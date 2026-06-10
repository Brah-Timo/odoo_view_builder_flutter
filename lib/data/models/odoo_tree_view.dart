// lib/data/models/odoo_tree_view.dart
//
// Specialised extension helpers for Tree (List) views.
// The full data is stored in OdooView; this file adds
// tree-specific helpers and aggregation options.

import 'package:equatable/equatable.dart';
import 'odoo_field.dart';

/// Aggregate function available on numeric tree columns
enum ColumnAggregate { none, sum, avg, max, min }

/// Optional column visibility
enum ColumnOptional { none, show, hide }

/// Extended metadata for a column inside a Tree view
class TreeColumn extends Equatable {
  final OdooField field;
  final ColumnAggregate aggregate;
  final ColumnOptional optional;
  final String? width;          // e.g. "200px" or "1"
  final bool editable;
  final String? decoration;     // decoration-danger / decoration-success / etc.

  const TreeColumn({
    required this.field,
    this.aggregate = ColumnAggregate.none,
    this.optional = ColumnOptional.none,
    this.width,
    this.editable = false,
    this.decoration,
  });

  factory TreeColumn.fromField(OdooField field) =>
      TreeColumn(field: field);

  /// Generates the <field> XML tag with tree-specific attributes
  String toXml({int indent = 12}) {
    final pad = ' ' * indent;
    final buf = StringBuffer('$pad<field name="${field.name}"');

    if (field.label != null && field.label!.isNotEmpty) {
      buf.write(' string="${field.label}"');
    }
    if (field.readonly) buf.write(' readonly="1"');
    if (field.invisible) buf.write(' invisible="1"');
    if (field.widget != null && field.widget!.isNotEmpty) {
      buf.write(' widget="${field.widget}"');
    }
    if (width != null && width!.isNotEmpty) buf.write(' width="$width"');

    // Aggregation
    if (aggregate != ColumnAggregate.none) {
      buf.write(' ${aggregate.name}="${field.label ?? field.name}"');
    }

    // Optional visibility
    if (optional != ColumnOptional.none) {
      buf.write(' optional="${optional.name}"');
    }

    // Decoration
    if (decoration != null && decoration!.isNotEmpty) {
      buf.write(' $decoration="True"');
    }

    buf.write('/>');
    return buf.toString();
  }

  TreeColumn copyWith({
    OdooField? field,
    ColumnAggregate? aggregate,
    ColumnOptional? optional,
    String? width,
    bool? editable,
    String? decoration,
  }) {
    return TreeColumn(
      field: field ?? this.field,
      aggregate: aggregate ?? this.aggregate,
      optional: optional ?? this.optional,
      width: width ?? this.width,
      editable: editable ?? this.editable,
      decoration: decoration ?? this.decoration,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field.toJson(),
        'aggregate': aggregate.name,
        'optional': optional.name,
        'width': width,
        'editable': editable,
        'decoration': decoration,
      };

  factory TreeColumn.fromJson(Map<String, dynamic> json) => TreeColumn(
        field: OdooField.fromJson(json['field'] as Map<String, dynamic>),
        aggregate: ColumnAggregate.values.firstWhere(
          (a) => a.name == (json['aggregate'] as String? ?? 'none'),
          orElse: () => ColumnAggregate.none,
        ),
        optional: ColumnOptional.values.firstWhere(
          (o) => o.name == (json['optional'] as String? ?? 'none'),
          orElse: () => ColumnOptional.none,
        ),
        width: json['width'] as String?,
        editable: json['editable'] as bool? ?? false,
        decoration: json['decoration'] as String?,
      );

  @override
  List<Object?> get props => [field, aggregate, optional, width, editable];
}
