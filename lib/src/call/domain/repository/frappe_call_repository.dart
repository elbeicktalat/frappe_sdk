// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/frappe_sdk.dart';
import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';
import 'package:frappe_sdk/src/call/domain/utils/http_methods.dart';

/// The repository interface for the Frappe call.
abstract interface class FrappeCallRepository {
  /// Makes request to the specified endpoint.
  ///
  /// * [method] The frappe method path to call.
  /// * [fromJson] The function to parse the response.
  /// * [params] The query parameters to send with the request.
  /// * [httpMethod] The HTTP method to use.
  Future<T?> call<T>(
    String method, {
    required T Function(JSON json) fromJson,
    Map<String, dynamic>? params,
    HttpMethods httpMethod = HttpMethods.get,
  });

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

  /// Get current fiscal year.
  ///
  /// * [date] The date to get the fiscal year for.
  /// * [fiscalYear] The fiscal year to get.
  /// * [label] The label to get.
  /// * [verbose] The verbose to get.
  /// * [company] The company to get.
  /// * [asMap] Whether to return the fiscal year as a map.
  /// * [fromJson] The function to parse the response.
  Future<T?> getFiscalYear<T>({
    DateTime? date,
    String? fiscalYear,
    String? label,
    int? verbose,
    String? company,
    bool asMap = true,
    T Function(JSON json) fromJson,
  });

  /// Get company default.
  ///
  /// * [company] The company to get values from.
  /// * [fieldName] The field to get.
  Future<T?> getCompanyDefault<T>({
    String? company,
    String? fieldName,
  });

  /// Get all companies.
  Future<List<String>> getCompanies();

  /// Get child table values of a document.
  ///
  /// * [docType] The document type.
  /// * [parent] The parent document.
  /// * [fields] The fields to get.
  /// * [filters] The filters to apply.
  Future<List<T?>> getChildren<T>(
    String docType,
    String parent, {
    Set<String>? fields,
    List<Filter>? filters,
  });

  /// Get stock balance.
  ///
  /// * [itemCode] The item code.
  /// * [warehouse] The warehouse.
  /// * [postingDate] The posting date.
  /// * [withValuationRate] Whether to include valuation rate.
  /// * [withSerialNo] Whether to include serial number.
  Future<T?> getStockBalance<T>({
    required String itemCode,
    required String warehouse,
    DateTime? postingDate,
    bool withValuationRate = false,
    bool withSerialNo = false,
  });


  /// Search for item by barcode.
  ///
  /// * [barcode] The barcode to search for.
  Future<BarcodeScanResult?> scanBarcode(String barcode);
}
