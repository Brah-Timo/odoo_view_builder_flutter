// lib/data/repositories/field_repository.dart

import '../models/odoo_field.dart';
import '../../config/constants.dart';

/// Provides available field definitions (built-in palette)
class FieldRepository {
  const FieldRepository();

  /// All palette field types available for dragging onto the canvas
  List<PaletteField> getPaletteFields() {
    return [
      // ── Basic Types ──────────────────────────────────────────────────────
      PaletteField(
        type: OdooFieldType.char,
        defaultLabel: 'Text Field',
        icon: '🔤',
        description: 'Single-line text (char)',
        category: 'Basic',
      ),
      PaletteField(
        type: OdooFieldType.text,
        defaultLabel: 'Long Text',
        icon: '📄',
        description: 'Multi-line text area',
        category: 'Basic',
      ),
      PaletteField(
        type: OdooFieldType.integer,
        defaultLabel: 'Integer',
        icon: '🔢',
        description: 'Whole number',
        category: 'Basic',
      ),
      PaletteField(
        type: OdooFieldType.float,
        defaultLabel: 'Float / Money',
        icon: '💰',
        description: 'Decimal number or monetary amount',
        category: 'Basic',
      ),
      PaletteField(
        type: OdooFieldType.boolean,
        defaultLabel: 'Checkbox',
        icon: '✅',
        description: 'True / False toggle',
        category: 'Basic',
      ),
      PaletteField(
        type: OdooFieldType.html,
        defaultLabel: 'HTML Content',
        icon: '🌐',
        description: 'Rich HTML editor',
        category: 'Basic',
      ),

      // ── Date / Time ──────────────────────────────────────────────────────
      PaletteField(
        type: OdooFieldType.date,
        defaultLabel: 'Date',
        icon: '📅',
        description: 'Date picker',
        category: 'Date & Time',
      ),
      PaletteField(
        type: OdooFieldType.datetime,
        defaultLabel: 'Date & Time',
        icon: '🕐',
        description: 'Date + time picker',
        category: 'Date & Time',
      ),

      // ── Relational ───────────────────────────────────────────────────────
      PaletteField(
        type: OdooFieldType.many2one,
        defaultLabel: 'Many2One',
        icon: '🔗',
        description: 'Link to one record in another model',
        category: 'Relational',
      ),
      PaletteField(
        type: OdooFieldType.many2many,
        defaultLabel: 'Many2Many',
        icon: '🔀',
        description: 'Link to multiple records (tags)',
        category: 'Relational',
      ),
      PaletteField(
        type: OdooFieldType.one2many,
        defaultLabel: 'One2Many Lines',
        icon: '📋',
        description: 'Embedded sub-list (lines)',
        category: 'Relational',
      ),

      // ── Selection ────────────────────────────────────────────────────────
      PaletteField(
        type: OdooFieldType.selection,
        defaultLabel: 'Selection',
        icon: '📌',
        description: 'Dropdown list of fixed options',
        category: 'Selection',
      ),

      // ── Binary ───────────────────────────────────────────────────────────
      PaletteField(
        type: OdooFieldType.binary,
        defaultLabel: 'File / Image',
        icon: '📎',
        description: 'File attachment or image',
        category: 'Binary',
      ),
    ];
  }

  /// Field types grouped by category
  Map<String, List<PaletteField>> getPaletteByCategory() {
    final palette = getPaletteFields();
    final result = <String, List<PaletteField>>{};
    for (final f in palette) {
      result.putIfAbsent(f.category, () => []).add(f);
    }
    return result;
  }

  /// Common widget options for a given field type
  List<WidgetOption> getWidgetOptions(OdooFieldType type) {
    final widgets = AppConstants.fieldWidgets[type.value] ?? [];
    return widgets.map((w) => WidgetOption(name: w)).toList();
  }
}

// ─── Supporting DTOs ─────────────────────────────────────────────────────────

class PaletteField {
  final OdooFieldType type;
  final String defaultLabel;
  final String icon;
  final String description;
  final String category;

  const PaletteField({
    required this.type,
    required this.defaultLabel,
    required this.icon,
    required this.description,
    required this.category,
  });
}

class WidgetOption {
  final String name;
  final String? description;

  const WidgetOption({required this.name, this.description});
}
