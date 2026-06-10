// lib/presentation/providers/editor_state_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/odoo_form.dart';
import '../../data/models/odoo_field.dart';
import '../../data/models/odoo_group.dart';
import '../../config/app_config.dart';

// ─── Selected Item ────────────────────────────────────────────────────────────

/// What is currently selected on the canvas
abstract class CanvasSelection {}

class FieldSelection extends CanvasSelection {
  final OdooField field;
  FieldSelection(this.field);
}

class GroupSelection extends CanvasSelection {
  final OdooGroup group;
  GroupSelection(this.group);
}

class NoSelection extends CanvasSelection {}

final canvasSelectionProvider =
    StateProvider<CanvasSelection>((ref) => NoSelection());

// ─── Panel Visibility ────────────────────────────────────────────────────────

final showXmlPreviewProvider = StateProvider<bool>(
  (ref) => AppConfig.showXmlPreviewByDefault,
);

final showPropertiesPanelProvider = StateProvider<bool>((ref) => true);
final showPalettePanelProvider = StateProvider<bool>((ref) => true);

// ─── Drag State ───────────────────────────────────────────────────────────────

final isDraggingProvider = StateProvider<bool>((ref) => false);

// ─── Current View / Editor State ─────────────────────────────────────────────

final currentViewProvider =
    StateNotifierProvider<CurrentViewNotifier, OdooView?>(
  (ref) => CurrentViewNotifier(),
);

class CurrentViewNotifier extends StateNotifier<OdooView?> {
  CurrentViewNotifier() : super(null);

  // ── History for undo / redo ───────────────────────────────────────────────
  final List<OdooView> _history = [];
  int _historyIndex = -1;

  void _pushHistory(OdooView view) {
    // Remove any forward history
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(view);
    if (_history.length > AppConfig.maxUndoHistory) {
      _history.removeAt(0);
    }
    _historyIndex = _history.length - 1;
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    state = _history[_historyIndex];
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    state = _history[_historyIndex];
  }

  // ── View Lifecycle ────────────────────────────────────────────────────────

  void loadView(OdooView view) {
    state = view;
    _history.clear();
    _historyIndex = -1;
    _pushHistory(view);
  }

  void clearView() {
    state = null;
    _history.clear();
    _historyIndex = -1;
  }

  void _update(OdooView Function(OdooView current) updater) {
    if (state == null) return;
    final updated = updater(state!);
    state = updated;
    _pushHistory(updated);
  }

  // ── View Metadata ─────────────────────────────────────────────────────────

  void updateMeta({
    String? id,
    String? name,
    String? model,
    ViewType? viewType,
    String? docModule,
    int? priority,
    String? inheritId,
    String? defaultOrder,
  }) {
    _update((v) => v.copyWith(
          id: id,
          name: name,
          model: model,
          viewType: viewType,
          docModule: docModule,
          priority: priority,
          inheritId: inheritId,
          defaultOrder: defaultOrder,
        ));
  }

  // ── Field Operations ──────────────────────────────────────────────────────

  /// Add a field to top-level fields
  void addTopLevelField(OdooField field) {
    _update((v) => v.copyWith(
          topLevelFields: [...v.topLevelFields, field],
        ));
  }

  /// Insert a field at a specific index in top-level fields
  void insertTopLevelField(OdooField field, int index) {
    _update((v) {
      final list = [...v.topLevelFields];
      list.insert(index.clamp(0, list.length), field);
      return v.copyWith(topLevelFields: list);
    });
  }

  /// Reorder top-level fields
  void reorderTopLevelField(int oldIndex, int newIndex) {
    _update((v) {
      final list = [...v.topLevelFields];
      final item = list.removeAt(oldIndex);
      list.insert(newIndex.clamp(0, list.length), item);
      return v.copyWith(topLevelFields: list);
    });
  }

  /// Update a top-level field
  void updateTopLevelField(OdooField updated) {
    _update((v) => v.copyWith(
          topLevelFields: v.topLevelFields
              .map((f) => f.id == updated.id ? updated : f)
              .toList(),
        ));
  }

  /// Remove a top-level field by id
  void removeTopLevelField(String fieldId) {
    _update((v) => v.copyWith(
          topLevelFields:
              v.topLevelFields.where((f) => f.id != fieldId).toList(),
        ));
  }

  // ── Group Operations ──────────────────────────────────────────────────────

  void addGroup(OdooGroup group) {
    _update((v) => v.copyWith(groups: [...v.groups, group]));
  }

  void insertGroup(OdooGroup group, int index) {
    _update((v) {
      final list = [...v.groups];
      list.insert(index.clamp(0, list.length), group);
      return v.copyWith(groups: list);
    });
  }

  void reorderGroup(int oldIndex, int newIndex) {
    _update((v) {
      final list = [...v.groups];
      final item = list.removeAt(oldIndex);
      list.insert(newIndex.clamp(0, list.length), item);
      return v.copyWith(groups: list);
    });
  }

  void updateGroup(OdooGroup updated) {
    _update((v) => v.copyWith(
          groups: v.groups
              .map((g) => g.id == updated.id ? updated : g)
              .toList(),
        ));
  }

  void removeGroup(String groupId) {
    _update((v) => v.copyWith(
          groups: v.groups.where((g) => g.id != groupId).toList(),
        ));
  }

  void duplicateGroup(String groupId) {
    _update((v) {
      final idx = v.groups.indexWhere((g) => g.id == groupId);
      if (idx < 0) return v;
      final list = [...v.groups];
      list.insert(idx + 1, list[idx].duplicate());
      return v.copyWith(groups: list);
    });
  }

  // ── Field inside Group ────────────────────────────────────────────────────

  void addFieldToGroup(String groupId, OdooField field) {
    _update((v) => v.copyWith(
          groups: v.groups
              .map((g) => g.id == groupId
                  ? g.copyWith(fields: [...g.fields, field])
                  : g)
              .toList(),
        ));
  }

  void updateFieldInGroup(String groupId, OdooField updated) {
    _update((v) => v.copyWith(
          groups: v.groups.map((g) {
            if (g.id != groupId) return g;
            return g.copyWith(
              fields: g.fields
                  .map((f) => f.id == updated.id ? updated : f)
                  .toList(),
            );
          }).toList(),
        ));
  }

  void removeFieldFromGroup(String groupId, String fieldId) {
    _update((v) => v.copyWith(
          groups: v.groups.map((g) {
            if (g.id != groupId) return g;
            return g.copyWith(
              fields: g.fields.where((f) => f.id != fieldId).toList(),
            );
          }).toList(),
        ));
  }

  void reorderFieldInGroup(String groupId, int oldIndex, int newIndex) {
    _update((v) => v.copyWith(
          groups: v.groups.map((g) {
            if (g.id != groupId) return g;
            final list = [...g.fields];
            final item = list.removeAt(oldIndex);
            list.insert(newIndex.clamp(0, list.length), item);
            return g.copyWith(fields: list);
          }).toList(),
        ));
  }

  // ── Notebook Pages ────────────────────────────────────────────────────────

  void addPage(NotebookPage page) {
    _update((v) => v.copyWith(pages: [...v.pages, page]));
  }

  void removePage(String pageId) {
    _update((v) => v.copyWith(
          pages: v.pages.where((p) => p.id != pageId).toList(),
        ));
  }
}

// ─── Derived / Computed Providers ────────────────────────────────────────────

/// Live-generated XML from the current view
final generatedXmlProvider = Provider<String?>((ref) {
  final view = ref.watch(currentViewProvider);
  if (view == null) return null;
  return view.generateXml();
});

/// Whether the current view has unsaved changes
final hasUnsavedChangesProvider = StateProvider<bool>((ref) => false);
