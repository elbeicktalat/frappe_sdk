/// Represents a filter operator.
enum FilterOperator {
  /// The equal operator.
  equal('='),

  /// The not equal operator.
  notEqual('!='),

  /// The greater than operator.
  greaterThan('>'),

  /// The greater than or equal operator.
  greaterThanOrEqual('>='),

  /// The less than operator.
  lessThan('<'),

  /// The less than or equal operator.
  lessThanOrEqual('<='),

  /// The like operator.
  like('like'),

  /// The not like operator.
  notLike('not like'),

  /// The in operator.
  $in('in'),

  /// The not in operator.
  notIn('not in'),

  /// The between operator.
  between('between');

  const FilterOperator(this.symbol);

  /// The symbol of the operator.
  final String symbol;
}
