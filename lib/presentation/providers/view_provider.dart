// lib/presentation/providers/view_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/odoo_form.dart';
import '../../data/repositories/view_repository.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final viewRepositoryProvider = Provider<ViewRepository>((ref) {
  return LocalViewRepository();
});

// ─── All Saved Views ─────────────────────────────────────────────────────────

final savedViewsProvider =
    AsyncNotifierProvider<SavedViewsNotifier, List<OdooView>>(
  SavedViewsNotifier.new,
);

class SavedViewsNotifier extends AsyncNotifier<List<OdooView>> {
  @override
  Future<List<OdooView>> build() async {
    final repo = ref.read(viewRepositoryProvider);
    return repo.findAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      final repo = ref.read(viewRepositoryProvider);
      return repo.findAll();
    });
  }

  Future<void> save(OdooView view) async {
    final repo = ref.read(viewRepositoryProvider);
    await repo.save(view);
    await refresh();
  }

  Future<void> delete(String id) async {
    final repo = ref.read(viewRepositoryProvider);
    await repo.delete(id);
    await refresh();
  }
}

// ─── Search ──────────────────────────────────────────────────────────────────

final viewSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredViewsProvider = Provider<AsyncValue<List<OdooView>>>((ref) {
  final query = ref.watch(viewSearchQueryProvider);
  final allViewsAsync = ref.watch(savedViewsProvider);

  return allViewsAsync.whenData((views) {
    if (query.trim().isEmpty) return views;
    final q = query.toLowerCase();
    return views
        .where((v) =>
            v.name.toLowerCase().contains(q) ||
            v.model.toLowerCase().contains(q))
        .toList();
  });
});
