// lib/presentation/screens/kanban_editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/odoo_form.dart';
import '../../data/models/odoo_field.dart';
import '../providers/editor_state_provider.dart';
import '../widgets/kanban/kanban_card_builder.dart';

class KanbanEditorScreen extends ConsumerWidget {
  const KanbanEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(currentViewProvider);
    if (view == null) return const SizedBox.shrink();

    return Column(
      children: [
        _buildOptionsBar(view, ref),
        Expanded(
          child: Row(
            children: [
              // Card preview
              Expanded(
                flex: 2,
                child: _buildCardPreview(view),
              ),
              // Fields panel
              SizedBox(
                width: 280,
                child: _buildFieldsPanel(view, ref),
              ),
            ],
          ),
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
          const Icon(Icons.view_kanban_outlined, size: 16),
          const SizedBox(width: 8),
          Text('${view.topLevelFields.length} fields', style: AppTheme.sectionTitle),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Field', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview(OdooView view) {
    return Container(
      color: const Color(0xFFEEEEEE),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: KanbanCardBuilder(view: view),
      ),
    );
  }

  Widget _buildFieldsPanel(OdooView view, WidgetRef ref) {
    return Container(
      color: AppTheme.propertiesBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Card Fields', style: AppTheme.sectionTitle),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: view.topLevelFields.length,
              onReorder: (old, newIdx) {
                ref
                    .read(currentViewProvider.notifier)
                    .reorderTopLevelField(old, newIdx);
              },
              itemBuilder: (_, index) {
                final field = view.topLevelFields[index];
                return _KanbanFieldItem(
                  key: ValueKey(field.id),
                  field: field,
                  onDelete: () => ref
                      .read(currentViewProvider.notifier)
                      .removeTopLevelField(field.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KanbanFieldItem extends StatelessWidget {
  final OdooField field;
  final VoidCallback onDelete;
  const _KanbanFieldItem({
    super.key,
    required this.field,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.drag_indicator, size: 18),
        title: Text(field.name, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          field.fieldType.value,
          style: AppTheme.fieldTypeBadge.copyWith(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: onDelete,
        ),
        dense: true,
      ),
    );
  }
}
