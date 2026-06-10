// lib/utils/helpers/field_helper.dart
//
// Utility helpers for Odoo field types.
//
// Covers:
//   • Default attribute maps per field type
//   • Widget compatibility matrix
//   • Icon / colour look-up for the UI palette
//   • Human-readable labels and descriptions
//   • Aggregation support for tree view columns

import 'package:flutter/material.dart';

import '../../data/models/odoo_field.dart';

// ---------------------------------------------------------------------------
// FieldHelper
// ---------------------------------------------------------------------------

/// Static helpers for working with [OdooFieldType] values.
///
/// All methods are pure functions — no state, no I/O.
abstract class FieldHelper {
  FieldHelper._();

  // ── Default attribute maps ───────────────────────────────────────────────

  /// Returns the default attribute map for [type].
  ///
  /// These defaults match Odoo's own field rendering without any
  /// additional developer overrides.
  static Map<String, dynamic> defaultAttrs(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
        },
      OdooFieldType.integer => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
          'sum': null,
          'avg': null,
        },
      OdooFieldType.float => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
          'sum': null,
          'avg': null,
          'digits': null,
        },
      OdooFieldType.boolean => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
        },
      OdooFieldType.date => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
        },
      OdooFieldType.datetime => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
        },
      OdooFieldType.text => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 2,
        },
      OdooFieldType.html => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 2,
        },
      OdooFieldType.binary => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
        },
      OdooFieldType.selection => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
        },
      OdooFieldType.many2one => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
          'domain': null,
          'context': null,
        },
      OdooFieldType.many2many => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 2,
          'domain': null,
          'context': null,
        },
      OdooFieldType.one2many => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 2,
          'context': null,
        },
      OdooFieldType.reference => {
          'required': false,
          'readonly': false,
          'nolabel': false,
          'invisible': false,
          'colspan': 1,
        },
    };
  }

  // ── Widget compatibility ─────────────────────────────────────────────────

  /// Returns widget names that are compatible with [type].
  ///
  /// Only widgets officially supported by Odoo's web client are listed.
  static List<String> compatibleWidgets(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => [
          'char',
          'email',
          'url',
          'phone',
          'handle',
          'image',
          'color',
          'copy_clipboard',
          'reference',
        ],
      OdooFieldType.integer => [
          'integer',
          'progressbar',
          'handle',
          'priority',
        ],
      OdooFieldType.float => [
          'float',
          'monetary',
          'progressbar',
          'float_time',
          'float_factor',
          'float_toggle',
        ],
      OdooFieldType.boolean => [
          'boolean',
          'toggle_button',
          'boolean_toggle',
          'boolean_favorite',
        ],
      OdooFieldType.date => [
          'date',
          'remaining_days',
          'date_range',
        ],
      OdooFieldType.datetime => [
          'datetime',
          'remaining_days',
          'date_range',
        ],
      OdooFieldType.text => [
          'text',
          'html',
          'char',
          'image',
          'json',
        ],
      OdooFieldType.html => [
          'html',
          'text',
        ],
      OdooFieldType.binary => [
          'binary',
          'image',
          'pdf_viewer',
        ],
      OdooFieldType.selection => [
          'selection',
          'radio',
          'priority',
          'badge',
          'state_selection',
        ],
      OdooFieldType.many2one => [
          'many2one',
          'selection',
          'radio',
          'badge',
          'many2one_avatar',
          'many2one_avatar_user',
          'many2one_tags',
          'statusbar',
        ],
      OdooFieldType.many2many => [
          'many2many',
          'many2many_tags',
          'many2many_checkboxes',
          'many2many_binary',
          'many2many_avatar',
          'many2many_avatar_user',
        ],
      OdooFieldType.one2many => [
          'one2many',
          'many2many',
        ],
      OdooFieldType.reference => [
          'reference',
        ],
    };
  }

  /// Returns the default / recommended widget name for [type].
  static String defaultWidget(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => 'char',
      OdooFieldType.integer => 'integer',
      OdooFieldType.float => 'float',
      OdooFieldType.boolean => 'boolean',
      OdooFieldType.date => 'date',
      OdooFieldType.datetime => 'datetime',
      OdooFieldType.text => 'text',
      OdooFieldType.html => 'html',
      OdooFieldType.binary => 'binary',
      OdooFieldType.selection => 'selection',
      OdooFieldType.many2one => 'many2one',
      OdooFieldType.many2many => 'many2many_tags',
      OdooFieldType.one2many => 'one2many',
      OdooFieldType.reference => 'reference',
    };
  }

  // ── Aggregation support (tree view) ─────────────────────────────────────

  /// Returns `true` if [type] supports column aggregation in tree views
  /// (`sum`, `avg`, `max`, `min`).
  static bool supportsAggregation(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.integer ||
      OdooFieldType.float =>
        true,
      _ => false,
    };
  }

  /// Aggregation functions available for numeric fields in tree views.
  static const List<String> aggregationFunctions = [
    'sum',
    'avg',
    'max',
    'min',
  ];

  // ── Relation helpers ─────────────────────────────────────────────────────

  /// Returns `true` if [type] links to another model (requires `comodel`).
  static bool isRelational(OdooFieldType type) {
    return type == OdooFieldType.many2one ||
        type == OdooFieldType.many2many ||
        type == OdooFieldType.one2many;
  }

  /// Returns `true` if [type] results in a list/table sub-widget.
  static bool isListLike(OdooFieldType type) {
    return type == OdooFieldType.one2many || type == OdooFieldType.many2many;
  }

  /// Returns `true` if the field renders as a simple scalar.
  static bool isScalar(OdooFieldType type) {
    return !isRelational(type) &&
        type != OdooFieldType.html &&
        type != OdooFieldType.binary;
  }

  // ── Suggested name prefixes ──────────────────────────────────────────────

  /// Returns a suggested field name prefix for auto-completion hints.
  static String suggestedPrefix(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => 'x_char_',
      OdooFieldType.integer => 'x_int_',
      OdooFieldType.float => 'x_float_',
      OdooFieldType.boolean => 'x_is_',
      OdooFieldType.date => 'x_date_',
      OdooFieldType.datetime => 'x_datetime_',
      OdooFieldType.text => 'x_text_',
      OdooFieldType.html => 'x_html_',
      OdooFieldType.binary => 'x_file_',
      OdooFieldType.selection => 'x_state_',
      OdooFieldType.many2one => 'x_',
      OdooFieldType.many2many => 'x_',
      OdooFieldType.one2many => 'x_line_',
      OdooFieldType.reference => 'x_ref_',
    };
  }

  // ── UI helpers ───────────────────────────────────────────────────────────

  /// Returns the Material icon for [type] used in the palette and property
  /// panels.
  static IconData iconFor(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => Icons.text_fields,
      OdooFieldType.integer => Icons.pin,
      OdooFieldType.float => Icons.calculate_outlined,
      OdooFieldType.boolean => Icons.toggle_on_outlined,
      OdooFieldType.date => Icons.calendar_today_outlined,
      OdooFieldType.datetime => Icons.access_time,
      OdooFieldType.text => Icons.notes,
      OdooFieldType.html => Icons.code,
      OdooFieldType.binary => Icons.attach_file,
      OdooFieldType.selection => Icons.arrow_drop_down_circle_outlined,
      OdooFieldType.many2one => Icons.link,
      OdooFieldType.many2many => Icons.account_tree_outlined,
      OdooFieldType.one2many => Icons.list_alt_outlined,
      OdooFieldType.reference => Icons.open_in_new,
    };
  }

  /// Returns a display colour for [type] used in the palette chips.
  static Color colorFor(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char => const Color(0xFF4CAF50),
      OdooFieldType.integer => const Color(0xFF2196F3),
      OdooFieldType.float => const Color(0xFF03A9F4),
      OdooFieldType.boolean => const Color(0xFF9C27B0),
      OdooFieldType.date => const Color(0xFFFF9800),
      OdooFieldType.datetime => const Color(0xFFFF5722),
      OdooFieldType.text => const Color(0xFF607D8B),
      OdooFieldType.html => const Color(0xFF795548),
      OdooFieldType.binary => const Color(0xFF9E9E9E),
      OdooFieldType.selection => const Color(0xFF673AB7),
      OdooFieldType.many2one => const Color(0xFFF44336),
      OdooFieldType.many2many => const Color(0xFFE91E63),
      OdooFieldType.one2many => const Color(0xFF009688),
      OdooFieldType.reference => const Color(0xFF3F51B5),
    };
  }

  /// Returns a short human-readable description of [type].
  static String descriptionFor(OdooFieldType type) {
    return switch (type) {
      OdooFieldType.char =>
        'Single-line text — names, codes, short strings.',
      OdooFieldType.integer => 'Whole number — quantities, counts.',
      OdooFieldType.float =>
        'Decimal number — prices, weights, ratios.',
      OdooFieldType.boolean => 'True / False toggle — active, is_done, etc.',
      OdooFieldType.date => 'Calendar date without time.',
      OdooFieldType.datetime => 'Date and time (UTC stored).',
      OdooFieldType.text => 'Multi-line plain text.',
      OdooFieldType.html => 'Rich-text HTML editor.',
      OdooFieldType.binary => 'File or image attachment.',
      OdooFieldType.selection =>
        'Drop-down from a fixed list of choices.',
      OdooFieldType.many2one =>
        'Link to a single record in another model.',
      OdooFieldType.many2many =>
        'Tags — links to multiple records in another model.',
      OdooFieldType.one2many =>
        'Embedded table — child records belonging to this record.',
      OdooFieldType.reference =>
        'Dynamic link to any model record.',
    };
  }

  // ── Type conversion utilities ────────────────────────────────────────────

  /// Normalises a raw string coming from the Odoo server into the closest
  /// [OdooFieldType]. Handles compound types like `char(64)`.
  static OdooFieldType normalise(String rawType) {
    final base = rawType.split('(').first.trim().toLowerCase();
    return OdooFieldType.fromString(base);
  }

  /// Returns all field types that can be safely used in a Kanban card
  /// without special template wiring.
  static List<OdooFieldType> kanbanCompatibleTypes() {
    return [
      OdooFieldType.char,
      OdooFieldType.integer,
      OdooFieldType.float,
      OdooFieldType.boolean,
      OdooFieldType.date,
      OdooFieldType.datetime,
      OdooFieldType.selection,
      OdooFieldType.many2one,
    ];
  }

  /// Returns all field types usable as column headers in a Tree view.
  static List<OdooFieldType> treeCompatibleTypes() {
    return OdooFieldType.values
        .where((t) => t != OdooFieldType.html && t != OdooFieldType.one2many)
        .toList();
  }
}
