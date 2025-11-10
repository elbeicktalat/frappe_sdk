// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:frappe_sdk/frappe_sdk.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository implementation of [FrappeDBRepository] that uses an advanced
/// caching strategy to handle in-place updates and reconstruct lists efficiently.
class FrappeDBRepositoryImpl implements FrappeDBRepository {
  /// Creates a new instance of [FrappeDBRepositoryImpl].
  FrappeDBRepositoryImpl(
    this._remoteDataSource,
    this._cacheManager,
    this._sharedPreferences,
  );

  final FrappeDBRemoteDataSource _remoteDataSource;
  final BaseCacheManager _cacheManager;
  final SharedPreferences _sharedPreferences;

  /// Generates a key to store the list of record names for a specific query.
  String _generateListCacheKey(
    String docType, {
    List<Filter>? filters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
  }) {
    final List<String> keyParts = <String>[
      'list',
      docType,
      if (filters != null && filters.isNotEmpty) 'filters:${jsonEncode(filters)}',
      if (limit != null) 'limit:$limit',
      if (limitStart != null) 'limitStart:$limitStart',
      if (orderBy != null) 'orderBy:${orderBy.field}-${orderBy.desc}',
    ];
    final String combinedKey = keyParts.join('&');
    final Digest digest = sha1.convert(utf8.encode(combinedKey));
    return 'query_$digest';
  }

  /// Generates a cache key for a single document record.
  String _getRecordCacheKey(String docType, String docName) => 'record_${docType}_$docName';

  /// Generates the key for a single document's modification timestamp.
  String _getRecordTimestampKey(String docType, String docName) => 'ts_${docType}_$docName';

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
  }) async {
    // Note: This granular caching strategy does not work well with 'orFilters' or 'groupBy'.
    // We will bypass the cache for such complex queries.
    if ((orFilters != null && orFilters.isNotEmpty) || groupBy != null) {
      return _remoteDataSource.getDocList<T>(
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

    // 1. Get a lightweight list of remote records with their modification timestamps.
    final List<Map<String, dynamic>?>? remoteIndex = await _remoteDataSource.getDocList(
      docType,
      fromJson: (Map<String, dynamic> json) => json,
      fields: <String>{'name', 'modified'},
      filters: filters,
      limit: limit,
      limitStart: limitStart,
      orderBy: orderBy,
    );

    if (remoteIndex == null) {
      // If the server returns no data, clear any cached list for this query and return null.
      final String listKey = _generateListCacheKey(
        docType,
        filters: filters,
        limit: limit,
        limitStart: limitStart,
        orderBy: orderBy,
      );
      await _sharedPreferences.remove(listKey);
      return null;
    }

    final List<Future<T?>> futureDocs = <Future<T?>>[];
    final List<String> remoteDocNames = <String>[];

    // 2. Intelligently decide whether to fetch from cache or network for each item.
    for (final Map<String, dynamic>? indexItem in remoteIndex) {
      if (indexItem == null) {
        continue;
      }

      final String docName = indexItem['name'];
      final String remoteTimestamp = indexItem['modified'];
      remoteDocNames.add(docName);

      final String recordTimestampKey = _getRecordTimestampKey(docType, docName);
      final String? cachedTimestamp = _sharedPreferences.getString(recordTimestampKey);

      // If timestamps match, load from cache.
      if (remoteTimestamp == cachedTimestamp) {
        futureDocs.add(_getCachedRecord(docType, docName, fromJson: fromJson));
      }
      // Otherwise, fetch from network and update cache.
      else {
        futureDocs.add(
          _fetchAndCacheRecord(
            docType,
            docName,
            remoteTimestamp,
            fields: fields,
            fromJson: fromJson,
          ),
        );
      }
    }

    // 3. Update the cached list of names for this query.
    final String listKey = _generateListCacheKey(
      docType,
      filters: filters,
      limit: limit,
      limitStart: limitStart,
      orderBy: orderBy,
    );
    await _sharedPreferences.setStringList(listKey, remoteDocNames);

    // 4. Await all futures and return the fully constructed list.
    final List<T?> result = await Future.wait(futureDocs);
    return result.toList();
  }

  /// Helper to get a single record from the cache.
  Future<T?> _getCachedRecord<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final String recordKey = _getRecordCacheKey(docType, docName);
    final FileInfo? fileInfo = await _cacheManager.getFileFromCache(recordKey);
    if (fileInfo != null) {
      final String cachedJson = await fileInfo.file.readAsString();
      return fromJson(json.decode(cachedJson));
    }
    return null;
  }

  /// Helper to fetch a single record, cache it, and update its timestamp.
  Future<T?> _fetchAndCacheRecord<T>(
    String docType,
    String docName,
    String timestamp, {
    required T Function(Map<String, dynamic> json) fromJson,
    Set<String>? fields,
  }) async {
    // Use getDocList to fetch only the specified fields for a single document.
    // This is much more efficient than fetching the whole document.
    final List<T?>? result = await _remoteDataSource.getDocList<T>(
      docType,
      fromJson: fromJson,
      fields: fields,
      filters: <Filter>[Filter(field: 'name', operator: FilterOperator.equal, value: docName)],
      limit: 1,
    );

    final T? doc = result?.firstOrNull;

    if (doc != null) {
      final String recordKey = _getRecordCacheKey(docType, docName);
      final String recordTimestampKey = _getRecordTimestampKey(docType, docName);

      // Cache the full document. Assumes 'doc' has a 'toJson' method.
      await _cacheManager.putFile(
        recordKey,
        utf8.encode(json.encode((doc as dynamic).toJson())),
        fileExtension: 'json',
      );
      // Update the timestamp in SharedPreferences.
      await _sharedPreferences.setString(recordTimestampKey, timestamp);
    }
    return doc;
  }

  /// Invalidates the cache for a single document.
  Future<void> _invalidateRecordCache(String docType, String docName) async {
    await _cacheManager.removeFile(_getRecordCacheKey(docType, docName));
    await _sharedPreferences.remove(_getRecordTimestampKey(docType, docName));
  }

  @override
  Future<T?> getDoc<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    // Caching for single documents can be added here if needed.
    // For now, it will fetch directly from the remote source.
    return _remoteDataSource.getDoc<T>(docType, docName, fromJson: fromJson);
  }

  @override
  Future<T?> createDoc<T>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    final T? newDoc = await _remoteDataSource.createDoc(docType, body, fromJson: fromJson);
    // Creating a doc doesn't mean we need to invalidate anything,
    // as the next getDocList will simply pick it up as a new item.
    return newDoc;
  }

  @override
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    final T? doc = await _remoteDataSource.updateDoc(docType, docName, body, fromJson: fromJson);
    if (doc != null) {
      // Invalidate the specific record that was updated.
      await _invalidateRecordCache(docType, docName);
    }
    return doc;
  }

  @override
  Future<bool> deleteDoc<T>(
    String docType,
    String docName,
  ) async {
    final bool isDeleted = await _remoteDataSource.deleteDoc(docType, docName);
    if (isDeleted) {
      // Invalidate the specific record that was deleted.
      await _invalidateRecordCache(docType, docName);
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
    // This method fetches the latest, so bypassing cache is reasonable.
    return _remoteDataSource.getLastDoc(
      docType,
      fromJson: fromJson,
      filters: filters,
      orFilters: orFilters,
      orderBy: orderBy,
    );
  }
}
