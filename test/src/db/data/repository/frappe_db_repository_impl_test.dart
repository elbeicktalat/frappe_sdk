// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'package:frappe_sdk/src/db/data/data_source/local/frappe_db_local_data_source.dart';
import 'package:frappe_sdk/src/db/data/data_source/remote/frappe_db_remote_data_source.dart';
import 'package:frappe_sdk/src/db/data/repository/frappe_db_repository_impl.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/utils/cache_strategy.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';
import 'package:test/test.dart';

class MockRemoteDataSource implements FrappeDBRemoteDataSource {
  List<Map<String, dynamic>> remoteDocs = [];
  int getDocListCount = 0;
  List<Set<String>?> lastFields = [];
  List<List<Filter>?> lastFilters = [];

  @override
  Future<List<T?>?> getDocList<T>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    Set<String>? fields,
    List<Filter>? filters,
    List<Filter>? orFilters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
    String? groupBy,
  }) async {
    getDocListCount++;
    lastFields.add(fields);
    lastFilters.add(filters);

    List<Map<String, dynamic>> results = remoteDocs;

    // Very basic filter handling for tests
    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        if (filter.field == 'name' && filter.value is List) {
          final List names = filter.value as List;
          results = results.where((doc) => names.contains(doc['name'])).toList();
        }
      }
    }

    return results
        .map((doc) {
          if (fields != null) {
            final Map<String, dynamic> filtered = {};
            for (final f in fields) {
              if (doc.containsKey(f)) filtered[f] = doc[f];
            }
            return fromJson(filtered);
          }
          return fromJson(doc);
        })
        .toList()
        .cast<T?>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocalDataSource implements FrappeDBLocalDataSource {
  Map<String, Map<String, dynamic>> cache = {};
  int saveDocListCount = 0;

  @override
  Future<List<T?>?> getDocList<T>(
    String docType, {
    required T Function(Map<String, dynamic> json) fromJson,
    Set<String>? fields,
    List<Filter>? filters,
    List<Filter>? orFilters,
    int? limit,
    int? limitStart,
    OrderBy? orderBy,
    String? groupBy,
  }) async {
    List<Map<String, dynamic>> results = cache.values.toList();

    if (filters != null && filters.isNotEmpty) {
      for (final filter in filters) {
        if (filter.field == 'name' && filter.value is List) {
          final List names = filter.value as List;
          results = results.where((doc) => names.contains(doc['name'])).toList();
        }
      }
    }

    return results.map((doc) => fromJson(doc)).toList().cast<T?>();
  }

  @override
  Future<void> saveDocList(String docType, List<Map<String, dynamic>> docs,
      {bool isFull = false}) async {
    saveDocListCount++;
    for (final doc in docs) {
      cache[doc['name']] = Map<String, dynamic>.from(doc);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FrappeDBRepositoryImpl repository;
  late MockRemoteDataSource remote;
  late MockLocalDataSource local;

  setUp(() {
    remote = MockRemoteDataSource();
    local = MockLocalDataSource();
    repository = FrappeDBRepositoryImpl(remote, local);
  });

  test('networkFirst strategy should only fetch stale docs', () async {
    // 1. Initial state: Cache has two docs, Remote has the same two docs.
    local.cache = {
      'Doc1': {'name': 'Doc1', 'modified': '2023-01-01', 'field1': 'old1'},
      'Doc2': {'name': 'Doc2', 'modified': '2023-01-01', 'field1': 'old2'},
    };
    remote.remoteDocs = [
      {'name': 'Doc1', 'modified': '2023-01-01', 'field1': 'old1'}, // Fresh
      {'name': 'Doc2', 'modified': '2023-01-02', 'field1': 'new2'}, // Stale
    ];

    // 2. Request getDocList with networkFirst
    final results = await repository.getDocList(
      'TestType',
      fields: {'name', 'modified', 'field1'},
      strategy: CacheStrategy.networkFirst,
      fromJson: (json) => json,
    );

    // 3. Verifications
    // Should have called remote twice:
    // - first for name/modified check
    // - second for FETCHING ONLY STALE DOCS
    expect(remote.getDocListCount, 2);

    // Check first call fields
    expect(remote.lastFields[0], containsAll(['name', 'modified']));

    // Check second call filters - should only request Doc2
    final secondCallFilters = remote.lastFilters[1];
    expect(secondCallFilters, isNotNull);
    final nameFilter = secondCallFilters!.firstWhere((f) => f.field == 'name');
    expect(nameFilter.value, contains('Doc2'));
    expect(nameFilter.value, isNot(contains('Doc1')));

    // Results should be correct
    expect(results!.length, 2);
    expect(results[0]!['name'], 'Doc1');
    expect(results[1]!['name'], 'Doc2');
    expect(results[1]!['field1'], 'new2');

    // Cache should be updated
    expect(local.cache['Doc2']!['field1'], 'new2');
    expect(local.saveDocListCount, 1); // One call to save stale docs
  });

  test('networkFirst strategy should fetch docs if cache is missing fields', () async {
    local.cache = {
      'Doc1': {'name': 'Doc1', 'modified': '2023-01-01'}, // Missing 'field1'
    };
    remote.remoteDocs = [
      {'name': 'Doc1', 'modified': '2023-01-01', 'field1': 'val1'},
    ];

    final results = await repository.getDocList(
      'TestType',
      fields: {'name', 'modified', 'field1'},
      strategy: CacheStrategy.networkFirst,
      fromJson: (json) => json,
    );

    expect(remote.getDocListCount, 2);
    final secondCallFilters = remote.lastFilters[1];
    expect(secondCallFilters!.firstWhere((f) => f.field == 'name').value, contains('Doc1'));
    expect(results![0]!['field1'], 'val1');
  });
}
