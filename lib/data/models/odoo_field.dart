// lib/data/models/odoo_field.dart

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Supported Odoo field types
enum OdooFieldType {
  char('char', 'Text'),
  integer('integer', 'Integer'),
  float('float', 'Float'),
  boolean('boolean', 'Boolean'),
  date('date', 'Date'),
  datetime('datetime', 'Date & Time'),
  text('text', 'Long Text'),
  html('html', 'HTML'),
  binary('binary', 'File/Image'),
  selection('selection', 'Selection'),
  many2one('many2one', 'Many2One'),
  many2many('many2many', 'Many2Many'),
  one2many('one2many', 'One2Many'),
  reference('reference', 'Reference');

  const OdooFieldType(this.value, this.label);
  final String value;
  final String label;

  static OdooFieldType fromString(String value) {
    return OdooFieldType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OdooFieldType.char,
    );
  }
}

/// Decoration types for tree view columns
enum FieldDecoration {
  none,
  bold,
  italic,
  danger,
  info,
  muted,
  success,
  warning,
}

/// Represents a single Odoo field in a view
class OdooField extends Equatable {
  final String id;
  final String name;
  final OdooFieldType fieldType;
  final String? label;
  final bool required;
  final bool readonly;
  final bool nolabel;
  final bool invisible;
  final String? defaultValue;
  final String? placeholder;
  final String? widget;
  final int? colspan;
  final String? domain;
  final String? context;
  final String? attrs;
  final String? groups;
  final String? onchange;
  final String? help;
  final String? comodel;       // for Many2one / Many2many / One2many
  final String? relationField; // inverse_name for One2many
  final List<SelectionOption> selectionOptions; // for selection fields
  final FieldDecoration decoration;
  final String? sum;  // tree view aggregation
  final bool optional;
  final Map<String, dynamic> extraAttrs;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OdooField({
    required this.id,
    required this.name,
    required this.fieldType,
    this.label,
    this.required = false,
    this.readonly = false,
    this.nolabel = false,
    this.invisible = false,
    this.defaultValue,
    this.placeholder,
    this.widget,
    this.colspan,
    this.domain,
    this.context,
    this.attrs,
    this.groups,
    this.onchange,
    this.help,
    this.comodel,
    this.relationField,
    this.selectionOptions = const [],
    this.decoration = FieldDecoration.none,
    this.sum,
    this.optional = false,
    this.extraAttrs = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory — creates a new field with a generated ID.
  ///
  /// All parameters beyond [name], [fieldType], [label] are convenience
  /// shortcuts — they delegate to [copyWith] internally so the full set of
  /// attributes is always available.
  factory OdooField.create({
    required String name,
    required OdooFieldType fieldType,
    String? label,
    // Convenience shortcuts (avoid having to chain .copyWith())
    bool? required,
    bool? readonly,
    bool? nolabel,
    bool? invisible,
    String? widget,
    int? colspan,
    String? domain,
    String? context,
    String? attrs,
    String? groups,
    String? onchange,
    String? help,
    String? comodel,
    String? relationField,
    String? placeholder,
    String? sum,
    bool? optional,
    Map<String, dynamic>? extraAttrs,
  }) {
    final now = DateTime.now();
    return OdooField(
      id: const Uuid().v4(),
      name: name,
      fieldType: fieldType,
      label: label,
      required: required ?? false,
      readonly: readonly ?? false,
      nolabel: nolabel ?? false,
      invisible: invisible ?? false,
      widget: widget,
      colspan: colspan,
      domain: domain,
      context: context,
      attrs: attrs,
      groups: groups,
      onchange: onchange,
      help: help,
      comodel: comodel,
      relationField: relationField,
      placeholder: placeholder,
      sum: sum,
      optional: optional ?? false,
      extraAttrs: extraAttrs ?? const {},
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Factory — creates a blank placeholder field dropped on canvas
  factory OdooField.blank(OdooFieldType type) {
    return OdooField.create(
      name: type.value,
      fieldType: type,
      label: type.label,
    );
  }

  // ─── XML Generation ──────────────────────────────────────────────────────────

  /// Renders the field as a single-line XML tag
  String toXml({int indent = 0}) {
    final pad = ' ' * indent;
    final buf = StringBuffer('$pad<field name="$name"');

    if (label != null && label!.isNotEmpty) buf.write(' string="$label"');
    if (required) buf.write(' required="1"');
    if (readonly) buf.write(' readonly="1"');
    if (nolabel) buf.write(' nolabel="1"');
    if (invisible) buf.write(' invisible="1"');
    if (widget != null && widget!.isNotEmpty) buf.write(' widget="$widget"');
    if (colspan != null && colspan! > 1) buf.write(' colspan="$colspan"');
    if (domain != null && domain!.isNotEmpty) buf.write(' domain="$domain"');
    if (context != null && context!.isNotEmpty) buf.write(' context="$context"');
    if (attrs != null && attrs!.isNotEmpty) buf.write(' attrs="$attrs"');
    if (groups != null && groups!.isNotEmpty) buf.write(' groups="$groups"');
    if (onchange != null && onchange!.isNotEmpty) buf.write(' onchange="$onchange"');
    if (placeholder != null && placeholder!.isNotEmpty) buf.write(' placeholder="$placeholder"');
    if (sum != null && sum!.isNotEmpty) buf.write(' sum="$sum"');
    if (optional) buf.write(' optional="show"');

    // decoration for tree views
    if (decoration != FieldDecoration.none) {
      buf.write(' decoration-${_decorationName(decoration)}="True"');
    }

    // extra custom attributes
    extraAttrs.forEach((k, v) => buf.write(' $k="$v"'));

    buf.write('/>');
    return buf.toString();
  }

  String _decorationName(FieldDecoration d) {
    return switch (d) {
      FieldDecoration.bold => 'bf',
      FieldDecoration.italic => 'it',
      FieldDecoration.danger => 'danger',
      FieldDecoration.info => 'info',
      FieldDecoration.muted => 'muted',
      FieldDecoration.success => 'success',
      FieldDecoration.warning => 'warning',
      _ => '',
    };
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fieldType': fieldType.value,
        'label': label,
        'required': required,
        'readonly': readonly,
        'nolabel': nolabel,
        'invisible': invisible,
        'defaultValue': defaultValue,
        'placeholder': placeholder,
        'widget': widget,
        'colspan': colspan,
        'domain': domain,
        'context': context,
        'attrs': attrs,
        'groups': groups,
        'onchange': onchange,
        'help': help,
        'comodel': comodel,
        'relationField': relationField,
        'selectionOptions': selectionOptions.map((o) => o.toJson()).toList(),
        'decoration': decoration.name,
        'sum': sum,
        'optional': optional,
        'extraAttrs': extraAttrs,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OdooField.fromJson(Map<String, dynamic> json) {
    return OdooField(
      id: json['id'] as String,
      name: json['name'] as String,
      fieldType: OdooFieldType.fromString(json['fieldType'] as String),
      label: json['label'] as String?,
      required: json['required'] as bool? ?? false,
      readonly: json['readonly'] as bool? ?? false,
      nolabel: json['nolabel'] as bool? ?? false,
      invisible: json['invisible'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
      placeholder: json['placeholder'] as String?,
      widget: json['widget'] as String?,
      colspan: json['colspan'] as int?,
      domain: json['domain'] as String?,
      context: json['context'] as String?,
      attrs: json['attrs'] as String?,
      groups: json['groups'] as String?,
      onchange: json['onchange'] as String?,
      help: json['help'] as String?,
      comodel: json['comodel'] as String?,
      relationField: json['relationField'] as String?,
      selectionOptions: (json['selectionOptions'] as List<dynamic>? ?? [])
          .map((o) => SelectionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      decoration: FieldDecoration.values.firstWhere(
        (d) => d.name == (json['decoration'] as String? ?? 'none'),
        orElse: () => FieldDecoration.none,
      ),
      sum: json['sum'] as String?,
      optional: json['optional'] as bool? ?? false,
      extraAttrs: Map<String, dynamic>.from(
          json['extraAttrs'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // ─── CopyWith ────────────────────────────────────────────────────────────────

  OdooField copyWith({
    String? id,
    String? name,
    OdooFieldType? fieldType,
    String? label,
    bool? required,
    bool? readonly,
    bool? nolabel,
    bool? invisible,
    String? defaultValue,
    String? placeholder,
    String? widget,
    int? colspan,
    String? domain,
    String? context,
    String? attrs,
    String? groups,
    String? onchange,
    String? help,
    String? comodel,
    String? relationField,
    List<SelectionOption>? selectionOptions,
    FieldDecoration? decoration,
    String? sum,
    bool? optional,
    Map<String, dynamic>? extraAttrs,
  }) {
    return OdooField(
      id: id ?? this.id,
      name: name ?? this.name,
      fieldType: fieldType ?? this.fieldType,
      label: label ?? this.label,
      required: required ?? this.required,
      readonly: readonly ?? this.readonly,
      nolabel: nolabel ?? this.nolabel,
      invisible: invisible ?? this.invisible,
      defaultValue: defaultValue ?? this.defaultValue,
      placeholder: placeholder ?? this.placeholder,
      widget: widget ?? this.widget,
      colspan: colspan ?? this.colspan,
      domain: domain ?? this.domain,
      context: context ?? this.context,
      attrs: attrs ?? this.attrs,
      groups: groups ?? this.groups,
      onchange: onchange ?? this.onchange,
      help: help ?? this.help,
      comodel: comodel ?? this.comodel,
      relationField: relationField ?? this.relationField,
      selectionOptions: selectionOptions ?? this.selectionOptions,
      decoration: decoration ?? this.decoration,
      sum: sum ?? this.sum,
      optional: optional ?? this.optional,
      extraAttrs: extraAttrs ?? this.extraAttrs,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id, name, fieldType, label, required, readonly, nolabel, invisible,
        widget, colspan, decoration, optional,
      ];
}

// ─── Selection Option ─────────────────────────────────────────────────────────

/// A single option inside a selection/radio field
class SelectionOption extends Equatable {
  final String value;
  final String label;

  const SelectionOption({required this.value, required this.label});

  Map<String, dynamic> toJson() => {'value': value, 'label': label};

  factory SelectionOption.fromJson(Map<String, dynamic> json) =>
      SelectionOption(
        value: json['value'] as String,
        label: json['label'] as String,
      );

  @override
  List<Object?> get props => [value, label];
}
