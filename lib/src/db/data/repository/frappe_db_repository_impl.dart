// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/data/data_source/local/frappe_db_local_data_source.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:frappe_sdk/src/db/domain/utils/cache_strategy.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// A repository implementation of [FrappeDBRepository] that uses a customizable
/// caching strategy with [sqflite] for local storage.
class FrappeDBRepositoryImpl implements FrappeDBRepository {
  /// Creates a new instance of [FrappeDBRepositoryImpl].
  FrappeDBRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource, {
    this.defaultStrategy = CacheStrategy.networkFirst,
  });

  final FrappeDBRemoteDataSource _remoteDataSource;
  final FrappeDBLocalDataSource _localDataSource;

  /// The default caching strategy to use.
  final CacheStrategy defaultStrategy;

  @override
  Future<T?> getDoc<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
    CacheStrategy? strategy,
  }) async {
    final CacheStrategy appliedStrategy = strategy ?? defaultStrategy;

    switch (appliedStrategy) {
      case CacheStrategy.networkOnly:
        return _fetchAndSaveDoc(docType, docName, fromJson: fromJson);

      case CacheStrategy.cacheOnly:
        return _localDataSource.getDoc(docType, docName, fromJson: fromJson);

      case CacheStrategy.cacheFirst:
        final JSON? cachedData = await _localDataSource.getDocRaw(docType, docName);
        if (cachedData != null && cachedData['__is_full'] == 1) {
          return fromJson(cachedData);
        }
        return _fetchAndSaveDoc(docType, docName, fromJson: fromJson);

      case CacheStrategy.networkFirst:
        final JSON? cachedData = await _localDataSource.getDocRaw(docType, docName);
        if (cachedData != null && cachedData['__is_full'] == 1) {
          try {
            // Optimization: check if modified on server before fetching full doc
            final List<JSON?>? checkList = await _remoteDataSource.getDocList<JSON>(
              docType,
              fields: <String>{'name', 'modified'},
              filters: <Filter>[Filter.equal('name', docName)],
              limit: 1,
              fromJson: (JSON json) => json,
            );

            if (checkList != null && checkList.isNotEmpty) {
              final JSON? remoteDoc = checkList.first;
              if (remoteDoc != null && remoteDoc['modified'] == cachedData['modified']) {
                return fromJson(cachedData);
              }
            }
          } catch (_) {
            // Network error during check, fallback to cache
            return fromJson(cachedData);
          }
        }
        try {
          return await _fetchAndSaveDoc(docType, docName, fromJson: fromJson);
        } catch (_) {
          if (cachedData != null) return fromJson(cachedData);
          return _localDataSource.getDoc(docType, docName, fromJson: fromJson);
        }
    }
  }

  @override
  Future<List<T?>?> getDocList<T>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    Set<String>? fields,
    List<Filter>? filters,
    List<Filter>? orFilters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
    String? groupBy,
    CacheStrategy? strategy,
  }) async {
    final CacheStrategy appliedStrategy = strategy ?? defaultStrategy;

    switch (appliedStrategy) {
      case CacheStrategy.networkOnly:
        return _fetchAndSaveDocList(
          docType,
          fromJson: fromJson,
          fields: fields,
          filters: filters,
          orFilters: orFilters,
          limit: limit,
          limitStart: limitStart,
          orderBy: orderBy,
          groupBy: groupBy,
        );

      case CacheStrategy.cacheOnly:
        return _localDataSource.getDocList(
          docType,
          fromJson: fromJson,
          fields: fields,
          filters: filters,
          orFilters: orFilters,
          limit: limit,
          limitStart: limitStart,
          orderBy: orderBy,
          groupBy: groupBy,
        );

      case CacheStrategy.cacheFirst:
        final List<T?>? cachedList = await _localDataSource.getDocList(
          docType,
          fromJson: fromJson,
          fields: fields,
          filters: filters,
          orFilters: orFilters,
          limit: limit,
          limitStart: limitStart,
          orderBy: orderBy,
          groupBy: groupBy,
        );
        if (cachedList != null && cachedList.isNotEmpty) return cachedList;
        return _fetchAndSaveDocList(
          docType,
          fromJson: fromJson,
          fields: fields,
          filters: filters,
          orFilters: orFilters,
          limit: limit,
          limitStart: limitStart,
          orderBy: orderBy,
          groupBy: groupBy,
        );

      case CacheStrategy.networkFirst:
        try {
          final List<JSON?>? remoteMin = await _remoteDataSource.getDocList<JSON>(
            docType,
            fields: <String>{'name', 'modified'},
            filters: filters,
            orFilters: orFilters,
            limit: limit,
            limitStart: limitStart,
            orderBy: orderBy,
            groupBy: groupBy,
            fromJson: (JSON json) => json,
          );

          if (remoteMin == null || remoteMin.isEmpty) {
            return <T?>[];
          }

          final List<String> names =
              remoteMin.whereType<JSON>().map((JSON e) => e['name'] as String).toList();

          // Get these from local to compare modified AND check field completeness
          final List<JSON?>? localCachedRaw = await _localDataSource.getDocList<JSON>(
            docType,
            filters: <Filter>[Filter.in_('name', names)],
            fromJson: (JSON json) => json,
          );

          final Map<String, JSON> localMap = <String, JSON>{
            for (final JSON doc in localCachedRaw?.whereType<JSON>() ?? <JSON>[])
              doc['name'] as String: doc,
          };

          final List<String> staleOrMissingNames = <String>[];
          for (final JSON remoteDoc in remoteMin.whereType<JSON>()) {
            final String name = remoteDoc['name'] as String;
            final String remoteMod = remoteDoc['modified'] as String;
            final JSON? localDoc = localMap[name];

            if (localDoc == null || localDoc['modified'] != remoteMod) {
              staleOrMissingNames.add(name);
              continue;
            }

            // Check if all requested fields are present in localDoc
            if (fields != null) {
              for (final String field in fields) {
                if (!localDoc.containsKey(field)) {
                  staleOrMissingNames.add(name);
                  break;
                }
              }
            }
          }

          if (staleOrMissingNames.isNotEmpty) {
            final Set<String>? fetchFields =
                fields == null ? null : <String>{...fields, 'name', 'modified'};
            final List<JSON?>? freshDocs = await _remoteDataSource.getDocList<JSON>(
              docType,
              fields: fetchFields,
              filters: <Filter>[Filter.in_('name', staleOrMissingNames)],
              fromJson: (JSON json) => json,
            );

            if (freshDocs != null) {
              final List<JSON> validFreshDocs = freshDocs.whereType<JSON>().toList();
              await _localDataSource.saveDocList(docType, validFreshDocs, isFull: fields == null);

              // Update localMap with fresh data
              for (final JSON doc in validFreshDocs) {
                localMap[doc['name'] as String] = doc;
              }
            }
          }

          // Return the results in the order defined by remoteMin
          return remoteMin.whereType<JSON>().map((JSON remoteDoc) {
            final String name = remoteDoc['name'] as String;
            final JSON? doc = localMap[name];
            return doc != null ? fromJson(doc) : null;
          }).toList();
        } catch (_) {
          return _localDataSource.getDocList(
            docType,
            fromJson: fromJson,
            fields: fields,
            filters: filters,
            orFilters: orFilters,
            limit: limit,
            limitStart: limitStart,
            orderBy: orderBy,
            groupBy: groupBy,
          );
        }
    }
  }

  Future<T?> _fetchAndSaveDoc<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final T? doc = await _remoteDataSource.getDoc(
      docType,
      docName,
      fromJson: fromJson,
    );
    if (doc != null) {
      // We need the raw JSON to save it locally.
      // This is a trade-off: either we fetch as Map or we require fromJson/toJson.
      // Since FrappeDoc usually has a way to get Map, but T is generic.
      // Let's assume we can fetch as Map first.
      final JSON? rawDoc = await _remoteDataSource.getDoc(
        docType,
        docName,
        fromJson: (JSON json) => json,
      );
      if (rawDoc != null) {
        await _localDataSource.saveDoc(docType, rawDoc, isFull: true);
      }
    }
    return doc;
  }

  Future<List<T?>?> _fetchAndSaveDocList<T>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    Set<String>? fields,
    List<Filter>? filters,
    List<Filter>? orFilters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
    String? groupBy,
  }) async {
    final List<JSON?>? rawDocs = await _remoteDataSource.getDocList(
      docType,
      fromJson: (JSON json) => json,
      fields: fields,
      filters: filters,
      orFilters: orFilters,
      limit: limit,
      limitStart: limitStart,
      orderBy: orderBy,
      groupBy: groupBy,
    );

    if (rawDocs != null) {
      final List<JSON> validDocs = rawDocs.whereType<JSON>().toList();
      await _localDataSource.saveDocList(docType, validDocs, isFull: fields == null);
      return validDocs.map(fromJson).toList();
    }
    return null;
  }

  @override
  Future<T?> createDoc<T>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    // We fetch as raw JSON first to save it to local cache, then convert to T.
    final JSON? rawDoc = await _remoteDataSource.createDoc(
      docType,
      body,
      fromJson: (JSON json) => json,
    );

    if (rawDoc != null) {
      await _localDataSource.saveDoc(docType, rawDoc, isFull: true);
      return fromJson(rawDoc);
    }
    return null;
  }

  @override
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    final JSON? rawDoc = await _remoteDataSource.updateDoc(
      docType,
      docName,
      body,
      fromJson: (JSON json) => json,
    );

    if (rawDoc != null) {
      await _localDataSource.saveDoc(docType, rawDoc, isFull: true);
      return fromJson(rawDoc);
    }
    return null;
  }

  @override
  Future<bool> deleteDoc<T>(
    String docType,
    String docName,
  ) async {
    final bool isDeleted = await _remoteDataSource.deleteDoc(docType, docName);
    if (isDeleted) {
      await _localDataSource.deleteDoc(docType, docName);
    }
    return isDeleted;
  }

  @override
  Future<int?> countDoc<T>(
    String docType, {
    List<Filter>? filters,
  }) {
    return _remoteDataSource.countDoc(docType, filters: filters);
  }

  @override
  Future<T?> getLastDoc<T>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    List<Filter>? filters,
    List<Filter>? orFilters,
    OrderBy? orderBy,
  }) {
    return _remoteDataSource.getLastDoc(
      docType,
      fromJson: fromJson,
      filters: filters,
      orFilters: orFilters,
      orderBy: orderBy,
    );
  }
}
