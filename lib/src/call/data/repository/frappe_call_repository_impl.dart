// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/call/data/data_source/remote/frappe_call_remote_data_source.dart';
import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';
import 'package:frappe_sdk/src/call/domain/repository/frappe_call_repository.dart';
import 'package:frappe_sdk/src/call/domain/utils/http_methods.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// The repository implementation for the Frappe call.
class FrappeCallRepositoryImpl implements FrappeCallRepository {
  /// Creates a new instance of [FrappeCallRepositoryImpl].
  FrappeCallRepositoryImpl(this._remoteDataSource);

  final FrappeCallRemoteDataSource _remoteDataSource;

  @override
  Future<T?> call<T>(
    String method, {
    required T Function(JSON json) fromJson,
    Map<String, dynamic>? params,
    HttpMethods httpMethod = HttpMethods.get,
  }) {
    return _remoteDataSource.call(method, fromJson: fromJson);
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
  }) {
    return _remoteDataSource.getBalance(
      account: account,
      date: date,
      startDate: startDate,
      partyType: partyType,
      party: party,
      company: company,
      currency: currency,
      costCenter: costCenter,
      ignoreAccountPermission: ignoreAccountPermission,
      accountType: accountType,
    );
  }

  @override
  Future<List<T?>> getChildren<T>(
    String docType,
    String parent, {
    Set<String>? fields,
    List<Filter>? filters,
  }) {
    return _remoteDataSource.getChildren(
      docType,
      parent,
      fields: fields,
      filters: filters,
    );
  }

  @override
  Future<List<String>> getCompanies() {
    return _remoteDataSource.getCompanies();
  }

  @override
  Future<T?> getCompanyDefault<T>({
    required String company,
    required String fieldName,
    required T Function(JSON json) fromJson,
  }) {
    return _remoteDataSource.getCompanyDefault(
      company: company,
      fieldName: fieldName,
      fromJson: fromJson,
    );
  }

  @override
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  }) {
    return _remoteDataSource.getExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      date: date,
    );
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
  }) {
    return _remoteDataSource.getFiscalYear(
      fromJson: fromJson,
      date: date,
      fiscalYear: fiscalYear,
      label: label,
      verbose: verbose,
      company: company,
      asMap: asMap,
    );
  }

  @override
  Future<T?> getStockBalance<T>({
    required String itemCode,
    required String warehouse,
    required T Function(JSON json) fromJson,
    DateTime? postingDate,
    bool? withValuationRate,
    bool? withSerialNo,
  }) {
    return _remoteDataSource.getStockBalance(
      itemCode: itemCode,
      warehouse: warehouse,
      fromJson: fromJson,
      postingDate: postingDate,
      withValuationRate: withValuationRate,
      withSerialNo: withSerialNo,
    );
  }

  @override
  Future<BarcodeScanResult?> scanBarcode(String barcode) {
    return _remoteDataSource.scanBarcode(barcode);
  }
}
