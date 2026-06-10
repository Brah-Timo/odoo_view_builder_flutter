// lib/services/xml/xml_parser.dart

import 'package:xml/xml.dart' as xml;
import '../../data/models/odoo_form.dart';
import '../../data/models/odoo_field.dart';
import '../../data/models/odoo_group.dart';

/// Result of an XML parse operation
class ParseResult {
  final OdooView? view;
  final String? error;
  final List<String> warnings;

  const ParseResult._({this.view, this.error, this.warnings = const []});

  factory ParseResult.success(OdooView view, {List<String>? warnings}) =>
      ParseResult._(view: view, warnings: warnings ?? []);

  factory ParseResult.failure(String error) =>
      ParseResult._(error: error);

  bool get isSuccess => view != null;
}

/// Parses Odoo XML view files into OdooView models
class XmlParser {
  XmlParser._();

  // ─── Public API ──────────────────────────────────────────────────────────────

  /// Parse a full views.xml file — returns the first view found.
  static ParseResult parseViewFile(String xmlContent) {
    try {
      final doc = xml.XmlDocument.parse(xmlContent);
      final records = doc.findAllElements('record');

      if (records.isEmpty) {
        return ParseResult.failure('No <record> elements found in the XML.');
      }

      final record = records.first;
      return _parseRecord(record);
    } on xml.XmlParserException catch (e) {
      return ParseResult.failure('XML parse error at line ${e.position}: ${e.message}');
    } catch (e) {
      return ParseResult.failure('Unexpected error: $e');
    }
  }

  /// Parse all views in a file
  static List<ParseResult> parseAllViews(String xmlContent) {
    try {
      final doc = xml.XmlDocument.parse(xmlContent);
      return doc.findAllElements('record').map(_parseRecord).toList();
    } on xml.XmlParserException catch (e) {
      return [ParseResult.failure('XML parse error: ${e.message}')];
    } catch (e) {
      return [ParseResult.failure('Unexpected error: $e')];
    }
  }

  // ─── Record Parsing ──────────────────────────────────────────────────────────

  static ParseResult _parseRecord(xml.XmlElement record) {
    final warnings = <String>[];

    try {
      final id = record.getAttribute('id') ?? 'view_imported';

      // Extract named fields from record
      String? name, model, inheritId;
      int priority = 16;
      xml.XmlElement? archElement;

      for (final field in record.findElements('field')) {
        final fieldName = field.getAttribute('name');
        switch (fieldName) {
          case 'name':
            name = field.innerText.trim();
            break;
          case 'model':
            model = field.innerText.trim();
            break;
          case 'inherit_id':
            inheritId = field.getAttribute('ref');
            break;
          case 'priority':
            priority = int.tryParse(
                  field.getAttribute('eval') ?? field.innerText.trim(),
                ) ??
                16;
            break;
          case 'arch':
            archElement = field;
            break;
        }
      }

      if (model == null) {
        return ParseResult.failure('Missing <field name="model"> in record $id');
      }

      if (archElement == null) {
        return ParseResult.failure('Missing <field name="arch"> in record $id');
      }

      // Find the root view element inside arch
      final viewElements = archElement.children
          .whereType<xml.XmlElement>()
          .toList();

      if (viewElements.isEmpty) {
        return ParseResult.failure('No view element inside <arch> in record $id');
      }

      final viewRoot = viewElements.first;
      final viewTypeName = viewRoot.localName;

      final viewType = switch (viewTypeName) {
        'form' => ViewType.form,
        'tree' => ViewType.tree,
        'kanban' => ViewType.kanban,
        _ => null,
      };

      if (viewType == null) {
        return ParseResult.failure(
            'Unknown view type: $viewTypeName in record $id');
      }

      final now = DateTime.now();
      OdooView view;

      switch (viewType) {
        case ViewType.form:
          view = _parseFormView(
            viewRoot: viewRoot,
            id: id,
            name: name ?? id,
            model: model,
            inheritId: inheritId,
            priority: priority,
            now: now,
          );
          break;
        case ViewType.tree:
          view = _parseTreeView(
            viewRoot: viewRoot,
            id: id,
            name: name ?? id,
            model: model,
            inheritId: inheritId,
            priority: priority,
            now: now,
          );
          break;
        case ViewType.kanban:
          view = _parseKanbanView(
            viewRoot: viewRoot,
            id: id,
            name: name ?? id,
            model: model,
            inheritId: inheritId,
            priority: priority,
            now: now,
          );
          break;
      }

      return ParseResult.success(view, warnings: warnings);
    } catch (e) {
      return ParseResult.failure('Failed to parse record: $e');
    }
  }

  // ─── Form View Parsing ───────────────────────────────────────────────────────

  static OdooView _parseFormView({
    required xml.XmlElement viewRoot,
    required String id,
    required String name,
    required String model,
    required String? inheritId,
    required int priority,
    required DateTime now,
  }) {
    final topFields = <OdooField>[];
    final groups = <OdooGroup>[];
    final pages = <NotebookPage>[];
    String? customCSS;

    for (final child in viewRoot.children.whereType<xml.XmlElement>()) {
      switch (child.localName) {
        case 'field':
          if (_isDirectChild(child, viewRoot)) {
            topFields.add(_parseField(child));
          }
          break;
        case 'group':
          if (_isDirectChild(child, viewRoot)) {
            groups.add(_parseGroup(child));
          }
          break;
        case 'notebook':
          for (final page in child.findElements('page')) {
            pages.add(_parsePage(page));
          }
          break;
        case 'style':
          customCSS = child.innerText.trim();
          break;
      }
    }

    return OdooView(
      id: id,
      name: name,
      model: model,
      viewType: ViewType.form,
      inheritId: inheritId,
      topLevelFields: topFields,
      groups: groups,
      pages: pages,
      customCSS: customCSS,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Tree View Parsing ───────────────────────────────────────────────────────

  static OdooView _parseTreeView({
    required xml.XmlElement viewRoot,
    required String id,
    required String name,
    required String model,
    required String? inheritId,
    required int priority,
    required DateTime now,
  }) {
    final fields = viewRoot
        .findElements('field')
        .map(_parseField)
        .toList();

    final editable = viewRoot.getAttribute('editable') != null;
    final defaultOrder = viewRoot.getAttribute('default_order');

    return OdooView(
      id: id,
      name: name,
      model: model,
      viewType: ViewType.tree,
      inheritId: inheritId,
      topLevelFields: fields,
      editable: editable,
      defaultOrder: defaultOrder,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Kanban View Parsing ─────────────────────────────────────────────────────

  static OdooView _parseKanbanView({
    required xml.XmlElement viewRoot,
    required String id,
    required String name,
    required String model,
    required String? inheritId,
    required int priority,
    required DateTime now,
  }) {
    // Extract field declarations at the top level of kanban
    final fields = viewRoot
        .findElements('field')
        .map(_parseField)
        .toList();

    final kanbanClass = viewRoot.getAttribute('class');

    return OdooView(
      id: id,
      name: name,
      model: model,
      viewType: ViewType.kanban,
      inheritId: inheritId,
      topLevelFields: fields,
      kanbanClass: kanbanClass,
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ─── Element Parsers ─────────────────────────────────────────────────────────

  static OdooField _parseField(xml.XmlElement el) {
    final name = el.getAttribute('name') ?? 'unknown';
    final widgetAttr = el.getAttribute('widget');
    final fieldType = _inferFieldType(name, widgetAttr);
    final now = DateTime.now();

    return OdooField(
      id: '${name}_${now.millisecondsSinceEpoch}',
      name: name,
      fieldType: fieldType,
      label: el.getAttribute('string'),
      required: el.getAttribute('required') == '1',
      readonly: el.getAttribute('readonly') == '1',
      nolabel: el.getAttribute('nolabel') == '1',
      invisible: el.getAttribute('invisible') == '1',
      widget: widgetAttr,
      colspan: int.tryParse(el.getAttribute('colspan') ?? ''),
      domain: el.getAttribute('domain'),
      context: el.getAttribute('context'),
      attrs: el.getAttribute('attrs'),
      groups: el.getAttribute('groups'),
      placeholder: el.getAttribute('placeholder'),
      sum: el.getAttribute('sum'),
      optional: el.getAttribute('optional') == 'show',
      createdAt: now,
      updatedAt: now,
    );
  }

  static OdooGroup _parseGroup(xml.XmlElement el) {
    final now = DateTime.now();

    final fields = <OdooField>[];
    final subGroups = <OdooGroup>[];

    for (final child in el.children.whereType<xml.XmlElement>()) {
      if (child.localName == 'field') {
        fields.add(_parseField(child));
      } else if (child.localName == 'group') {
        subGroups.add(_parseGroup(child));
      }
    }

    return OdooGroup(
      id: 'group_${now.millisecondsSinceEpoch}',
      label: el.getAttribute('string'),
      fields: fields,
      subGroups: subGroups,
      colspan: int.tryParse(el.getAttribute('colspan') ?? ''),
      fillBrk: el.getAttribute('fill_brk') == '1',
      expand: el.getAttribute('expand') == '1',
      col: int.tryParse(el.getAttribute('col') ?? ''),
      groups: el.getAttribute('groups'),
      invisible: el.getAttribute('invisible') == '1',
      attrs: el.getAttribute('attrs'),
      createdAt: now,
      updatedAt: now,
    );
  }

  static NotebookPage _parsePage(xml.XmlElement el) {
    final label = el.getAttribute('string') ?? 'Page';
    final invisible = el.getAttribute('invisible') == '1';

    final fields = <OdooField>[];
    final groups = <OdooGroup>[];

    for (final child in el.children.whereType<xml.XmlElement>()) {
      if (child.localName == 'field') {
        fields.add(_parseField(child));
      } else if (child.localName == 'group') {
        groups.add(_parseGroup(child));
      }
    }

    return NotebookPage(
      id: '${label.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      fields: fields,
      groups: groups,
      invisible: invisible,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static bool _isDirectChild(xml.XmlElement child, xml.XmlElement parent) {
    return child.parent == parent;
  }

  /// Infer field type from name / widget hints since Odoo XML doesn't carry
  /// the field type (it's defined in the model, not the view).
  static OdooFieldType _inferFieldType(String name, String? widget) {
    if (widget != null) {
      if (['email', 'url', 'phone'].contains(widget)) return OdooFieldType.char;
      if (widget == 'many2many_tags') return OdooFieldType.many2many;
      if (widget == 'many2one_tags') return OdooFieldType.many2one;
      if (widget == 'statusbar') return OdooFieldType.many2one;
      if (widget == 'html') return OdooFieldType.html;
      if (widget == 'monetary') return OdooFieldType.float;
      if (widget == 'progressbar') return OdooFieldType.float;
      if (widget == 'image') return OdooFieldType.binary;
    }

    // Name-based heuristics
    if (name.endsWith('_id')) return OdooFieldType.many2one;
    if (name.endsWith('_ids')) return OdooFieldType.many2many;
    if (name.contains('date')) return OdooFieldType.date;
    if (name.contains('time') || name.contains('datetime')) return OdooFieldType.datetime;
    if (name.contains('amount') || name.contains('price') || name.contains('total')) {
      return OdooFieldType.float;
    }
    if (name.contains('qty') || name.contains('quantity') || name.contains('count')) {
      return OdooFieldType.integer;
    }
    if (name == 'active' || name.startsWith('is_') || name.startsWith('has_')) {
      return OdooFieldType.boolean;
    }
    if (name == 'description' || name == 'note' || name == 'notes') {
      return OdooFieldType.text;
    }
    if (name == 'state') return OdooFieldType.selection;

    return OdooFieldType.char;
  }
}
