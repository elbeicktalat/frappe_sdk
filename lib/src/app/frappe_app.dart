// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:dio/dio.dart';
import 'package:frappe_sdk/src/call/data/data_source/remote/frappe_call_remote_data_source_impl.dart';
import 'package:frappe_sdk/src/call/data/repository/frappe_call_repository_impl.dart';
import 'package:frappe_sdk/src/call/domain/repository/frappe_call_repository.dart';
import 'package:frappe_sdk/src/db/data/data_source/local/frappe_db_local_data_source.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source_impl.dart';
import 'package:frappe_sdk/src/db/data/repository/frappe_db_repository_impl.dart';
import 'package:frappe_sdk/src/db/domain/repository/frappe_db_repository.dart';
import 'package:frappe_sdk/src/db/domain/utils/cache_strategy.dart';

/// The Frappe application.
class FrappeApp {
  /// Creates a new Frappe application.
  FrappeApp({
    required Dio dio,
    required FrappeDBLocalDataSource localDataSource,
    this.defaultStrategy = CacheStrategy.cacheFirst,
  })  : _dio = dio,
        _localDataSource = localDataSource;

  /// The [Dio] instance.
  final Dio _dio;

  /// The [FrappeDBLocalDataSource] instance.
  final FrappeDBLocalDataSource _localDataSource;

  /// The default caching strategy.
  final CacheStrategy defaultStrategy;

  /// The [FrappeDBRepository] instance.
  FrappeDBRepository get db => FrappeDBRepositoryImpl(
        FrappeDBRemoteDataSourceImpl(_dio),
        _localDataSource,
        defaultStrategy: defaultStrategy,
      );

  /// The [FrappeCallRepository] instance.
  FrappeCallRepository get call => FrappeCallRepositoryImpl(
        FrappeCallRemoteDataSourceImpl(_dio),
      );
}
