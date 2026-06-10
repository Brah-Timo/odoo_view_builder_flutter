// lib/data/models/odoo_kanban_view.dart
//
// Kanban-specific helpers and card layout model.

import 'package:equatable/equatable.dart';
import 'odoo_field.dart';

/// A kanban card section (header / body / footer)
enum KanbanSection { header, body, footer }

/// A positioned field inside a Kanban card template
class KanbanCardField extends Equatable {
  final OdooField field;
  final KanbanSection section;
  final String? cssClass;
  final String? tIf;      // t-if condition
  final bool bold;
  final bool muted;

  const KanbanCardField({
    required this.field,
    this.section = KanbanSection.body,
    this.cssClass,
    this.tIf,
    this.bold = false,
    this.muted = false,
  });

  factory KanbanCardField.fromField(OdooField field) =>
      KanbanCardField(field: field);

  /// Generates a <field> (or <t t-if="..."><field .../></t>) snippet
  String toXml({int indent = 24}) {
    final pad = ' ' * indent;
    final buf = StringBuffer();

    if (tIf != null && tIf!.isNotEmpty) {
      buf.writeln('$pad<t t-if="$tIf">');
    }

    final innerPad = tIf != null ? '$pad    ' : pad;

    if (cssClass != null || bold || muted) {
      final cls = [
        if (cssClass != null) cssClass!,
        if (bold) 'fw-bold',
        if (muted) 'text-muted',
      ].join(' ');
      buf.writeln('$innerPad<div class="$cls">');
      buf.writeln('$innerPad    <field name="${field.name}"/>');
      buf.writeln('$innerPad</div>');
    } else {
      buf.writeln('$innerPad<field name="${field.name}"/>');
    }

    if (tIf != null) {
      buf.write('$pad</t>');
    }

    return buf.toString().trimRight();
  }

  KanbanCardField copyWith({
    OdooField? field,
    KanbanSection? section,
    String? cssClass,
    String? tIf,
    bool? bold,
    bool? muted,
  }) {
    return KanbanCardField(
      field: field ?? this.field,
      section: section ?? this.section,
      cssClass: cssClass ?? this.cssClass,
      tIf: tIf ?? this.tIf,
      bold: bold ?? this.bold,
      muted: muted ?? this.muted,
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field.toJson(),
        'section': section.name,
        'cssClass': cssClass,
        'tIf': tIf,
        'bold': bold,
        'muted': muted,
      };

  factory KanbanCardField.fromJson(Map<String, dynamic> json) {
    return KanbanCardField(
      field: OdooField.fromJson(json['field'] as Map<String, dynamic>),
      section: KanbanSection.values.firstWhere(
        (s) => s.name == (json['section'] as String? ?? 'body'),
        orElse: () => KanbanSection.body,
      ),
      cssClass: json['cssClass'] as String?,
      tIf: json['tIf'] as String?,
      bold: json['bold'] as bool? ?? false,
      muted: json['muted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [field, section, cssClass, tIf, bold, muted];
}

/// Full kanban card template descriptor
class KanbanCardTemplate extends Equatable {
  final List<KanbanCardField> headerFields;
  final List<KanbanCardField> bodyFields;
  final List<KanbanCardField> footerFields;
  final String? colorField;   // field name for color bar
  final bool showActivityButton;
  final bool showStatusBar;

  const KanbanCardTemplate({
    this.headerFields = const [],
    this.bodyFields = const [],
    this.footerFields = const [],
    this.colorField,
    this.showActivityButton = false,
    this.showStatusBar = false,
  });

  /// Generates the full <templates> block
  String toXml({int indent = 16}) {
    final i = ' ' * indent;
    final i4 = ' ' * (indent + 4);
    final i8 = ' ' * (indent + 8);
    final i12 = ' ' * (indent + 12);
    final buf = StringBuffer();

    buf.writeln('$i<templates>');
    buf.writeln('$i4<t t-name="kanban-box">');
    buf.writeln(
      '$i8<div class="oe_kanban_global_click${colorField != null ? ' oe_kanban_color_' : ''}">',
    );

    if (colorField != null) {
      buf.writeln('$i12<div class="oe_kanban_color_bar" t-attf-class="oe_kanban_color_#{kanban_getcolor(record.${colorField!}.raw_value)}"/>');
    }

    // Header
    if (headerFields.isNotEmpty) {
      buf.writeln('$i12<div class="oe_kanban_details">');
      buf.writeln('$i12    <strong class="o_kanban_record_title">');
      for (final f in headerFields) {
        buf.writeln(f.toXml(indent: indent + 20));
      }
      buf.writeln('$i12    </strong>');
      buf.writeln('$i12</div>');
    }

    // Body
    if (bodyFields.isNotEmpty) {
      buf.writeln('$i12<div class="oe_kanban_details">');
      for (final f in bodyFields) {
        buf.writeln(f.toXml(indent: indent + 16));
      }
      buf.writeln('$i12</div>');
    }

    // Footer
    if (footerFields.isNotEmpty || showActivityButton) {
      buf.writeln('$i12<div class="oe_kanban_footer">');
      for (final f in footerFields) {
        buf.writeln(f.toXml(indent: indent + 16));
      }
      if (showActivityButton) {
        buf.writeln('$i12    <div class="oe_kanban_footer_right">');
        buf.writeln('$i12        <button name="action_schedule_meeting" type="object" class="oe_kanban_action oe_kanban_action_button">');
        buf.writeln('$i12            <i class="fa fa-phone" role="img"/>');
        buf.writeln('$i12        </button>');
        buf.writeln('$i12    </div>');
      }
      buf.writeln('$i12</div>');
    }

    buf.writeln('$i8</div>');
    buf.writeln('$i4</t>');
    buf.write('$i</templates>');
    return buf.toString();
  }

  KanbanCardTemplate copyWith({
    List<KanbanCardField>? headerFields,
    List<KanbanCardField>? bodyFields,
    List<KanbanCardField>? footerFields,
    String? colorField,
    bool? showActivityButton,
    bool? showStatusBar,
  }) {
    return KanbanCardTemplate(
      headerFields: headerFields ?? this.headerFields,
      bodyFields: bodyFields ?? this.bodyFields,
      footerFields: footerFields ?? this.footerFields,
      colorField: colorField ?? this.colorField,
      showActivityButton: showActivityButton ?? this.showActivityButton,
      showStatusBar: showStatusBar ?? this.showStatusBar,
    );
  }

  List<KanbanCardField> get allFields =>
      [...headerFields, ...bodyFields, ...footerFields];

  Map<String, dynamic> toJson() => {
        'headerFields': headerFields.map((f) => f.toJson()).toList(),
        'bodyFields': bodyFields.map((f) => f.toJson()).toList(),
        'footerFields': footerFields.map((f) => f.toJson()).toList(),
        'colorField': colorField,
        'showActivityButton': showActivityButton,
        'showStatusBar': showStatusBar,
      };

  factory KanbanCardTemplate.fromJson(Map<String, dynamic> json) {
    return KanbanCardTemplate(
      headerFields: (json['headerFields'] as List<dynamic>? ?? [])
          .map((f) => KanbanCardField.fromJson(f as Map<String, dynamic>))
          .toList(),
      bodyFields: (json['bodyFields'] as List<dynamic>? ?? [])
          .map((f) => KanbanCardField.fromJson(f as Map<String, dynamic>))
          .toList(),
      footerFields: (json['footerFields'] as List<dynamic>? ?? [])
          .map((f) => KanbanCardField.fromJson(f as Map<String, dynamic>))
          .toList(),
      colorField: json['colorField'] as String?,
      showActivityButton: json['showActivityButton'] as bool? ?? false,
      showStatusBar: json['showStatusBar'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        headerFields,
        bodyFields,
        footerFields,
        colorField,
        showActivityButton,
      ];
}
