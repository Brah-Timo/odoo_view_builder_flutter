// lib/data/repositories/view_repository.dart

import '../local_storage/local_database_helper.dart';
import '../models/odoo_form.dart';

/// Abstract contract for view persistence
abstract class ViewRepository {
  Future<void> save(OdooView view);
  Future<OdooView?> findById(String id);
  Future<List<OdooView>> findAll();
  Future<List<OdooView>> search({String? query, String? model, String? viewType});
  Future<void> delete(String id);
  Future<void> deleteAll();
  Future<int> count();
}

/// SQLite-backed implementation
class LocalViewRepository implements ViewRepository {
  final LocalDatabaseHelper _db;

  LocalViewRepository({LocalDatabaseHelper? db})
      : _db = db ?? LocalDatabaseHelper.instance;

  @override
  Future<void> save(OdooView view) => _db.saveView(view);

  @override
  Future<OdooView?> findById(String id) => _db.loadView(id);

  @override
  Future<List<OdooView>> findAll() => _db.loadAllViews();

  @override
  Future<List<OdooView>> search({
    String? query,
    String? model,
    String? viewType,
  }) =>
      _db.searchViews(query: query, model: model, viewType: viewType);

  @override
  Future<void> delete(String id) => _db.deleteView(id);

  @override
  Future<void> deleteAll() => _db.deleteAllViews();

  @override
  Future<int> count() => _db.countViews();
}
