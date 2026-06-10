// lib/data/local_storage/local_database_helper.dart

import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../config/constants.dart';
import '../models/odoo_form.dart';

/// SQLite persistence layer for saved views
class LocalDatabaseHelper {
  LocalDatabaseHelper._();
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableViews} (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        model TEXT NOT NULL,
        view_type TEXT NOT NULL,
        json_data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_views_model ON ${AppConstants.tableViews} (model)
    ''');

    await db.execute('''
      CREATE INDEX idx_views_view_type ON ${AppConstants.tableViews} (view_type)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations go here
  }

  // ─── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> saveView(OdooView view) async {
    final db = await database;
    await db.insert(
      AppConstants.tableViews,
      {
        'id': view.id,
        'name': view.name,
        'model': view.model,
        'view_type': view.viewType.value,
        'json_data': jsonEncode(view.toJson()),
        'created_at': view.createdAt.toIso8601String(),
        'updated_at': view.updatedAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OdooView?> loadView(String id) async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableViews,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    return _rowToView(rows.first);
  }

  Future<List<OdooView>> loadAllViews() async {
    final db = await database;
    final rows = await db.query(
      AppConstants.tableViews,
      orderBy: 'updated_at DESC',
    );
    return rows.map(_rowToView).whereType<OdooView>().toList();
  }

  Future<List<OdooView>> searchViews({
    String? query,
    String? model,
    String? viewType,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (query != null && query.isNotEmpty) {
      conditions.add('(name LIKE ? OR model LIKE ?)');
      args.addAll(['%$query%', '%$query%']);
    }
    if (model != null && model.isNotEmpty) {
      conditions.add('model = ?');
      args.add(model);
    }
    if (viewType != null && viewType.isNotEmpty) {
      conditions.add('view_type = ?');
      args.add(viewType);
    }

    final where = conditions.isEmpty ? null : conditions.join(' AND ');

    final rows = await db.query(
      AppConstants.tableViews,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updated_at DESC',
    );

    return rows.map(_rowToView).whereType<OdooView>().toList();
  }

  Future<void> deleteView(String id) async {
    final db = await database;
    await db.delete(
      AppConstants.tableViews,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllViews() async {
    final db = await database;
    await db.delete(AppConstants.tableViews);
  }

  Future<int> countViews() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${AppConstants.tableViews}');
    return result.first['count'] as int? ?? 0;
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────────

  OdooView? _rowToView(Map<String, dynamic> row) {
    try {
      final jsonData = jsonDecode(row['json_data'] as String)
          as Map<String, dynamic>;
      return OdooView.fromJson(jsonData);
    } catch (e) {
      return null;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
