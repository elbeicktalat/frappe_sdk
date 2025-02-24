// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:frappe_sdk/frappe_sdk.dart';
import 'package:frappe_sdk/src/_internal/utils.dart';
import 'package:frappe_sdk/src/call/data/data_source/remote/frappe_call_remote_data_source.dart';
import 'package:frappe_sdk/src/call/data/models/barcode_scan_result_model.dart';
import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';
import 'package:frappe_sdk/src/call/domain/utils/http_methods.dart';
import 'package:logger/logger.dart';

/// The remote data source implementation for the Frappe call.
class FrappeCallRemoteDataSourceImpl implements FrappeCallRemoteDataSource {
  /// Creates a new instance of [FrappeCallRemoteDataSourceImpl].
  FrappeCallRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  final Logger _log = Logger();

  @override
  Future<T?> call<T>(
    String method, {
    required T Function(JSON json) fromJson,
    Map<String, dynamic>? params,
    HttpMethods httpMethod = HttpMethods.get,
  }) async {
    try {
      final Response<dynamic> response = await _dio.request(
        '/api/method/$method',
        queryParameters: params,
        options: Options(
          method: httpMethod.name.toUpperCase(),
        ),
      );

      if (response.data == null) return null;
      return fromJson(response.data);
    } on DioException catch (e) {
      _log.e(e.response);
      _handelHttpException(e);
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<double?> getBalance({
    String? account,
    DateTime? date,
    DateTime? startDate,
    String? partyType,
    String? party,
    String? company,
    String? currency,
    String? costCenter,
    bool ignoreAccountPermission = false,
    String? accountType,
  }) async {
    _log.i('Getting balance for: ${party ?? account}');
    final double balance = await call(
      'erpnext.accounts.utils.get_balance_on',
      fromJson: (Map<String, dynamic> json) => json['message'],
      params: <String, Object?>{
        'account': account,
        'date': date,
        'start_date': startDate,
        'party_type': partyType,
        'party': party,
        'company': company,
        'in_account_currency': currency,
        'cost_center': costCenter,
        'ignore_account_permission': ignoreAccountPermission,
        'account_type': accountType,
      },
    );
    _log.i('Got balance for ${party ?? account}: $balance');

    return balance;
  }

  @override
  Future<T?> getFiscalYear<T>({
    required T Function(JSON json) fromJson,
    DateTime? date,
    String? fiscalYear,
    String? label,
    int? verbose,
    String? company,
    bool asMap = true,
  }) async {
    final T? result = await call(
      'erpnext.accounts.utils.get_fiscal_year',
      fromJson: fromJson,
      params: <String, Object?>{
        'date': date,
        'fiscal_year': fiscalYear,
        'label': label,
        'verbose': verbose,
        'company': company,
        'as_map': asMap,
      },
    );

    return result;
  }

  @override
  Future<T?> getCompanyDefault<T>({
    required String company,
    required String fieldName,
    required T Function(JSON json) fromJson,
  }) async {
    final T? result = await call(
      'erpnext.accounts.utils.get_company_default',
      fromJson: fromJson,
      params: <String, Object?>{
        'company': company,
        'fieldname': fieldName,
      },
    );

    return result;
  }

  @override
  Future<List<String>> getCompanies() async {
    final List<dynamic> companies = await call(
      'erpnext.accounts.utils.get_companies',
      fromJson: (Map<String, dynamic> json) {
        _log.i(json['message']);
        return json['message'];
      },
    );

    return companies.cast<String>();
  }

  @override
  Future<List<T?>> getChildren<T>(
    String docType,
    String parent, {
    Set<String>? fields,
    List<Filter>? filters,
  }) async {
    final List<dynamic> children = await call(
      'frappe.client.get_list',
      fromJson: (Map<String, dynamic> json) => json['message'],
      params: <String, Object?>{
        'doctype': docType,
        'parent': parent,
        'fields': jsonEncode(fields?.toList()),
        'filters': filters?.map(_getFilter).toList(),
      },
    );

    return children.cast<T?>();
  }

  @override
  Future<T?> getStockBalance<T>({
    required String itemCode,
    required String warehouse,
    required T Function(JSON json) fromJson,
    DateTime? postingDate,
    bool? withValuationRate,
    bool? withSerialNo,
  }) async {
    postingDate ??= DateTime.now();

    final dynamic result = await call(
      'erpnext.stock.utils.get_stock_balance',
      params: <String, Object?>{
        'item_code': itemCode,
        'warehouse': warehouse,
        'posting_date': postingDate.today,
        if (withValuationRate != null) 'with_valuation_rate': withValuationRate,
        if (withSerialNo != null) 'with_serial_no': withSerialNo,
      },
      fromJson: (Map<String, dynamic> json) {
        if (withValuationRate ?? false) {
          return fromJson(
            <String, dynamic>{
              'qty': (json['message'] as List<dynamic>)[0],
              'valuation_rate': (json['message'] as List<dynamic>)[1],
            },
          );
        }
        return fromJson(<String, double>{
          'qty': json['message'],
        });
      },
    );

    return result;
  }

  @override
  Future<BarcodeScanResult?> scanBarcode(String barcode) async {
    final JSON? result = await call(
      'erpnext.stock.utils.scan_barcode',
      fromJson: (Map<String, dynamic> json) => json['message'],
      params: <String, Object?>{
        'search_value': barcode,
      },
    );

    if (result == null || result.isEmpty) return null;
    return BarcodeScanResultModel.fromJson(result);
  }

  @override
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) async {
    final double? result = await call(
      'erpnext.setup.utils.get_exchange_rate',
      fromJson: (Map<String, dynamic> json) => json['message'],
      params: <String, Object?>{
        'from_currency': fromCurrency,
        'to_currency': toCurrency,
        'transaction_date': date,
      },
    );

    return result;
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
