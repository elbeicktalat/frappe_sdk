import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc_status.dart';

/// Represents a Frappe document.
class FrappeDoc {
  /// Creates a new Frappe document.
  FrappeDoc({
    required this.idx,
    required this.name,
    required this.owner,
    required this.creation,
    required this.modified,
    required this.modifiedBy,
    required this.docStatus,
  });

  /// The index of the document.
  final int idx;

  /// The name of the document.
  final String name;

  /// The owner of the document.
  final String owner;

  /// The creation date of the document.
  final DateTime creation;

  /// The last modified date of the document.
  final DateTime modified;

  /// The Person who did modified the document.
  final String modifiedBy;

  /// The status of the document, weather `saved` or `submitted` or `cancelled`.
  final FrappeDocStatus docStatus;
}
