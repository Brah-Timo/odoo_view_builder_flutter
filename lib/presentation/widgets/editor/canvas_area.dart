// lib/presentation/widgets/editor/canvas_area.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../data/models/odoo_form.dart';
import '../../../data/models/odoo_field.dart';
import '../../providers/editor_state_provider.dart';
import 'drop_target_zone.dart';
import 'draggable_group_widget.dart';

/// The main canvas where groups and fields are arranged
class CanvasArea extends ConsumerWidget {
  final OdooView view;
  const CanvasArea({super.key, required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppTheme.canvasBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.canvasPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── View header ────────────────────────────────────────────────
            _buildViewHeader(context, view),
            const SizedBox(height: 20),

            // ── Root drop zone ─────────────────────────────────────────────
            if (view.viewType == ViewType.form)
              _buildFormCanvas(ref)
            else if (view.viewType == ViewType.tree)
              _buildTreeCanvas(ref)
            else
              _buildKanbanCanvas(ref),
          ],
        ),
      ),
    );
  }

  // ─── View Header ─────────────────────────────────────────────────────────

  Widget _buildViewHeader(BuildContext context, OdooView view) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.source, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              Text(
                view.model,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          view.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (view.docModule != null)
          Text(
            '📦 ${view.docModule}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
      ],
    );
  }

  // ─── Form Canvas ──────────────────────────────────────────────────────────

  Widget _buildFormCanvas(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top-level fields (outside groups)
        if (view.topLevelFields.isNotEmpty) ...[
          const _SectionLabel(label: 'Root Fields'),
          const SizedBox(height: 8),
          ...view.topLevelFields.asMap().entries.map((e) {
            final field = e.value;
            return Column(
              children: [
                InlineDropZone(
                  onFieldDropped: (dropped) {
                    ref
                        .read(currentViewProvider.notifier)
                        .insertTopLevelField(dropped, e.key);
                  },
                ),
                _CanvasFieldTile(
                  field: field,
                  onTap: () => ref
                      .read(canvasSelectionProvider.notifier)
                      .state = FieldSelection(field),
                  onDelete: () => ref
                      .read(currentViewProvider.notifier)
                      .removeTopLevelField(field.id),
                ),
              ],
            );
          }),
          InlineDropZone(
            onFieldDropped: (f) =>
                ref.read(currentViewProvider.notifier).addTopLevelField(f),
          ),
          const SizedBox(height: 16),
        ],

        // Groups
        if (view.groups.isNotEmpty) ...[
          const _SectionLabel(label: 'Groups'),
          const SizedBox(height: 8),
        ],
        ...view.groups.asMap().entries.map((e) => DraggableGroupWidget(
              group: e.value,
              index: e.key,
            )),

        // Root drop zone (when canvas is empty)
        if (view.topLevelFields.isEmpty && view.groups.isEmpty)
          DropTargetZone(
            isEmpty: true,
            label: 'Drop the first field here',
            onFieldDropped: (f) =>
                ref.read(currentViewProvider.notifier).addTopLevelField(f),
            child: Container(
              width: double.infinity,
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Canvas is empty',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Drag fields from the palette on the left',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          // Final drop zone to append at the end
          DropTargetZone(
            showBorderAlways: false,
            onFieldDropped: (f) =>
                ref.read(currentViewProvider.notifier).addTopLevelField(f),
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              child: const Text(
                '+ Drop field here',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),

        // Notebook pages
        if (view.pages.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel(label: 'Notebook'),
          const SizedBox(height: 8),
          _NotebookPreview(view: view),
        ],
      ],
    );
  }

  // ─── Tree Canvas ──────────────────────────────────────────────────────────

  Widget _buildTreeCanvas(WidgetRef ref) {
    return DropTargetZone(
      isEmpty: view.topLevelFields.isEmpty,
      label: 'Drop columns here',
      onFieldDropped: (f) =>
          ref.read(currentViewProvider.notifier).addTopLevelField(f),
      child: Column(
        children: [
          // Header row preview
          _TreeHeaderRow(fields: view.topLevelFields),
          const Divider(height: 1),
          // Sample data row
          if (view.topLevelFields.isNotEmpty) _TreeSampleRow(fields: view.topLevelFields),
        ],
      ),
    );
  }

  // ─── Kanban Canvas ────────────────────────────────────────────────────────

  Widget _buildKanbanCanvas(WidgetRef ref) {
    return DropTargetZone(
      isEmpty: view.topLevelFields.isEmpty,
      label: 'Drop fields for kanban card',
      onFieldDropped: (f) =>
          ref.read(currentViewProvider.notifier).addTopLevelField(f),
      child: _KanbanPreview(view: view),
    );
  }
}

// ─── Canvas Field Tile ────────────────────────────────────────────────────────

class _CanvasFieldTile extends ConsumerWidget {
  final OdooField field;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CanvasFieldTile({
    required this.field,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selection = ref.watch(canvasSelectionProvider);
    final isSelected =
        selection is FieldSelection && selection.field.id == field.id;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.08)
              : AppTheme.fieldCardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.selectedBorder
                : AppTheme.fieldCardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ListTile(
          dense: true,
          leading: _FieldTypeIcon(type: field.fieldType),
          title: Row(
            children: [
              Text(
                field.label ?? field.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              if (field.required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
            ],
          ),
          subtitle: Text(
            field.name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Attributes badges
              if (field.readonly)
                _Badge(label: 'RO', color: Colors.orange),
              if (field.invisible)
                _Badge(label: 'INV', color: Colors.grey),
              if (field.widget != null)
                _Badge(label: field.widget!, color: AppTheme.accentColor),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.close, size: 14),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove field',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _FieldTypeIcon extends StatelessWidget {
  final OdooFieldType type;
  static const Map<OdooFieldType, Color> _colors = {
    OdooFieldType.char: Color(0xFF2196F3),
    OdooFieldType.text: Color(0xFF03A9F4),
    OdooFieldType.integer: Color(0xFF4CAF50),
    OdooFieldType.float: Color(0xFF8BC34A),
    OdooFieldType.boolean: Color(0xFFFF9800),
    OdooFieldType.date: Color(0xFF9C27B0),
    OdooFieldType.datetime: Color(0xFF673AB7),
    OdooFieldType.selection: Color(0xFFFF5722),
    OdooFieldType.many2one: Color(0xFFF44336),
    OdooFieldType.many2many: Color(0xFFE91E63),
    OdooFieldType.one2many: Color(0xFF795548),
    OdooFieldType.html: Color(0xFF00BCD4),
    OdooFieldType.binary: Color(0xFF607D8B),
    OdooFieldType.reference: Color(0xFF9E9E9E),
  };

  const _FieldTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? Colors.grey;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          type.value.substring(0, 2).toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label.toUpperCase(), style: AppTheme.sectionTitle),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _TreeHeaderRow extends StatelessWidget {
  final List<OdooField> fields;
  const _TreeHeaderRow({required this.fields});

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No columns', style: TextStyle(color: Colors.grey)),
      );
    }
    return Container(
      color: AppTheme.groupBackground,
      child: Row(
        children: fields.map((f) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                f.label ?? f.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TreeSampleRow extends StatelessWidget {
  final List<OdooField> fields;
  const _TreeSampleRow({required this.fields});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: fields.map((f) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _KanbanPreview extends StatelessWidget {
  final OdooView view;
  const _KanbanPreview({required this.view});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(title: 'New', cardCount: 2, view: view),
          const SizedBox(width: 12),
          _KanbanColumn(title: 'In Progress', cardCount: 1, view: view),
          const SizedBox(width: 12),
          _KanbanColumn(title: 'Done', cardCount: 3, view: view),
        ],
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final int cardCount;
  final OdooView view;
  const _KanbanColumn({
    required this.title,
    required this.cardCount,
    required this.view,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.groupBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$cardCount',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(cardCount, (_) => _KanbanCardPreview(view: view)),
          ],
        ),
      ),
    );
  }
}

class _KanbanCardPreview extends StatelessWidget {
  final OdooView view;
  const _KanbanCardPreview({required this.view});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: view.topLevelFields.take(3).map((f) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  height: 8,
                  width: 60 + (f.name.length * 2.0),
                  decoration: BoxDecoration(
                    color: f == view.topLevelFields.first
                        ? Colors.grey[700]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NotebookPreview extends StatelessWidget {
  final OdooView view;
  const _NotebookPreview({required this.view});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: view.pages.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: view.pages.map((p) => Tab(text: p.label)).toList(),
          ),
          Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.fieldCardBorder),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: TabBarView(
              children: view.pages.map((p) {
                return Text(
                  '${p.fields.length} fields, ${p.groups.length} groups',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
