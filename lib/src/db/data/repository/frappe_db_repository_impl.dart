// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A repository implementation of [FrappeDBRepository].
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

  String _getDocListCacheKey(String docType) => 'frappe_sdk_${docType.replaceAll(' ', '_')}_list';

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
    // 1. Get the current count of documents on the server.
    final int? serverDocCount = await _remoteDataSource.countDoc(docType, filters: filters);

    // 2. Get the stored count from shared preferences.
    final String cacheKey = _getDocListCacheKey(docType);
    final int cachedDocCount = _sharedPreferences.getInt(cacheKey) ?? 0;

    // 3. Try to get data from the cache first.
    final FileInfo? fileInfo = await _cacheManager.getFileFromCache(cacheKey);

    // 4. Compare counts and check if cached data exists.
    if (serverDocCount == cachedDocCount && fileInfo != null) {
      // If counts match and a cached file exists, return the cached data.
      final String cachedJson = await fileInfo.file.readAsString();
      final List<dynamic> data = json.decode(cachedJson);

      // ignore: always_specify_types
      return data.map((json) => fromJson(json as Map<String, dynamic>)).toList();
    } else {
      // 5. If counts differ or no cache exists, fetch from the remote data source.
      final List<T?>? freshData = await _remoteDataSource.getDocList<T>(
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

      if (freshData != null) {
        // 6. Cache the new data and update the count in shared preferences.
        await _cacheManager.putFile(
          cacheKey,
          utf8.encode(json.encode(freshData)),
          fileExtension: 'json',
        );
        await _sharedPreferences.setInt(cacheKey, serverDocCount!);
      }

      return freshData;
    }
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
    if (newDoc != null) {
      // Invalidate the list cache by removing the count.
      // The next call to getDocList will force a refresh.
      await _sharedPreferences.remove(_getDocListCacheKey(docType));
      await _cacheManager.removeFile(_getDocListCacheKey(docType));
    }
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
      // Invalidate cache for potential list changes.
      await _sharedPreferences.remove(_getDocListCacheKey(docType));
      await _cacheManager.removeFile(_getDocListCacheKey(docType));
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
      // Invalidate the list cache as the count has changed.
      await _sharedPreferences.remove(_getDocListCacheKey(docType));
      await _cacheManager.removeFile(_getDocListCacheKey(docType));
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
