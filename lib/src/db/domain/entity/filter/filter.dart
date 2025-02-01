import 'package:frappe_sdk/src/db/domain/entity/filter/filter_operator.dart';

/// Represents a filter.
final class Filter {
  /// Creates a new filter.
  Filter({
    required this.field,
    required this.operator,
    required this.value,
  });

  /// The field to filter by.
  final String field;

  /// The operator to use.
  final FilterOperator operator;

  /// The value to filter by.
  final Object value;
}
