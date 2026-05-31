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
    this.defaultStrategy = CacheStrategy.cacheFirst,
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
        final Map<String, dynamic>? cachedData = await _localDataSource.getDocRaw(docType, docName);
        if (cachedData != null && cachedData['__is_full'] == 1) {
          return fromJson(cachedData);
        }
        return _fetchAndSaveDoc(docType, docName, fromJson: fromJson);

      case CacheStrategy.networkFirst:
        try {
          return await _fetchAndSaveDoc(docType, docName, fromJson: fromJson);
        } catch (_) {
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
          return await _fetchAndSaveDocList(
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
      final Map<String, dynamic>? rawDoc = await _remoteDataSource.getDoc(
        docType,
        docName,
        fromJson: (Map<String, dynamic> json) => json,
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
    final List<Map<String, dynamic>?>? rawDocs = await _remoteDataSource.getDocList(
      docType,
      fromJson: (Map<String, dynamic> json) => json,
      fields: fields,
      filters: filters,
      orFilters: orFilters,
      limit: limit,
      limitStart: limitStart,
      orderBy: orderBy,
      groupBy: groupBy,
    );

    if (rawDocs != null) {
      final List<Map<String, dynamic>> validDocs =
          rawDocs.whereType<Map<String, dynamic>>().toList();
      await _localDataSource.saveDocList(docType, validDocs, isFull: false);
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
    final Map<String, dynamic>? rawDoc = await _remoteDataSource.createDoc(
      docType,
      body,
      fromJson: (Map<String, dynamic> json) => json,
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
    final Map<String, dynamic>? rawDoc = await _remoteDataSource.updateDoc(
      docType,
      docName,
      body,
      fromJson: (Map<String, dynamic> json) => json,
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
