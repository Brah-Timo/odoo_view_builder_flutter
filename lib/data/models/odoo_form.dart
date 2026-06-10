// lib/data/models/odoo_form.dart

import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'odoo_field.dart';
import 'odoo_group.dart';

/// The type of Odoo View
enum ViewType {
  form('form', 'Form View'),
  tree('tree', 'List View'),
  kanban('kanban', 'Kanban View');

  const ViewType(this.value, this.label);
  final String value;
  final String label;

  static ViewType fromString(String v) =>
      ViewType.values.firstWhere((e) => e.value == v, orElse: () => ViewType.form);
}

/// A notebook page (<page>) inside a <notebook> element
class NotebookPage extends Equatable {
  final String id;
  final String label;
  final List<OdooField> fields;
  final List<OdooGroup> groups;
  final bool? invisible;

  const NotebookPage({
    required this.id,
    required this.label,
    this.fields = const [],
    this.groups = const [],
    this.invisible,
  });

  factory NotebookPage.create(String label) {
    return NotebookPage(id: const Uuid().v4(), label: label);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'fields': fields.map((f) => f.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'invisible': invisible,
      };

  factory NotebookPage.fromJson(Map<String, dynamic> json) => NotebookPage(
        id: json['id'] as String,
        label: json['label'] as String,
        fields: (json['fields'] as List<dynamic>? ?? [])
            .map((f) => OdooField.fromJson(f as Map<String, dynamic>))
            .toList(),
        groups: (json['groups'] as List<dynamic>? ?? [])
            .map((g) => OdooGroup.fromJson(g as Map<String, dynamic>))
            .toList(),
        invisible: json['invisible'] as bool?,
      );

  @override
  List<Object?> get props => [id, label];
}

/// The full Odoo View (Form / Tree / Kanban) model
class OdooView extends Equatable {
  final String id;              // e.g. "view_partner_form_custom"
  final String name;            // display name
  final String model;           // Odoo model e.g. "res.partner"
  final ViewType viewType;
  final String? docModule;      // module name in technical XML id: module.id
  final String? inheritId;      // id of view being inherited

  // ── Form-specific ─────────────────────────────────────────────────────────
  final List<OdooField> topLevelFields;   // fields outside groups
  final List<OdooGroup> groups;
  final List<NotebookPage> pages;         // notebook pages
  final bool? createButton;
  final bool? deleteButton;
  final bool? editButton;
  final String? customCSS;

  // ── Tree-specific ─────────────────────────────────────────────────────────
  final bool editable;           // editable="top"
  final bool? decorationDanger;
  final String? defaultOrder;
  final bool? noCreate;

  // ── Kanban-specific ───────────────────────────────────────────────────────
  final String? kanbanClass;
  final bool? quickCreate;
  final String? groupBy;

  // ── Metadata ──────────────────────────────────────────────────────────────
  final int priority;            // ir.ui.view priority
  final DateTime createdAt;
  final DateTime updatedAt;

  const OdooView({
    required this.id,
    required this.name,
    required this.model,
    required this.viewType,
    this.docModule,
    this.inheritId,
    this.topLevelFields = const [],
    this.groups = const [],
    this.pages = const [],
    this.createButton,
    this.deleteButton,
    this.editButton,
    this.customCSS,
    this.editable = false,
    this.decorationDanger,
    this.defaultOrder,
    this.noCreate,
    this.kanbanClass,
    this.quickCreate,
    this.groupBy,
    this.priority = 16,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory — creates a blank view
  factory OdooView.create({
    String? id,
    required String name,
    required String model,
    required ViewType viewType,
    String? docModule,
    List<OdooField>? fields,
    List<OdooGroup>? groups,
  }) {
    final now = DateTime.now();
    final safeId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return OdooView(
      id: id ?? 'view_${safeId}_${viewType.value}',
      name: name,
      model: model,
      viewType: viewType,
      docModule: docModule,
      topLevelFields: fields ?? const [],
      groups: groups ?? const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// Flat list of ALL fields (top-level + inside groups + inside pages)
  List<OdooField> get allFields {
    final result = <OdooField>[...topLevelFields];
    for (final g in groups) {
      result.addAll(_collectGroupFields(g));
    }
    for (final p in pages) {
      result.addAll(p.fields);
      for (final g in p.groups) {
        result.addAll(_collectGroupFields(g));
      }
    }
    return result;
  }

  List<OdooField> _collectGroupFields(OdooGroup group) {
    final result = <OdooField>[...group.fields];
    for (final sub in group.subGroups) {
      result.addAll(_collectGroupFields(sub));
    }
    return result;
  }

  /// Alias for [topLevelFields] — convenience for tests and external code.
  List<OdooField> get fields => topLevelFields;

  bool get isEmpty =>
      topLevelFields.isEmpty && groups.isEmpty && pages.isEmpty;

  String get technicalId =>
      docModule != null ? '$docModule.$id' : id;

  // ─── XML Generation ──────────────────────────────────────────────────────────

  /// Full views.xml content for this single view
  String generateXml() {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="utf-8"?>');
    buf.writeln('<odoo>');
    buf.writeln('    <data>');
    buf.writeln();
    buf.writeln(_generateRecord());
    buf.writeln();
    buf.writeln('    </data>');
    buf.write('</odoo>');
    return buf.toString();
  }

  String _generateRecord() {
    final buf = StringBuffer();
    buf.writeln('        <record id="$id" model="ir.ui.view">');
    buf.writeln('            <field name="name">$name</field>');
    buf.writeln('            <field name="model">$model</field>');
    if (priority != 16) {
      buf.writeln('            <field name="priority" eval="$priority"/>');
    }
    if (inheritId != null && inheritId!.isNotEmpty) {
      buf.writeln('            <field name="inherit_id" ref="$inheritId"/>');
    }
    buf.writeln('            <field name="arch" type="xml">');
    buf.write(_generateArch());
    buf.writeln('            </field>');
    buf.write('        </record>');
    return buf.toString();
  }

  String _generateArch() {
    return switch (viewType) {
      ViewType.form => _generateFormArch(),
      ViewType.tree => _generateTreeArch(),
      ViewType.kanban => _generateKanbanArch(),
    };
  }

  String _generateFormArch() {
    final buf = StringBuffer();
    buf.writeln('                <form>');

    if (customCSS != null && customCSS!.isNotEmpty) {
      buf.writeln('                    <style>$customCSS</style>');
    }

    // Top-level fields
    for (final f in topLevelFields) {
      buf.writeln(f.toXml(indent: 20));
    }

    // Groups
    for (final g in groups) {
      buf.write(g.toXml(indent: 20));
    }

    // Notebook (pages)
    if (pages.isNotEmpty) {
      buf.writeln('                    <notebook>');
      for (final page in pages) {
        buf.writeln('                        <page string="${page.label}"${page.invisible == true ? ' invisible="1"' : ''}>');
        for (final f in page.fields) {
          buf.writeln(f.toXml(indent: 28));
        }
        for (final g in page.groups) {
          buf.write(g.toXml(indent: 28));
        }
        buf.writeln('                        </page>');
      }
      buf.writeln('                    </notebook>');
    }

    buf.write('                </form>');
    return buf.toString();
  }

  String _generateTreeArch() {
    final buf = StringBuffer();
    final editableAttr = editable ? ' editable="top"' : '';
    final orderAttr = defaultOrder != null ? ' default_order="$defaultOrder"' : '';
    buf.writeln('                <tree$editableAttr$orderAttr>');

    for (final f in topLevelFields) {
      buf.writeln(f.toXml(indent: 20));
    }

    buf.write('                </tree>');
    return buf.toString();
  }

  String _generateKanbanArch() {
    final buf = StringBuffer();
    final classAttr = kanbanClass != null ? ' class="$kanbanClass"' : '';
    buf.writeln('                <kanban$classAttr>');

    // field declarations for kanban
    for (final f in topLevelFields) {
      buf.writeln('                    <field name="${f.name}"/>');
    }

    buf.writeln('                    <templates>');
    buf.writeln('                        <t t-name="kanban-box">');
    buf.writeln('                            <div class="oe_kanban_global_click">');

    for (final f in topLevelFields.where((f) => !f.invisible)) {
      buf.writeln('                                <field name="${f.name}"/>');
    }

    buf.writeln('                            </div>');
    buf.writeln('                        </t>');
    buf.writeln('                    </templates>');
    buf.write('                </kanban>');
    return buf.toString();
  }

  // ─── Serialization ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'model': model,
        'viewType': viewType.value,
        'docModule': docModule,
        'inheritId': inheritId,
        'topLevelFields': topLevelFields.map((f) => f.toJson()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
        'pages': pages.map((p) => p.toJson()).toList(),
        'createButton': createButton,
        'deleteButton': deleteButton,
        'editButton': editButton,
        'customCSS': customCSS,
        'editable': editable,
        'defaultOrder': defaultOrder,
        'noCreate': noCreate,
        'kanbanClass': kanbanClass,
        'quickCreate': quickCreate,
        'groupBy': groupBy,
        'priority': priority,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory OdooView.fromJson(Map<String, dynamic> json) {
    return OdooView(
      id: json['id'] as String,
      name: json['name'] as String,
      model: json['model'] as String,
      viewType: ViewType.fromString(json['viewType'] as String),
      docModule: json['docModule'] as String?,
      inheritId: json['inheritId'] as String?,
      topLevelFields: (json['topLevelFields'] as List<dynamic>? ?? [])
          .map((f) => OdooField.fromJson(f as Map<String, dynamic>))
          .toList(),
      groups: (json['groups'] as List<dynamic>? ?? [])
          .map((g) => OdooGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
      pages: (json['pages'] as List<dynamic>? ?? [])
          .map((p) => NotebookPage.fromJson(p as Map<String, dynamic>))
          .toList(),
      createButton: json['createButton'] as bool?,
      deleteButton: json['deleteButton'] as bool?,
      editButton: json['editButton'] as bool?,
      customCSS: json['customCSS'] as String?,
      editable: json['editable'] as bool? ?? false,
      defaultOrder: json['defaultOrder'] as String?,
      noCreate: json['noCreate'] as bool?,
      kanbanClass: json['kanbanClass'] as String?,
      quickCreate: json['quickCreate'] as bool?,
      groupBy: json['groupBy'] as String?,
      priority: json['priority'] as int? ?? 16,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // ─── CopyWith ────────────────────────────────────────────────────────────────

  OdooView copyWith({
    String? id,
    String? name,
    String? model,
    ViewType? viewType,
    String? docModule,
    String? inheritId,
    // Accept both 'topLevelFields' and the shorter 'fields' alias
    List<OdooField>? topLevelFields,
    List<OdooField>? fields, // alias for topLevelFields
    List<OdooGroup>? groups,
    List<NotebookPage>? pages,
    bool? createButton,
    bool? deleteButton,
    bool? editButton,
    String? customCSS,
    bool? editable,
    bool? editableTree, // alias for editable (tree-view compat)
    String? defaultOrder,
    bool? noCreate,
    String? kanbanClass,
    bool? quickCreate,
    String? groupBy,
    int? priority,
  }) {
    return OdooView(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      viewType: viewType ?? this.viewType,
      docModule: docModule ?? this.docModule,
      inheritId: inheritId ?? this.inheritId,
      topLevelFields: fields ?? topLevelFields ?? this.topLevelFields,
      groups: groups ?? this.groups,
      pages: pages ?? this.pages,
      createButton: createButton ?? this.createButton,
      deleteButton: deleteButton ?? this.deleteButton,
      editButton: editButton ?? this.editButton,
      customCSS: customCSS ?? this.customCSS,
      editable: editableTree ?? editable ?? this.editable,
      defaultOrder: defaultOrder ?? this.defaultOrder,
      noCreate: noCreate ?? this.noCreate,
      kanbanClass: kanbanClass ?? this.kanbanClass,
      quickCreate: quickCreate ?? this.quickCreate,
      groupBy: groupBy ?? this.groupBy,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, model, viewType, updatedAt];
}

/// Backward-compatibility alias — use [OdooView] in new code.
typedef OdooForm = OdooView;
