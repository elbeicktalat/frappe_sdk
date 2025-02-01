// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// A repository implementation of [FrappeDBRepository].
class FrappeDBRepositoryImpl implements FrappeDBRepository {
  /// Creates a new instance of [FrappeDBRepositoryImpl].
  FrappeDBRepositoryImpl(this._remoteDataSource);

  final FrappeDBRemoteDataSource _remoteDataSource;

  @override
  Future<T?> getDoc<T extends FrappeDoc>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) {
    return _remoteDataSource.getDoc<T>(docType, docName, fromJson: fromJson);
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
  }) {
    return _remoteDataSource.getDocList(
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

  @override
  Future<T?> createDoc<T extends FrappeDoc>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) {
    return _remoteDataSource.createDoc(docType, body, fromJson: fromJson);
  }

  @override
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) {
    return _remoteDataSource.updateDoc(
      docType,
      docName,
      body,
      fromJson: fromJson,
    );
  }

  @override
  Future<bool> deleteDoc<T>(
    String docType,
    String docName,
  ) {
    return _remoteDataSource.deleteDoc(docType, docName);
  }

  @override
  Future<int?> countDoc<T>(
    String docType, {
    List<Filter>? filters,
  }) {
    return _remoteDataSource.countDoc(docType, filters: filters);
  }

  @override
  Future<T?> getLastDoc<T extends FrappeDoc>(
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
