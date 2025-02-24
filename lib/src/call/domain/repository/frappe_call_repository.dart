// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/frappe_sdk.dart';
import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';
import 'package:frappe_sdk/src/call/domain/utils/http_methods.dart';

/// The repository interface for the Frappe call.
abstract interface class FrappeCallRepository {
  /// {@template FrappeCallRepository.call}
  ///
  /// Makes request to the specified endpoint.
  ///
  /// * [method] The frappe method path to call.
  /// * [fromJson] The function to parse the response.
  /// * [params] The query parameters to send with the request.
  /// * [httpMethod] The HTTP method to use.
  ///
  /// {@endtemplate}
  Future<T?> call<T>(
    String method, {
    required T Function(JSON json) fromJson,
    Map<String, dynamic>? params,
    HttpMethods httpMethod = HttpMethods.get,
  });

  /// {@template FrappeCallRepository.getBalance}
  ///
  /// Get balance on a specific account.
  ///
  /// * [account] The account to get the balance for.
  /// * [date] The date to get the balance for.
  /// * [startDate] The start date to get the balance for.
  /// * [partyType] The party type to get the balance for.
  /// * [party] The party to get the balance for.
  /// * [company] The company to get the balance for.
  /// * [currency] The currency to get the balance for.
  /// * [costCenter] The cost center to get the balance for.
  /// * [ignoreAccountPermission] Whether to ignore the account permission.
  /// * [accountType] The account type to get the balance for.
  ///
  /// {@endtemplate}
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

  /// {@template FrappeCallRepository.getFiscalYear}
  ///
  /// Get current fiscal year.
  ///
  /// * [date] The date to get the fiscal year for.
  /// * [fiscalYear] The fiscal year to get.
  /// * [label] The label to get.
  /// * [verbose] The verbose to get.
  /// * [company] The company to get.
  /// * [asMap] Whether to return the fiscal year as a map.
  /// * [fromJson] The function to parse the response.
  ///
  /// {@endtemplate}
  Future<T?> getFiscalYear<T>({
    required T Function(JSON json) fromJson,
    DateTime? date,
    String? fiscalYear,
    String? label,
    int? verbose,
    String? company,
    bool asMap = true,
  });

  /// {@template FrappeCallRepository.getCompanyDefault}
  ///
  /// Get company default.
  ///
  /// * [company] The company to get values from.
  /// * [fieldName] The field to get.
  ///
  /// {@endtemplate}
  Future<T?> getCompanyDefault<T>({
    required String company,
    required String fieldName,
    required T Function(JSON json) fromJson,
  });

  /// {@template FrappeCallRepository.getCompanies}
  ///
  /// Get all companies.
  ///
  /// {@endtemplate}
  Future<List<String>> getCompanies();

  /// {@template FrappeCallRepository.getChildren}
  ///
  /// Get child table values of a document.
  ///
  /// * [docType] The document type.
  /// * [parent] The parent document.
  /// * [fields] The fields to get.
  /// * [filters] The filters to apply.
  ///
  /// {@endtemplate}
  Future<List<T?>> getChildren<T>(
    String docType,
    String parent, {
    Set<String>? fields,
    List<Filter>? filters,
  });

  /// {@template FrappeCallRepository.getStockBalance}
  ///
  /// Get stock balance.
  ///
  /// * [itemCode] The item code.
  /// * [warehouse] The warehouse.
  /// * [postingDate] The posting date.
  /// * [withValuationRate] Whether to include valuation rate.
  /// * [withSerialNo] Whether to include serial number.
  ///
  /// {@endtemplate}
  Future<T?> getStockBalance<T>({
    required String itemCode,
    required String warehouse,
    required T Function(JSON json) fromJson,
    DateTime? postingDate,
    bool? withValuationRate,
    bool? withSerialNo,
  });

  /// {@template FrappeCallRepository.scanBarcode}
  ///
  /// Search for item by barcode.
  ///
  /// * [barcode] The barcode to search for.
  ///
  /// {@endtemplate}
  Future<BarcodeScanResult?> scanBarcode(String barcode);

  /// {@template FrappeCallRepository.getExchangeRate}
  ///
  /// Get exchange rate.
  ///
  /// * [fromCurrency] The currency to convert from.
  /// * [toCurrency] The currency to convert to.
  /// * [date] The date to get exchange price on.
  ///
  /// {@endtemplate}
  Future<double?> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    DateTime? date,
  });
}
