import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// A repository for interacting with the Frappe database.
abstract interface class FrappeDBRepository {
  /// Get a document from the database and return it as a [T] object.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [docName] The identifier of the document.
  /// * [fromJson] FromJson function to parse the document.
  Future<T?> getDoc<T extends FrappeDoc>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  });

  /// Get a list of documents from the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [fromJson] FromJson function to parse the document.
  /// * [fields] The fields to fetch and return.
  /// * [filters] The filters to apply - SQL AND Operation.
  /// * [orFilters] The filters to apply - SQL OR Operation.
  /// * [limit] The maximum number of documents to return.
  /// * [limitStart] The offset to start from.
  /// * [orderBy] Sort results by field and order.
  /// * [groupBy] Group the results by particular field.
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

  /// Create a new document in the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [body] The document data.
  Future<T?> createDoc<T extends FrappeDoc>(
    String docType,
    Map<String, dynamic> body,
  );

  /// Update an existing document in the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [docName] The identifier of the document.
  /// * [body] The document data.
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body,
  );

  /// Delete a document from the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [docName] The identifier of the document.
  Future<bool> deleteDoc<T>(
    String docType,
    String docName,
  );

  /// Get the count of documents in the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [filters] The filters to apply.
  Future<int?> countDoc<T>(
    String docType, {
    List<Filter>? filters,
  });

  /// Get the last [docType] document from the database.
  ///
  /// * [docType] The Frappe `doctype` name.
  /// * [fromJson] FromJson function to parse the document.
  /// * [filters] The filters to apply - SQL AND Operation.
  /// * [orFilters] The filters to apply - SQL OR Operation.
  /// * [orderBy] Sort results by field and order.
  Future<T?> getLastDoc<T extends FrappeDoc>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    List<Filter>? filters,
    List<Filter>? orFilters,
    OrderBy? orderBy,
  });
}
