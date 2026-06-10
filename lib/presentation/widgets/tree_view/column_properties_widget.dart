// lib/presentation/widgets/tree_view/column_properties_widget.dart

import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_tree_view.dart';

class ColumnPropertiesWidget extends StatelessWidget {
  final TreeColumn column;
  final ValueChanged<TreeColumn> onUpdated;

  const ColumnPropertiesWidget({
    super.key,
    required this.column,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Aggregate
          _PropertyChooser<ColumnAggregate>(
            label: 'Aggregate',
            value: column.aggregate,
            options: ColumnAggregate.values,
            labelFor: (v) => v.name,
            onChanged: (v) => onUpdated(column.copyWith(aggregate: v)),
          ),
          // Optional
          _PropertyChooser<ColumnOptional>(
            label: 'Optional',
            value: column.optional,
            options: ColumnOptional.values,
            labelFor: (v) => v.name,
            onChanged: (v) => onUpdated(column.copyWith(optional: v)),
          ),
          // Readonly
          SizedBox(
            width: 140,
            child: CheckboxListTile(
              title: const Text('Readonly', style: TextStyle(fontSize: 12)),
              value: column.editable,
              onChanged: (v) =>
                  onUpdated(column.copyWith(editable: v ?? false)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyChooser<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  const _PropertyChooser({
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.fieldLabel),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            value: value,
            items: options
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(labelFor(opt),
                          style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: const InputDecoration(),
          ),
        ],
      ),
    );
  }
}
