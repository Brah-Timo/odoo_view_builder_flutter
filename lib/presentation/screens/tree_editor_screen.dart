// lib/presentation/screens/tree_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/odoo_form.dart';
import '../../data/models/odoo_tree_view.dart';
import '../providers/editor_state_provider.dart';
import '../widgets/tree_view/column_item_widget.dart';

class TreeEditorScreen extends ConsumerWidget {
  const TreeEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(currentViewProvider);
    if (view == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Tree-specific options bar
        _buildOptionsBar(view, ref),
        // Columns list
        Expanded(
          child: view.topLevelFields.isEmpty
              ? _buildEmptyState()
              : _buildColumnsList(view, ref),
        ),
      ],
    );
  }

  Widget _buildOptionsBar(OdooView view, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.groupBackground,
      child: Row(
        children: [
          const Icon(Icons.list_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '${view.topLevelFields.length} columns',
            style: AppTheme.sectionTitle,
          ),
          const Spacer(),
          SwitchListTile(
            title: const Text('Editable', style: TextStyle(fontSize: 12)),
            value: view.editable,
            onChanged: (v) {
              ref.read(currentViewProvider.notifier).updateMeta();
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildColumnsList(OdooView view, WidgetRef ref) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: view.topLevelFields.length,
      onReorder: (old, newIdx) {
        ref
            .read(currentViewProvider.notifier)
            .reorderTopLevelField(old, newIdx);
      },
      itemBuilder: (_, index) {
        final field = view.topLevelFields[index];
        final col = TreeColumn.fromField(field);
        return ColumnItemWidget(
          key: ValueKey(field.id),
          column: col,
          index: index,
          onUpdated: (updated) {
            ref
                .read(currentViewProvider.notifier)
                .updateTopLevelField(updated.field);
          },
          onDeleted: () {
            ref
                .read(currentViewProvider.notifier)
                .removeTopLevelField(field.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.list_alt, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No columns yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Drag fields from the palette to add columns',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
