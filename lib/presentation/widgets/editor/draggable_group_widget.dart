// lib/presentation/widgets/editor/draggable_group_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_field.dart';
import '../../../data/models/odoo_group.dart';
import '../../providers/editor_state_provider.dart';
import 'drop_target_zone.dart';

/// A group displayed on the canvas — draggable for reordering + droppable
class DraggableGroupWidget extends ConsumerStatefulWidget {
  final OdooGroup group;
  final int index;

  const DraggableGroupWidget({
    super.key,
    required this.group,
    required this.index,
  });

  @override
  ConsumerState<DraggableGroupWidget> createState() =>
      _DraggableGroupWidgetState();
}

class _DraggableGroupWidgetState
    extends ConsumerState<DraggableGroupWidget> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(canvasSelectionProvider);
    final isSelected =
        selection is GroupSelection &&
        selection.group.id == widget.group.id;

    return GestureDetector(
      onTap: () => ref.read(canvasSelectionProvider.notifier).state =
          GroupSelection(widget.group),
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.groupBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.selectedBorder
                : AppTheme.groupBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGroupHeader(isSelected),
            if (!_collapsed)
              _buildGroupContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader(bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.groupBorder.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(9),
          topRight: Radius.circular(9),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          const Icon(Icons.group_work_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            widget.group.label ?? 'Group',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (widget.group.colspan != null) ...[
            const SizedBox(width: 8),
            _GroupBadge(label: 'colspan=${widget.group.colspan}'),
          ],
          if (widget.group.col != null) ...[
            const SizedBox(width: 4),
            _GroupBadge(label: 'col=${widget.group.col}'),
          ],
          const Spacer(),
          // field count
          Text(
            '${widget.group.fields.length} field(s)',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(width: 8),
          // Collapse / expand
          IconButton(
            icon: Icon(
              _collapsed ? Icons.unfold_more : Icons.unfold_less,
              size: 16,
            ),
            onPressed: () => setState(() => _collapsed = !_collapsed),
            tooltip: _collapsed ? 'Expand' : 'Collapse',
            visualDensity: VisualDensity.compact,
          ),
          // Duplicate
          IconButton(
            icon: const Icon(Icons.copy, size: 14),
            onPressed: () => ref
                .read(currentViewProvider.notifier)
                .duplicateGroup(widget.group.id),
            tooltip: 'Duplicate group',
            visualDensity: VisualDensity.compact,
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            onPressed: () => _confirmDelete(),
            tooltip: 'Delete group',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent() {
    final group = widget.group;

    return DropTargetZone(
      isEmpty: group.fields.isEmpty && group.subGroups.isEmpty,
      label: 'Drop fields into this group',
      onFieldDropped: (field) {
        ref
            .read(currentViewProvider.notifier)
            .addFieldToGroup(group.id, field);
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: group.fields.isEmpty && group.subGroups.isEmpty
            ? const _EmptyGroupPlaceholder()
            : _GroupFieldsGrid(group: group),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Delete "${widget.group.label ?? 'this group'}" and all its fields?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ref
          .read(currentViewProvider.notifier)
          .removeGroup(widget.group.id);
    }
  }
}

// ─── Group Fields Grid ────────────────────────────────────────────────────────

class _GroupFieldsGrid extends ConsumerWidget {
  final OdooGroup group;
  const _GroupFieldsGrid({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: group.fields.map((field) {
        return _GroupFieldChip(
          field: field,
          groupId: group.id,
        );
      }).toList(),
    );
  }
}

class _GroupFieldChip extends ConsumerWidget {
  final OdooField field;
  final String groupId;
  const _GroupFieldChip({required this.field, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(canvasSelectionProvider);
    final isSelected =
        selection is FieldSelection && selection.field.id == field.id;

    return GestureDetector(
      onTap: () => ref.read(canvasSelectionProvider.notifier).state =
          FieldSelection(field),
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.selectedBorder
                : AppTheme.fieldCardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              field.label ?? field.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            if (field.required) ...[
              const SizedBox(width: 2),
              const Text('*',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(width: 6),
            InkWell(
              onTap: () => ref
                  .read(currentViewProvider.notifier)
                  .removeFieldFromGroup(groupId, field.id),
              child: const Icon(Icons.close, size: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGroupPlaceholder extends StatelessWidget {
  const _EmptyGroupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_box_outlined, color: Colors.grey, size: 24),
          SizedBox(height: 8),
          Text(
            'Drop fields here',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _GroupBadge extends StatelessWidget {
  final String label;
  const _GroupBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 9,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
