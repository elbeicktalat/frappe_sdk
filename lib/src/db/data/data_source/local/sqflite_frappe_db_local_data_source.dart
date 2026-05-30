// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:frappe_sdk/src/db/data/data_source/local/frappe_db_local_data_source.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter.dart';
import 'package:frappe_sdk/src/db/domain/entity/filter/filter_operator.dart';
import 'package:frappe_sdk/src/db/domain/utils/typedefs.dart';
import 'package:sqflite/sqflite.dart';

/// An implementation of [FrappeDBLocalDataSource] that uses [sqflite]
/// with a dynamic schema (table per doctype, column per field).
class SqfliteFrappeDBLocalDataSource implements FrappeDBLocalDataSource {
  /// Creates a new instance of [SqfliteFrappeDBLocalDataSource].
  SqfliteFrappeDBLocalDataSource(this._database);

  final Database _database;

  // Cache to track which tables and columns we've already verified in this session
  final Map<String, Set<String>> _knownTables = <String, Set<String>>{};

  String _getTableName(String docType) => 'doctype_${docType.replaceAll(' ', '_')}';

  Future<void> _ensureTableAndColumns(String docType, Map<String, dynamic> data) async {
    final String tableName = _getTableName(docType);
    final Set<String>? knownColumns = _knownTables[tableName];

    if (knownColumns == null) {
      // Table might not exist
      await _database.execute('''
        CREATE TABLE IF NOT EXISTS "$tableName" (
          name TEXT PRIMARY KEY,
          modified TEXT
        )
      ''');
      
      final List<Map<String, dynamic>> columns = await _database.rawQuery('PRAGMA table_info("$tableName")');
      final Set<String> currentColumns = columns.map((Map<String, dynamic> c) => c['name'] as String).toSet();
      _knownTables[tableName] = currentColumns;
      await _ensureColumns(tableName, data, currentColumns);
    } else {
      await _ensureColumns(tableName, data, knownColumns);
    }
  }

  Future<void> _ensureColumns(String tableName, Map<String, dynamic> data, Set<String> currentColumns) async {
    for (final String key in data.keys) {
      if (!currentColumns.contains(key)) {
        // Add missing column. We use TEXT for simplicity as Frappe types vary and SQFlite is flexible.
        // For complex types, we store as JSON strings.
        await _database.execute('ALTER TABLE "$tableName" ADD COLUMN "$key" TEXT');
        currentColumns.add(key);
      }
    }
  }

  Map<String, dynamic> _prepareDataForSql(Map<String, dynamic> data) {
    return data.map((String key, dynamic value) {
      if (value is Map || value is List) {
        return MapEntry<String, dynamic>(key, value.toString());
      }
      return MapEntry<String, dynamic>(key, value);
    });
  }

  @override
  Future<T?> getDoc<T>(
    String docType,
    String docName, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final String tableName = _getTableName(docType);
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        '"$tableName"',
        where: 'name = ?',
        whereArgs: <String>[docName],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return fromJson(maps.first);
    } catch (_) {
      // Table might not exist yet
      return null;
    }
  }

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
    final String tableName = _getTableName(docType);
    final List<String> whereClauses = <String>[];
    final List<dynamic> whereArgs = <dynamic>[];

    if (filters != null && filters.isNotEmpty) {
      for (final Filter filter in filters) {
        whereClauses.add('"${filter.field}" ${_getSqlOperator(filter.operator)} ?');
        whereArgs.add(filter.value);
      }
    }

    final String? orderBySql = orderBy != null ? '"${orderBy.field}" ${orderBy.desc ? 'DESC' : 'ASC'}' : null;

    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        '"$tableName"',
        columns: fields?.toList(),
        where: whereClauses.isEmpty ? null : whereClauses.join(' AND '),
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        limit: limit,
        offset: limitStart,
        orderBy: orderBySql,
        groupBy: groupBy,
      );

      return maps.map(fromJson).toList();
    } catch (_) {
      // Table might not exist or columns might be missing
      return <T?>[];
    }
  }

  @override
  Future<void> saveDoc(String docType, Map<String, dynamic> data) async {
    if (!data.containsKey('name')) return;
    
    await _ensureTableAndColumns(docType, data);
    final String tableName = _getTableName(docType);
    final Map<String, dynamic> sqlData = _prepareDataForSql(data);

    // SQLite Upsert (Partial update)
    final List<String> columns = sqlData.keys.toList();
    final List<String> placeholders = List<String>.filled(columns.length, '?');
    final List<String> updateClauses = columns.where((String c) => c != 'name').map((String c) => '"$c" = EXCLUDED."$c"').toList();

    final String sql = '''
      INSERT INTO "$tableName" (${columns.map((String c) => '"$c"').join(', ')})
      VALUES (${placeholders.join(', ')})
      ON CONFLICT(name) DO UPDATE SET
      ${updateClauses.join(', ')}
    ''';

    await _database.rawInsert(sql, sqlData.values.toList());
  }

  @override
  Future<void> saveDocList(String docType, List<Map<String, dynamic>> docs) async {
    if (docs.isEmpty) return;
    
    // Ensure table and all potential columns exist first (based on the first doc as heuristic)
    // In a more robust impl, we'd check all docs if they have different fields.
    for (final Map<String, dynamic> doc in docs) {
      await _ensureTableAndColumns(docType, doc);
    }

    final String tableName = _getTableName(docType);
    final Batch batch = _database.batch();

    for (final Map<String, dynamic> data in docs) {
      if (!data.containsKey('name')) continue;
      final Map<String, dynamic> sqlData = _prepareDataForSql(data);
      
      final List<String> columns = sqlData.keys.toList();
      final List<String> placeholders = List<String>.filled(columns.length, '?');
      final List<String> updateClauses = columns.where((String c) => c != 'name').map((String c) => '"$c" = EXCLUDED."$c"').toList();

      final String sql = '''
        INSERT INTO "$tableName" (${columns.map((String c) => '"$c"').join(', ')})
        VALUES (${placeholders.join(', ')})
        ON CONFLICT(name) DO UPDATE SET
        ${updateClauses.join(', ')}
      ''';
      
      batch.rawInsert(sql, sqlData.values.toList());
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<void> deleteDoc(String docType, String docName) async {
    final String tableName = _getTableName(docType);
    try {
      await _database.delete(
        '"$tableName"',
        where: 'name = ?',
        whereArgs: <String>[docName],
      );
    } catch (_) {}
  }

  @override
  Future<void> clear(String docType) async {
    final String tableName = _getTableName(docType);
    try {
      await _database.delete('"$tableName"');
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    final List<Map<String, dynamic>> tables = await _database.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'doctype_%'"
    );
    final Batch batch = _database.batch();
    for (final Map<String, dynamic> table in tables) {
      batch.delete('"${table['name']}"');
    }
    await batch.commit(noResult: true);
  }

  String _getSqlOperator(FilterOperator operator) {
    switch (operator) {
      case FilterOperator.equal: return '=';
      case FilterOperator.notEqual: return '!=';
      case FilterOperator.greaterThan: return '>';
      case FilterOperator.greaterThanOrEqual: return '>=';
      case FilterOperator.lessThan: return '<';
      case FilterOperator.lessThanOrEqual: return '<=';
      case FilterOperator.like: return 'LIKE';
      case FilterOperator.notLike: return 'NOT LIKE';
      case FilterOperator.$in: return 'IN';
      case FilterOperator.notIn: return 'NOT IN';
      case FilterOperator.between: return 'BETWEEN';
    }
  }
}
