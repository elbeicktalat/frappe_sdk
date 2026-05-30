// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// The local data source of [FrappeDBRepository].
abstract interface class FrappeDBLocalDataSource {
  /// Get a document from the local database.
  Future<T?> getDoc<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  });

  /// Get a list of documents from the local database.
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
  });

  /// Save a document to the local database, merging with existing data if present.
  Future<void> saveDoc(String docType, Map<String, dynamic> data);

  /// Save a list of documents to the local database, merging with existing data if present.
  Future<void> saveDocList(String docType, List<Map<String, dynamic>> docs);

  /// Delete a document from the local database.
  Future<void> deleteDoc(String docType, String docName);

  /// Clear all cached documents for a specific doctype.
  Future<void> clear(String docType);

  /// Clear all cached documents.
  Future<void> clearAll();
}
