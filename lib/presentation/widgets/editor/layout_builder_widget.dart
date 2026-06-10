// lib/presentation/widgets/editor/layout_builder_widget.dart

import 'package:flutter/material.dart';
import '../../../data/models/odoo_form.dart';
import '../../../data/models/odoo_group.dart';
import '../../../data/models/odoo_field.dart';
import '../../../config/theme.dart';

/// Renders a visual form layout preview from groups/fields
class FormLayoutBuilder extends StatelessWidget {
  final OdooView view;
  const FormLayoutBuilder({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top-level fields in a simple layout
        if (view.topLevelFields.isNotEmpty)
          _buildFieldsRow(view.topLevelFields),
        // Groups
        ...view.groups.map((g) => _buildGroupLayout(g)),
      ],
    );
  }

  Widget _buildFieldsRow(List<OdooField> fields) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: fields.map((f) => _FieldBox(field: f)).toList(),
    );
  }

  Widget _buildGroupLayout(OdooGroup group) {
    final columns = group.col ?? 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.groupBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.groupBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (group.label != null)
            Text(
              group.label!,
              style: AppTheme.sectionTitle,
            ),
          const SizedBox(height: 8),
          // Responsive grid
          LayoutBuilder(
            builder: (_, constraints) {
              final itemWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.fields.map((f) {
                  final span = f.colspan ?? 1;
                  return SizedBox(
                    width: (itemWidth * span + (span - 1) * 8)
                        .clamp(0, constraints.maxWidth),
                    child: _FieldBox(field: f),
                  );
                }).toList(),
              );
            },
          ),
          // Sub-groups
          ...group.subGroups.map(_buildGroupLayout),
        ],
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final OdooField field;
  const _FieldBox({required this.field});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!field.nolabel)
          Text(
            '${field.label ?? field.name}${field.required ? ' *' : ''}',
            style: AppTheme.fieldLabel,
          ),
        const SizedBox(height: 4),
        _FieldInput(field: field),
      ],
    );
  }
}

class _FieldInput extends StatelessWidget {
  final OdooField field;
  const _FieldInput({required this.field});

  @override
  Widget build(BuildContext context) {
    Widget input = switch (field.fieldType) {
      OdooFieldType.boolean => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(value: false, onChanged: null),
            const SizedBox(width: 4),
            Text(field.label ?? field.name, style: const TextStyle(fontSize: 12)),
          ],
        ),
      OdooFieldType.text => Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.fieldCardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      OdooFieldType.html => Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.fieldCardBorder),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(8),
          child: const Text('HTML Editor', style: TextStyle(color: Colors.grey, fontSize: 11)),
        ),
      OdooFieldType.binary => Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.fieldCardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              SizedBox(width: 8),
              Icon(Icons.attach_file, size: 14, color: Colors.grey),
              SizedBox(width: 4),
              Text('Upload file', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ),
      OdooFieldType.many2many ||
      OdooFieldType.many2one =>
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.fieldCardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select ${field.fieldType.value}...',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
            ],
          ),
        ),
      _ => Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.fieldCardBorder),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
    };

    if (field.readonly) {
      input = Opacity(opacity: 0.6, child: input);
    }
    if (field.invisible) {
      input = Opacity(opacity: 0.2, child: input);
    }

    return input;
  }
}
