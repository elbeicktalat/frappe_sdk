// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

/// The result of a barcode scan.
class BarcodeScanResult {
  /// Creates a new [BarcodeScanResult].
  BarcodeScanResult({
    required this.barcode,
    required this.itemCode,
    required this.uom,
    required this.hasBatchNumber,
    required this.hasSerialNumber,
  });

  /// The barcode.
  final String barcode;

  /// The item linked to the barcode scan.
  final String itemCode;

  /// The unit of management of the item.
  final String? uom;

  /// Whether the item has a batch number.
  final bool hasBatchNumber;

  /// Whether the item has a serial number.
  final bool hasSerialNumber;
}
