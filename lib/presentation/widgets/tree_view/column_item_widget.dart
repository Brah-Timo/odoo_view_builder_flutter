// lib/presentation/widgets/tree_view/column_item_widget.dart

import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_tree_view.dart';
import 'column_properties_widget.dart';

class ColumnItemWidget extends StatefulWidget {
  final TreeColumn column;
  final int index;
  final ValueChanged<TreeColumn> onUpdated;
  final VoidCallback onDeleted;

  const ColumnItemWidget({
    super.key,
    required this.column,
    required this.index,
    required this.onUpdated,
    required this.onDeleted,
  });

  @override
  State<ColumnItemWidget> createState() => _ColumnItemWidgetState();
}

class _ColumnItemWidgetState extends State<ColumnItemWidget> {
  bool _showProperties = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.index + 1}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              widget.column.field.label ?? widget.column.field.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              widget.column.field.fieldType.value,
              style: AppTheme.fieldTypeBadge,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.column.aggregate != ColumnAggregate.none)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.column.aggregate.name,
                      style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (widget.column.optional != ColumnOptional.none) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.visibility_off_outlined,
                      size: 14, color: Colors.grey),
                ],
                IconButton(
                  icon: Icon(
                    _showProperties
                        ? Icons.keyboard_arrow_up
                        : Icons.settings_outlined,
                    size: 16,
                  ),
                  onPressed: () =>
                      setState(() => _showProperties = !_showProperties),
                  tooltip: 'Column properties',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  onPressed: widget.onDeleted,
                  tooltip: 'Remove column',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (_showProperties) ...[
            const Divider(height: 1),
            ColumnPropertiesWidget(
              column: widget.column,
              onUpdated: widget.onUpdated,
            ),
          ],
        ],
      ),
    );
  }
}
