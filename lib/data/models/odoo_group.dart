// lib/data/models/odoo_group.dart

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'odoo_field.dart';

/// Represents a <group> element in an Odoo form view.
/// Groups can be nested (sub-groups) to create complex layouts.
class OdooGroup extends Equatable {
  final String id;
  final String? label;
  final List<OdooField> fields;
  final List<OdooGroup> subGroups;
  final int? colspan;
  final bool fillBrk;
  final bool expand;
  final String? expandButtonLabel;
  final int? col;          // number of columns inside the group
  final String? groups;    // access groups
  final bool invisible;
  final String? attrs;
  final int nestingLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OdooGroup({
    required this.id,
    this.label,
    this.fields = const [],
    this.subGroups = const [],
    this.colspan,
    this.fillBrk = false,
    this.expand = false,
    this.expandButtonLabel,
    this.col,
    this.groups,
    this.invisible = false,
    this.attrs,
    this.nestingLevel = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory — creates a new group with generated ID
  factory OdooGroup.create({
    String? label,
    List<OdooField>? fields,
    int? colspan,
  }) {
    final now = DateTime.now();
    return OdooGroup(
      id: const Uuid().v4(),
      label: label,
      fields: fields ?? const [],
      colspan: colspan,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Whether this group has any content
  bool get hasContent => fields.isNotEmpty || subGroups.isNotEmpty;

  /// Total number of fields recursively
  int get totalFieldCount {
    int count = fields.length;
    for (final sub in subGroups) {
      count += sub.totalFieldCount;
    }
    return count;
  }

  // ─── XML Generation ──────────────────────────────────────────────────────────

  String toXml({int indent = 8}) {
    final pad = ' ' * indent;
    final buf = StringBuffer('$pad<group');

    if (label != null && label!.isNotEmpty) buf.write(' string="$label"');
    if (colspan != null) buf.write(' colspan="$colspan"');
    if (col != null) buf.write(' col="$col"');
    if (fillBrk) buf.write(' fill_brk="1"');
    if (expand) buf.write(' expand="1"');
    if (expandButtonLabel != null && expandButtonLabel!.isNotEmpty) {
      buf.write(' expandButtonLabel="$expandButtonLabel"');
    }
    if (groups != null && groups!.isNotEmpty) buf.write(' groups="$groups"');
    if (invisible) buf.write(' invisible="1"');
    if (attrs != null && attrs!.isNotEmpty) buf.write(' attrs="$attrs"');

    buf.write('>\n');

    // Fields inside this group
    for (final field in fields) {
      buf.writeln(field.toXml(indent: indent + 4));
    }

    // Nested sub-groups
    for (final sub in subGroups) {
      buf.write(sub.toXml(indent: indent + 4));
    }

    buf.write('$pad</group>\n');
    return buf.toString();
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fields': fields.map((f) => f.toJson()).toList(),
        'subGroups': subGroups.map((g) => g.toJson()).toList(),
        'colspan': colspan,
        'fillBrk': fillBrk,
        'expand': expand,
        'expandButtonLabel': expandButtonLabel,
        'col': col,
        'groups': groups,
        'invisible': invisible,
        'attrs': attrs,
        'nestingLevel': nestingLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OdooGroup.fromJson(Map<String, dynamic> json) {
    return OdooGroup(
      id: json['id'] as String,
      label: json['label'] as String?,
      fields: (json['fields'] as List<dynamic>? ?? [])
          .map((f) => OdooField.fromJson(f as Map<String, dynamic>))
          .toList(),
      subGroups: (json['subGroups'] as List<dynamic>? ?? [])
          .map((g) => OdooGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      colspan: json['colspan'] as int?,
      fillBrk: json['fillBrk'] as bool? ?? false,
      expand: json['expand'] as bool? ?? false,
      expandButtonLabel: json['expandButtonLabel'] as String?,
      col: json['col'] as int?,
      groups: json['groups'] as String?,
      invisible: json['invisible'] as bool? ?? false,
      attrs: json['attrs'] as String?,
      nestingLevel: json['nestingLevel'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // ─── CopyWith ────────────────────────────────────────────────────────────────

  OdooGroup copyWith({
    String? id,
    String? label,
    List<OdooField>? fields,
    List<OdooGroup>? subGroups,
    int? colspan,
    bool? fillBrk,
    bool? expand,
    String? expandButtonLabel,
    int? col,
    String? groups,
    bool? invisible,
    String? attrs,
    int? nestingLevel,
  }) {
    return OdooGroup(
      id: id ?? this.id,
      label: label ?? this.label,
      fields: fields ?? this.fields,
      subGroups: subGroups ?? this.subGroups,
      colspan: colspan ?? this.colspan,
      fillBrk: fillBrk ?? this.fillBrk,
      expand: expand ?? this.expand,
      expandButtonLabel: expandButtonLabel ?? this.expandButtonLabel,
      col: col ?? this.col,
      groups: groups ?? this.groups,
      invisible: invisible ?? this.invisible,
      attrs: attrs ?? this.attrs,
      nestingLevel: nestingLevel ?? this.nestingLevel,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a deep copy with a fresh ID (used when duplicating)
  OdooGroup duplicate() {
    final now = DateTime.now();
    return OdooGroup(
      id: const Uuid().v4(),
      label: label != null ? '$label (copy)' : null,
      fields: fields.map((f) => f.copyWith(id: const Uuid().v4())).toList(),
      subGroups: subGroups.map((g) => g.duplicate()).toList(),
      colspan: colspan,
      fillBrk: fillBrk,
      expand: expand,
      expandButtonLabel: expandButtonLabel,
      col: col,
      groups: groups,
      invisible: invisible,
      attrs: attrs,
      nestingLevel: nestingLevel,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  List<Object?> get props => [id, label, fields, subGroups, colspan, col];
}
