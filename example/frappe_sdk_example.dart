import 'package:dio/dio.dart';
import 'package:frappe_sdk/src/app/frappe_app.dart';
import 'package:frappe_sdk/src/db/data/data_source/local/sqflite_frappe_db_local_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc_status.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  // Initialize Sqflite (for mobile/desktop with sqflite_common_ffi)
  final String path = join(await getDatabasesPath(), 'frappe_cache.db');
  final Database database = await openDatabase(
    path,
    version: 1,
  );

  final FrappeApp app = FrappeApp(
    dio: Dio(),
    localDataSource: SqfliteFrappeDBLocalDataSource(database),
  );

  final FrappeDBRepository db = app.db;

  final PaymentEntry? paymentEntry = await db.getDoc<PaymentEntry>(
    'Payment Entry',
    'PV25-00188',
    fromJson: PaymentEntry.fromJson,
  );

  print(paymentEntry?.idx);
  print(paymentEntry?.name);
  print(paymentEntry?.owner);
  print(paymentEntry?.creation);
  print(paymentEntry?.modified);
  print(paymentEntry?.modifiedBy);
  print(paymentEntry?.docStatus);
  print(paymentEntry?.paidAmount);
}

class PaymentEntry extends FrappeDoc {
  PaymentEntry({
    required super.idx,
    required super.name,
    required super.owner,
    required super.creation,
    required super.modified,
    required super.modifiedBy,
    required super.docStatus,
    required this.paidAmount,
  });

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      idx: json['idx'],
      name: json['name'],
      owner: json['owner'],
      creation: DateTime.parse(json['creation']),
      modified: DateTime.parse(json['modified']),
      modifiedBy: json['modified_by'],
      docStatus: FrappeDocStatus.parse(json['docstatus']),
      paidAmount: json['paid_amount'],
    );
  }

  final double paidAmount;
}
