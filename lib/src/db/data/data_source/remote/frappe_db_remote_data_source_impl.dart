// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';
import 'package:frappe_sdk/src/exception/frappe_exception.dart';
import 'package:logger/logger.dart';

/// The remote data source implementation.
final class FrappeDBRemoteDataSourceImpl implements FrappeDBRemoteDataSource {
  /// Create a new FrappeDBRemoteDataSourceImpl
  FrappeDBRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  static final Logger _log = Logger();

  @override
  Future<int?> countDoc<T>(String docType, {List<Filter>? filters}) async {
    final List<Map<String, dynamic>?>? docs = await getDocList(
      docType,
      fromJson: (Map<String, dynamic> json) => json,
      filters: filters,
    );

    return docs?.length;
  }

  @override
  Future<T?> createDoc<T>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    try {
      final Response<JSON> response =
          await _dio.post('/api/resource/$docType', data: body);

      final dynamic json = response.data?['data'];
      _log.d(json);

      return fromJson(json);
    } on DioException catch (e, s) {
      _log.e(e, stackTrace: s);
      _handelHttpException(e);
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<bool> deleteDoc<T>(String docType, String docName) async {
    try {
      final Response<dynamic> response =
          await _dio.delete('/api/resource/$docType/$docName');

      return response.statusCode == HttpStatus.ok;
    } on DioException catch (e, s) {
      _log.e(e, stackTrace: s);
      _handelHttpException(e);
      return false;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<T?> getDoc<T>(
    String docType,
    String docName, {
    required T Function(JSON json) fromJson,
  }) async {
    try {
      final Response<JSON> response =
          await _dio.get('/api/resource/$docType/$docName');

      final dynamic json = response.data?['data'];
      _log.d(json);

      return fromJson(json);
    } on DioException catch (e, s) {
      _log.e(e, stackTrace: s);
      _handelHttpException(e);
    } catch (e) {
      rethrow;
    }
    return null;
  }

  @override
  Future<List<T?>?> getDocList<T>(
    String docType, {
    required T Function(JSON json) fromJson,
    Set<String>? fields,
    List<Filter>? filters,
    List<Filter>? orFilters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
    String? groupBy,
  }) async {
    try {
      _log.i(fields);

      final Response<JSON> response = await _dio.get(
        '/api/resource/$docType',
        data: <String, Object?>{
          'fields': jsonEncode(fields?.toList()),
          'filters': filters?.map(_getFilter).toList(),
          'or_filters': orFilters?.map(_getFilter).toList(),
          'limit': '$limit',
          'limit_start': '$limitStart',
          if (orderBy != null)
            'order_by': '${orderBy.field} ${orderBy.desc ? 'desc' : 'asc'}',
          'group_by': groupBy,
        },
      );

      _log.d(response);

      final List<dynamic> data = response.data?['data'] as List<dynamic>;
      if (data.isEmpty) return null;

      return data
          .map((Object? json) => fromJson(json! as Map<String, dynamic>))
          .toList();
    } on DioException catch (e, s) {
      _log.e(e, stackTrace: s);
      _handelHttpException(e);
    } catch (e) {
      rethrow;
    }

    return null;
  }

  @override
  Future<T?> getLastDoc<T>(
    String docType, {
    required T Function(JSON json) fromJson,
    List<Filter>? filters,
    List<Filter>? orFilters,
    OrderBy? orderBy,
  }) async {
    final List<JSON?>? docs = await getDocList(
      docType,
      fromJson: (JSON json) => json,
      fields: <String>{'name'},
      filters: filters,
      orFilters: orFilters,
      limit: 1,
      orderBy: orderBy ?? (field: 'creation', desc: true),
    );

    return docs?.first != null
        ? getDoc<T>(docType, docs?.first!['name'], fromJson: fromJson)
        : null;
  }

  @override
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    final Response<JSON> response =
        await _dio.put('/api/resource/$docType/$docName', data: body);

    final dynamic json = response.data?['data'];
    _log.d(json);

    return fromJson(json);
  }

  void _handelHttpException(DioException e) {
    switch (e.response?.statusCode) {
      case HttpStatus.notFound:
        throw FrappeNotFoundException(e.response!.statusCode!);
      case HttpStatus.unauthorized:
        throw FrappeUnauthorizedException(e.response!.statusCode!);
    }
  }

  List<String> _getFilter(Filter filter) {
    return <String>[filter.field, filter.operator.symbol, '${filter.value}'];
  }
}
