import 'package:frappe_sdk/src/app/frappe_app.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc.dart';
import 'package:frappe_sdk/src/db/domain/entity/frappe_doc/frappe_doc_status.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';

void main() async {
  final FrappeApp app = FrappeApp(
    url: Uri.parse('https://your-frappe-instance.com'),
    name: 'PIPPOS',
    token: '<api-key>:<secret-key>',
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
