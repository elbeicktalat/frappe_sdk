import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// The remote data source of [FrappeDBRepository].
abstract interface class FrappeDBRemoteDataSource {
  /// {@macro FrappeDBRepository.getDoc}
  Future<T?> getDoc<T extends FrappeDoc>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  });

  /// {@macro FrappeDBRepository.getDocList}
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

  /// {@macro FrappeDBRepository.createDoc}
  Future<T?> createDoc<T extends FrappeDoc>(
    String docType,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  });

  /// {@macro FrappeDBRepository.updateDoc}
  Future<T?> updateDoc<T>(
    String docType,
    String docName,
    Map<String, dynamic> body, {
    required T Function(JSON json) fromJson,
  });

  /// {@macro FrappeDBRepository.deleteDoc}
  Future<bool> deleteDoc<T>(
    String docType,
    String docName,
  );

  /// {@macro FrappeDBRepository.countDoc}
  Future<int?> countDoc<T>(
    String docType, {
    List<Filter>? filters,
  });

  /// {@macro FrappeDBRepository.getLastDoc}
  Future<T?> getLastDoc<T extends FrappeDoc>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    List<Filter>? filters,
    List<Filter>? orFilters,
    OrderBy? orderBy,
  });
}
