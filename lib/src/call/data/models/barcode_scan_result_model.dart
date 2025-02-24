// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/call/domain/entities/barcode_scan_result.dart';

/// The result of a barcode scan.
class BarcodeScanResultModel extends BarcodeScanResult {
  /// Creates a new [BarcodeScanResult].
  BarcodeScanResultModel({
    required super.barcode,
    required super.itemCode,
    required super.uom,
    required super.hasBatchNumber,
    required super.hasSerialNumber,
  });

  /// Creates a new [BarcodeScanResult] from a [Map].
  factory BarcodeScanResultModel.fromJson(Map<String, dynamic> json) {
    return BarcodeScanResultModel(
      barcode: json['barcode'],
      itemCode: json['item_code'],
      uom: json['uom'],
      hasBatchNumber: json['has_batch_number'] == 1 || false,
      hasSerialNumber: json['has_serial_number'] == 1 || false,
    );
  }
}
