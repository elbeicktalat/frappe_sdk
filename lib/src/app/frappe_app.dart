// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:frappe_sdk/src/call/data/data_source/remote/frappe_call_remote_data_source_impl.dart';
import 'package:frappe_sdk/src/call/data/repository/frappe_call_repository_impl.dart';
import 'package:frappe_sdk/src/call/domain/repository/frappe_call_repository.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source_impl.dart';
import 'package:frappe_sdk/src/db/data/repository/frappe_db_repository_impl.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:frappe_sdk/src/utils/token_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Frappe application.
class FrappeApp {
  /// Creates a new Frappe application.
  const FrappeApp({
    required this.url,
    required this.name,
    required BaseCacheManager cacheManager,
    required SharedPreferences sharedPreferences,
    this.useToken = true,
    this.headers = const <String, String>{},
    this.token,
    this.tokenType = TokenType.token,
  })  : _cacheManager = cacheManager,
        _sharedPreferences = sharedPreferences;

  /// The url of the Frappe application.
  final Uri url;

  /// The name of the Frappe application.
  final String name;

  /// The headers of the Frappe application.
  final Map<String, String> headers;

  /// Whether to use the token or not.
  final bool useToken;

  /// The token of the Frappe application.
  final String? token;

  /// The token type of the Frappe application.
  final TokenType tokenType;

  /// The [CacheManager] instance.
  final BaseCacheManager _cacheManager;

  /// The [SharedPreferences] instance.
  final SharedPreferences _sharedPreferences;

  /// The [FrappeDBRepository] instance.
  FrappeDBRepository get db => FrappeDBRepositoryImpl(
        FrappeDBRemoteDataSourceImpl(_dio),
        _cacheManager,
        _sharedPreferences,
      );

  /// The [FrappeCallRepository] instance.
  FrappeCallRepository get call => FrappeCallRepositoryImpl(
        FrappeCallRemoteDataSourceImpl(_dio),
      );

  Dio get _dio {
    final Map<String, String> headersCopy = Map<String, String>.from(headers);
    if (useToken) headersCopy['authorization'] = '${tokenType.value} $token';

    return Dio(
      BaseOptions(
        baseUrl: url.toString(),
        headers: headersCopy,
      ),
    );
  }
}
