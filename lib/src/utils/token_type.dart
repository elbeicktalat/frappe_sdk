/// The token type.
enum TokenType {
  /// Bearer token.
  bearer('Bearer'),

  /// Token `<api-key>:<secret-key>`.
  token('token');

  const TokenType(this.value);

  /// The value of the token type.
  final String value;
}
