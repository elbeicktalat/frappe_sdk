// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

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
