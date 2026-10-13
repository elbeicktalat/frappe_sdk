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
    try {
      // frappe.client.get_count rather than a `count(name)` field: Frappe 16
      // refuses SQL functions written as strings in a list's fields.
      final Response<JSON> response = await _dio.get(
        '/api/method/frappe.client.get_count',
        data: <String, Object?>{
          'doctype': docType,
          if (filters != null) 'filters': jsonEncode(filters.map(_getFilter).toList()),
        },
      );

      return (response.data?['message'] as num?)?.toInt() ?? 0;
    } on DioException catch (e, s) {
      _log.e(e, stackTrace: s);
      _handelHttpException(e);
    }
    return null;
  }

  @override
  Future<T?> createDoc<T>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  }) async {
    try {
      final Response<JSON> response = await _dio.post('/api/resource/$docType', data: body);

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
      final Response<dynamic> response = await _dio.delete('/api/resource/$docType/$docName');

      return response.statusCode == HttpStatus.accepted;
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
      final Response<JSON> response = await _dio.get('/api/resource/$docType/$docName');

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

  /// Documents asked for per request when no [getDocList] limit is given.
  static const int _pageSize = 500;

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

      Future<List<dynamic>> page(int pageLimit, int? pageStart) async {
        final Response<JSON> response = await _dio.get(
          '/api/resource/$docType',
          data: <String, Object?>{
            if (fields != null) 'fields': jsonEncode(fields.toList()),
            if (filters != null) 'filters': jsonEncode(filters.map(_getFilter).toList()),
            if (orFilters != null) 'or_filters': jsonEncode(orFilters.map(_getFilter).toList()),
            'limit': pageLimit,
            if (pageStart != null) 'limit_start': pageStart,
            if (orderBy != null) 'order_by': '${orderBy.field} ${orderBy.desc ? 'desc' : 'asc'}',
            if (groupBy != null) 'group_by': groupBy,
          },
        );
        _log.d(response);
        return response.data?['data'] as List<dynamic>? ?? <dynamic>[];
      }

      final List<dynamic> data;
      if (limit != null) {
        data = await page(limit, limitStart);
      } else {
        // No limit means every document. Frappe answers 20 when it's not
        // told how many (and 0 doesn't mean "all" either), so ask page by page.
        data = <dynamic>[];
        int start = limitStart ?? 0;
        while (true) {
          final List<dynamic> rows = await page(_pageSize, start);
          data.addAll(rows);
          if (rows.length < _pageSize) break;
          start += _pageSize;
        }
      }

      if (data.isEmpty) return null;

      return data.map((Object? json) => fromJson(json! as Map<String, dynamic>)).toList();
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
    final Response<JSON> response = await _dio.put('/api/resource/$docType/$docName', data: body);

    final dynamic json = response.data?['data'];
    _log.d(json);

    return fromJson(json);
  }

  /// Turns an error answer from the server into an exception carrying what it
  /// said. Network errors (no answer) are left to the caller, whose cache
  /// strategies fall back to local data on them.
  void _handelHttpException(DioException e) {
    final Response<dynamic>? response = e.response;
    if (response != null) throw FrappeServerException.fromResponse(response);
  }

  List<dynamic> _getFilter(Filter filter) {
    return <dynamic>[filter.field, filter.operator.symbol, filter.value];
  }
}
