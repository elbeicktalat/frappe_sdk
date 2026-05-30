// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.


// implement auth layer


/// Repository for interacting with the Frappe authentication.
abstract interface class FrappeAuthRepository {
  /// {@template FrappeAuthRepository.login}
  /// Login to the Frappe application.
  ///
  /// * [username] The username.
  /// * [password] The password.
  ///
  /// {@endtemplate}
  Future<String?> login({
    required String username,
    required String password,
    String? otp,
    String? otpSecret,
  });
}
