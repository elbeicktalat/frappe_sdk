// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc_status.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';

/// The model of [FrappeDoc].
class FrappeDocModel extends FrappeDoc {
  /// Creates a new [FrappeDocModel].
  FrappeDocModel({
    required super.name,
    required super.owner,
    required super.creation,
    required super.modified,
    required super.modifiedBy,
    required super.docStatus,
    required super.idx,
  });

  /// Creates a new [FrappeDocModel] from a [Map] (json).
  factory FrappeDocModel.fromJson(Map<String, dynamic> json) {
    return FrappeDocModel(
      idx: json['idx'] as int,
      name: json['name'] as String,
      owner: json['owner'] as String,
      modifiedBy: json['modified_by'] as String,
      creation: DateTime.parse(json['creation'] as String),
      modified: DateTime.parse(json['modified'] as String),
      docStatus: FrappeDocStatus.parse(json['docstatus'] as int),
    );
  }

  /// Converts the [FrappeDocModel] to a [Map] (json).
  @override
  JSON toJson() {
    return <String, dynamic>{
      'idx': idx,
      'name': name,
      'owner': owner,
      'modified_by': modifiedBy,
      'creation': creation.toIso8601String(),
      'modified': modified.toIso8601String(),
      'docstatus': docStatus.value,
    };
  }
}
