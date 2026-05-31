// Copyright (©) 2025. Talat El Beick. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

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

  Future<void> _ensureMetadataTable() async {
    if (_knownTables.containsKey('__frappe_metadata')) return;

    await _database.execute('''
      CREATE TABLE IF NOT EXISTS "__frappe_metadata" (
        doctype TEXT,
        name TEXT,
        is_full INTEGER,
        child_tables TEXT,
        modified TEXT,
        PRIMARY KEY (doctype, name)
      )
    ''');
    _knownTables['__frappe_metadata'] = {'doctype', 'name', 'is_full', 'child_tables', 'modified'};
  }

  String _getTableName(String docType) => 'tab${docType.replaceAll(' ', '_')}';

  Future<void> _ensureTableAndColumns(String docType, Map<String, dynamic> data) async {
    final String tableName = _getTableName(docType);
    final Set<String>? knownColumns = _knownTables[tableName];

    if (knownColumns == null) {
      // Table might not exist.
      // We use PRIMARY KEY WITHOUT ROWID if possible or just standard PRIMARY KEY.
      // Column "name" and "modified" are core.
      await _database.execute('''
        CREATE TABLE IF NOT EXISTS "$tableName" (
          name TEXT PRIMARY KEY,
          modified TEXT
        )
      ''');

      final List<Map<String, dynamic>> columns =
          await _database.rawQuery('PRAGMA table_info("$tableName")');
      final Set<String> currentColumns =
          columns.map((Map<String, dynamic> c) => c['name'] as String).toSet();
      _knownTables[tableName] = currentColumns;
      await _ensureColumns(tableName, data, currentColumns);
    } else {
      await _ensureColumns(tableName, data, knownColumns);
    }
  }

  Future<void> _ensureColumns(
    String tableName,
    Map<String, dynamic> data,
    Set<String> currentColumns,
  ) async {
    for (final String key in data.keys) {
      if (!currentColumns.contains(key)) {
        // We use column definition WITHOUT type affinity.
        // SQLite will store the value with its natural type (INTEGER, REAL, TEXT, BLOB).
        // This is crucial for SUM(), AVG(), etc.
        await _database.execute('ALTER TABLE "$tableName" ADD COLUMN "$key"');
        currentColumns.add(key);
      }
    }
  }

  Map<String, dynamic> _prepareDataForSql(Map<String, dynamic> data) {
    return data.map((String key, dynamic value) {
      // Preserve primitives (int, double, String, null).
      // Convert bool to int (0/1) for SQLite compatibility.
      if (value is bool) {
        return MapEntry<String, dynamic>(key, value ? 1 : 0);
      }
      // Stringify only complex objects (List, Map).
      if (value is Map || value is List) {
        return MapEntry<String, dynamic>(key, json.encode(value));
      }
      return MapEntry<String, dynamic>(key, value);
    });
  }

  Map<String, dynamic> _parseSqlData(Map<String, dynamic> row) {
    return row.map((String key, dynamic value) {
      if (value is String) {
        // Try to detect if it's a stringified JSON (Map or List).
        final String trimmed = value.trim();
        if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
            (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
          try {
            return MapEntry<String, dynamic>(key, json.decode(value));
          } catch (_) {
            return MapEntry<String, dynamic>(key, value);
          }
        }
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
    final Map<String, dynamic>? doc = await getDocRaw(docType, docName);
    if (doc == null) return null;
    return fromJson(doc);
  }

  @override
  Future<Map<String, dynamic>?> getDocRaw(String docType, String docName) async {
    final String tableName = _getTableName(docType);
    try {
      await _ensureMetadataTable();
      final List<Map<String, dynamic>> maps = await _database.query(
        '"$tableName"',
        where: 'name = ?',
        whereArgs: <String>[docName],
        limit: 1,
      );

      if (maps.isEmpty) return null;

      final Map<String, dynamic> doc = _parseSqlData(maps.first);

      // Load metadata
      final List<Map<String, dynamic>> metaMaps = await _database.query(
        '"__frappe_metadata"',
        where: 'doctype = ? AND name = ?',
        whereArgs: <String>[docType, docName],
        limit: 1,
      );

      if (metaMaps.isNotEmpty) {
        final Map<String, dynamic> meta = metaMaps.first;
        doc['__is_full'] = meta['is_full'];

        if (meta['child_tables'] != null) {
          final Map<String, dynamic> mapping =
              json.decode(meta['child_tables'] as String) as Map<String, dynamic>;
          for (final String field in mapping.keys) {
            final String childDocType = mapping[field] as String;
            final List<Map<String, dynamic>>? children =
                await _fetchChildren(childDocType, docName, docType, field);
            doc[field] = children ?? <Map<String, dynamic>>[];
          }
        }
      }

      return doc;
    } catch (_) {
      // Table might not exist yet
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchChildren(
    String docType,
    String parentName,
    String parentType,
    String parentField,
  ) async {
    final String tableName = _getTableName(docType);
    try {
      final List<Map<String, dynamic>> maps = await _database.query(
        '"$tableName"',
        where: 'parent = ? AND parenttype = ? AND parentfield = ?',
        whereArgs: <String>[parentName, parentType, parentField],
      );

      final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
      for (final Map<String, dynamic> row in maps) {
        final Map<String, dynamic> childDoc = _parseSqlData(row);

        // Load metadata for child recursive loading
        final List<Map<String, dynamic>> metaMaps = await _database.query(
          '"__frappe_metadata"',
          where: 'doctype = ? AND name = ?',
          whereArgs: <String>[docType, childDoc['name']],
          limit: 1,
        );

        if (metaMaps.isNotEmpty) {
          final Map<String, dynamic> meta = metaMaps.first;
          if (meta['child_tables'] != null) {
            final Map<String, dynamic> mapping =
                json.decode(meta['child_tables'] as String) as Map<String, dynamic>;
            for (final String field in mapping.keys) {
              final String grandChildDocType = mapping[field] as String;
              final List<Map<String, dynamic>>? grandChildren = await _fetchChildren(
                  grandChildDocType, childDoc['name'] as String, docType, field);
              childDoc[field] = grandChildren ?? <Map<String, dynamic>>[];
            }
          }
        }
        results.add(childDoc);
      }
      return results;
    } catch (_) {
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

    final String? orderBySql =
        orderBy != null ? '"${orderBy.field}" ${orderBy.desc ? 'DESC' : 'ASC'}' : null;

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

      return maps.map((Map<String, dynamic> row) => fromJson(_parseSqlData(row))).toList();
    } catch (_) {
      // Table might not exist or columns might be missing
      return <T?>[];
    }
  }

  @override
  Future<void> saveDoc(
    String docType,
    Map<String, dynamic> data, {
    bool isFull = false,
  }) async {
    if (!data.containsKey('name')) return;

    final Map<String, dynamic> docToSave = Map<String, dynamic>.from(data);

    // Recursively find and save child tables
    final Map<String, String> childTableMapping = <String, String>{};
    final List<String> keys = docToSave.keys.toList();
    for (final String key in keys) {
      final dynamic value = docToSave[key];
      if (value is List) {
        if (value.isNotEmpty) {
          // Check if it's a list of child documents (they must have a doctype)
          final dynamic firstItem = value.first;
          if (firstItem is Map<String, dynamic> && firstItem.containsKey('doctype')) {
            final String childDocType = firstItem['doctype'] as String;
            childTableMapping[key] = childDocType;

            final List<Map<String, dynamic>> childDocs =
                value.cast<Map<String, dynamic>>().map((Map<String, dynamic> child) {
              return <String, dynamic>{
                ...child,
                'parent': docToSave['name'],
                'parenttype': docType,
                'parentfield': key,
              };
            }).toList();

            // Save child documents in their own standalone table
            await saveDocList(childDocType, childDocs, isFull: isFull);
          }
        }
        // Remove ANY List from parent to avoid creating columns in the main table
        docToSave.remove(key);
      }
    }

    // Save metadata to __frappe_metadata
    await _ensureMetadataTable();
    final String? modified = docToSave['modified'] as String?;

    // We use a custom SQL to handle the ON CONFLICT for metadata
    const String metaSql = '''
      INSERT INTO "__frappe_metadata" (doctype, name, is_full, child_tables, modified)
      VALUES (?, ?, ?, ?, ?)
      ON CONFLICT(doctype, name) DO UPDATE SET
        is_full = (CASE 
          WHEN EXCLUDED.is_full = 1 THEN 1 
          WHEN "__frappe_metadata".modified IS EXCLUDED.modified AND "__frappe_metadata".is_full = 1 THEN 1 
          ELSE 0 END),
        child_tables = (CASE
          WHEN EXCLUDED.child_tables IS NOT NULL THEN EXCLUDED.child_tables
          ELSE "__frappe_metadata".child_tables END),
        modified = EXCLUDED.modified
    ''';

    await _database.rawInsert(metaSql, <dynamic>[
      docType,
      docToSave['name'],
      if (isFull) 1 else 0,
      if (isFull || childTableMapping.isNotEmpty) json.encode(childTableMapping) else null,
      modified,
    ]);

    await _ensureTableAndColumns(docType, docToSave);
    final String tableName = _getTableName(docType);
    final Map<String, dynamic> sqlData = _prepareDataForSql(docToSave);

    final List<String> columns = sqlData.keys.toList();
    final List<String> placeholders = List<String>.filled(columns.length, '?');
    final List<String> updateClauses =
        columns.where((String c) => c != 'name').map((String c) => '"$c" = EXCLUDED."$c"').toList();

    final String sql = '''
      INSERT INTO "$tableName" (${columns.map((String c) => '"$c"').join(', ')})
      VALUES (${placeholders.join(', ')})
      ON CONFLICT(name) DO UPDATE SET
      ${updateClauses.join(', ')}
    ''';

    await _database.rawInsert(sql, sqlData.values.toList());
  }

  @override
  Future<void> saveDocList(
    String docType,
    List<Map<String, dynamic>> docs, {
    bool isFull = false,
  }) async {
    if (docs.isEmpty) return;

    // We process each doc individually to handle potential recursive children in each item
    for (final Map<String, dynamic> doc in docs) {
      await saveDoc(docType, doc, isFull: isFull);
    }
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
      await _ensureMetadataTable();
      await _database.delete(
        '"__frappe_metadata"',
        where: 'doctype = ? AND name = ?',
        whereArgs: <String>[docType, docName],
      );
    } catch (_) {}
  }

  @override
  Future<void> clear(String docType) async {
    final String tableName = _getTableName(docType);
    try {
      await _database.delete('"$tableName"');
      await _ensureMetadataTable();
      await _database.delete(
        '"__frappe_metadata"',
        where: 'doctype = ?',
        whereArgs: <String>[docType],
      );
    } catch (_) {}
  }

  @override
  Future<void> clearAll() async {
    final List<Map<String, dynamic>> tables = await _database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE 'tab%' OR name = '__frappe_metadata')");
    final Batch batch = _database.batch();
    for (final Map<String, dynamic> table in tables) {
      batch.delete('"${table['name']}"');
    }
    await batch.commit(noResult: true);
  }

  String _getSqlOperator(FilterOperator operator) {
    return switch (operator) {
      FilterOperator.equal => '=',
      FilterOperator.notEqual => '!=',
      FilterOperator.greaterThan => '>',
      FilterOperator.greaterThanOrEqual => '>=',
      FilterOperator.lessThan => '<',
      FilterOperator.lessThanOrEqual => '<=',
      FilterOperator.like => 'LIKE',
      FilterOperator.notLike => 'NOT LIKE',
      FilterOperator.$in => 'IN',
      FilterOperator.notIn => 'NOT IN',
      FilterOperator.between => 'BETWEEN'
    };
  }
}
