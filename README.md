# Frappe sdk

The dart library for Frappe REST API, this package provides a clean and simple way to connect
to your frappe instance.

[![Github stars](https://img.shields.io/github/stars/elbeicktalat/frappe_sdk?logo=github)](https://github.com/elbeicktalat/frappe_sdk)
[![Pub Version](https://img.shields.io/pub/v/frappe_sdk?color=blue&logo=dart)](https://pub.dev/packages/frappe_sdk)

## Index

- [Features](#features)
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Database](#database)
- [Call](#call)

## Features

The library currently supports the following features:

- 🗄 Database - Get document, get list of documents, get count, create, update and delete documents.

## Installation

Add this to your packages pubspec.yaml file:

```yaml
dependencies:
  frappe_sdk: <^last>
```

## Getting Started

```dart
void main() async {
  final FrappeApp app = FrappeApp(
    url: Uri.parse('https://your-frappe-instance.com'),
    name: 'your-frappe-instance-name',
    token: '<api-key>:<secret-key>', // or bearer token
  );
}
```

## Database

### Fetch document using document name

```dart
void myMethod(FrappeApp app) async {
  final FrappeDBRepository db = app.db;

  final PaymentEntry? paymentEntry = await db.getDoc<PaymentEntry>(
    'Payment Entry',
    'PV25-00188',
    fromJson: PaymentEntry.fromJson,
  );

  print(paymentEntry?.idx); // 5
  print(paymentEntry?.name); // 'PV25-00188'
  print(paymentEntry?.owner); // your@example.com
  print(paymentEntry?.creation); // 2025-01-30 22:42:25.505246
  print(paymentEntry?.modified); // 2025-01-30 22:42:35.739509
  print(paymentEntry?.modifiedBy); // your@example.com
  print(paymentEntry?.docStatus); // FrappeDocStatus.submitted
  print(paymentEntry?.paidAmount); // 1000.0
}

/// Represents a payment entry. (Frappe Doc)
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

  // add more fields here...
  final double paidAmount;
}
```

## Call

The call repo allow you to make calls to method on the frappe instance.
You can use it to make calls to the following pre defined methods:

- get_balance_on
- get_fiscal_year
- get_company_default
- get_companies
- get_children
- get_stock_balance
- scan_barcode
- get_exchange_rate

Get balance for account

```dart
void main() {
  final FrappeCallRepository call = app.call;
  
  final double? result = await call.getBalance(
    account: '1100 - Cash In Hand - PPS',
  );
}
```

You can also call any method that is defined on the frappe instance.
```dart
void main() {
  final FrappeCallRepository call = app.call;

  final double? balance = await call(
    'erpnext.setup.utils.get_exchange_rate',
    fromJson: (JSON json) => json['message'],
    params: <String, Object?>{
      'from_currency': 'EUR',
      'to_currency': 'USD',
    },
  );
  
  // or pre-define method
  final double? result = await call.getExchangeRate(
    fromCurrency: 'EUR',
    toCurrency: 'USD',
  );
}
```
Behind the scenes all `FrappeCallRepository` make you of `FrappeCallRepository.call` method.