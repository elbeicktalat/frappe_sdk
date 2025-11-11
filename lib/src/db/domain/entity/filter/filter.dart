// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/domain/entity/filter/filter_operator.dart';

/// Represents a filter.
final class Filter {
  /// Creates a new filter.
  Filter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.equal].
  Filter.equal(String field, Object value)
      : this(field: field, operator: FilterOperator.equal, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.notEqual].
  Filter.notEqual(String field, Object value)
      : this(field: field, operator: FilterOperator.notEqual, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.lessThan].
  Filter.lessThan(String field, Object value)
      : this(field: field, operator: FilterOperator.lessThan, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.lessThanOrEqual].
  Filter.lessThanOrEqual(String field, Object value)
      : this(field: field, operator: FilterOperator.lessThanOrEqual, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.greaterThan].
  Filter.greaterThan(String field, Object value)
      : this(field: field, operator: FilterOperator.greaterThan, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.greaterThanOrEqual].
  Filter.greaterThanOrEqual(String field, Object value)
      : this(field: field, operator: FilterOperator.greaterThanOrEqual, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.like].
  Filter.like(String field, Object value)
      : this(field: field, operator: FilterOperator.like, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.notLike].
  Filter.notLike(String field, Object value)
      : this(field: field, operator: FilterOperator.notLike, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.$in].
  Filter.in_(String field, Object value)
      : this(field: field, operator: FilterOperator.$in, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.notIn].
  Filter.notIn(String field, Object value)
      : this(field: field, operator: FilterOperator.notIn, value: value);

  /// Creates a new filter with the given field and value.
  /// The operator will be [FilterOperator.between].
  Filter.between(String field, Object value)
      : this(field: field, operator: FilterOperator.between, value: value);

  /// The field to filter by.
  final String field;

  /// The operator to use.
  final FilterOperator operator;

  /// The value to filter by.
  final Object value;

  /// Converts the filter instance to a JSON encodable map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'field': field,
      'operator': operator.symbol,
      'value': value,
    };
  }
}
