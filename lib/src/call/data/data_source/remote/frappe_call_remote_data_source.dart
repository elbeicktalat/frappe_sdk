// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/frappe_sdk.dart';
import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';
import 'package:frappe_sdk/src/call/domain/utils/http_methods.dart';

/// The remote data source interface for the Frappe call.
abstract interface class FrappeCallRemoteDataSource {
  /// {@macro FrappeCallRepository.call}
  Future<T?> call<T>(
    String method, {
    required T Function(JSON json) fromJson,
    Map<String, dynamic>? params,
    HttpMethods httpMethod = HttpMethods.get,
  });

  /// {@macro FrappeCallRepository.getBalance}
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
  });

  /// {@macro FrappeCallRepository.getFiscalYear}
  Future<T?> getFiscalYear<T>({
    required T Function(JSON json) fromJson,
    DateTime? date,
    String? fiscalYear,
    String? label,
    int? verbose,
    String? company,
    bool asMap = true,
  });

  /// {@macro FrappeCallRepository.getCompanyDefault}
  Future<T?> getCompanyDefault<T>({
    required String company,
    required String fieldName,
    required T Function(JSON json) fromJson,
  });

  /// {@macro FrappeCallRepository.getCompanies}
  Future<List<String>> getCompanies();

  /// {@macro FrappeCallRepository.getChildren}
  Future<List<T?>> getChildren<T>(
    String docType,
    String parent, {
    Set<String>? fields,
    List<Filter>? filters,
  });

  /// {@macro FrappeCallRepository.getStockBalance}
  Future<T?> getStockBalance<T>({
    required String itemCode,
    required String warehouse,
    required T Function(JSON json) fromJson,
    DateTime? postingDate,
    bool? withValuationRate,
    bool? withSerialNo,
  });

  /// {@macro FrappeCallRepository.scanBarcode}
  Future<BarcodeScanResult?> scanBarcode(String barcode);

  /// {@macro FrappeCallRepository.getExchangeRate}
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  });
}
