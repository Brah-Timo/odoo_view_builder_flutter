// test/services/xml/xml_generator_test.dart
//
// Unit tests for XmlGenerator.

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart' as xml;

import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_form.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_group.dart';
import 'package:odoo_view_builder_flutter/services/xml/xml_generator.dart';

void main() {
  // ── Helpers ─────────────────────────────────────────────────────────────

  OdooForm _partnerForm({
    List<OdooField>? fields,
    List<OdooGroup>? groups,
    ViewType type = ViewType.form,
  }) =>
      OdooForm.create(
        name: 'res.partner.form.test',
        model: 'res.partner',
        viewType: type,
        fields: fields ?? <OdooField>[],
        groups: groups ?? <OdooGroup>[],
      );

  // ── generateSingle() ─────────────────────────────────────────────────────

  group('XmlGenerator.generateSingle()', () {
    test('returns well-formed XML', () {
      final form = _partnerForm(fields: [
        OdooField.create(name: 'name', fieldType: OdooFieldType.char),
      ]);
      final xmlStr = XmlGenerator.generateSingle(form);
      expect(() => xml.XmlDocument.parse(xmlStr), returnsNormally);
    });

    test('contains odoo root element', () {
      final xmlStr = XmlGenerator.generateSingle(_partnerForm());
      final doc = xml.XmlDocument.parse(xmlStr);
      expect(doc.rootElement.name.local, 'odoo');
    });

    test('contains ir.ui.view record', () {
      final xmlStr = XmlGenerator.generateSingle(_partnerForm());
      expect(xmlStr, contains('model="ir.ui.view"'));
    });

    test('contains model field', () {
      final xmlStr = XmlGenerator.generateSingle(_partnerForm());
      expect(xmlStr, contains('res.partner'));
    });

    test('contains arch field with type=xml', () {
      final xmlStr = XmlGenerator.generateSingle(_partnerForm());
      expect(xmlStr, contains('<field name="arch" type="xml">'));
    });

    test('form view has <form> root in arch', () {
      final xmlStr = XmlGenerator.generateSingle(
          _partnerForm(type: ViewType.form));
      final doc = xml.XmlDocument.parse(xmlStr);
      final arch = doc.descendants
          .whereType<xml.XmlElement>()
          .firstWhere((e) => e.getAttribute('name') == 'arch');
      final viewRoot = arch.children.whereType<xml.XmlElement>().first;
      expect(viewRoot.name.local, 'form');
    });

    test('tree view has <tree> root in arch', () {
      final xmlStr = XmlGenerator.generateSingle(
          _partnerForm(type: ViewType.tree));
      expect(xmlStr, contains('<tree'));
    });

    test('kanban view has <kanban> root in arch', () {
      final xmlStr = XmlGenerator.generateSingle(
          _partnerForm(type: ViewType.kanban));
      expect(xmlStr, contains('<kanban'));
    });

    test('includes all top-level fields', () {
      final form = _partnerForm(fields: [
        OdooField.create(name: 'name', fieldType: OdooFieldType.char),
        OdooField.create(name: 'email', fieldType: OdooFieldType.char),
        OdooField.create(
            name: 'partner_id', fieldType: OdooFieldType.many2one),
      ]);
      final xmlStr = XmlGenerator.generateSingle(form);
      expect(xmlStr, contains('name="name"'));
      expect(xmlStr, contains('name="email"'));
      expect(xmlStr, contains('name="partner_id"'));
    });

    test('includes group with its fields', () {
      final group = OdooGroup.create(
        label: 'Address',
        fields: [
          OdooField.create(name: 'street', fieldType: OdooFieldType.char),
          OdooField.create(name: 'city', fieldType: OdooFieldType.char),
        ],
      );
      final form = _partnerForm(groups: <OdooGroup>[group]);
      final xmlStr = XmlGenerator.generateSingle(form);
      expect(xmlStr, contains('<group'));
      expect(xmlStr, contains('string="Address"'));
      expect(xmlStr, contains('name="street"'));
      expect(xmlStr, contains('name="city"'));
    });

    test('required field has required="1"', () {
      final form = _partnerForm(fields: [
        OdooField.create(
            name: 'name', fieldType: OdooFieldType.char, required: true),
      ]);
      expect(XmlGenerator.generateSingle(form), contains('required="1"'));
    });

    test('widget attribute is included', () {
      final form = _partnerForm(fields: [
        OdooField.create(
            name: 'email', fieldType: OdooFieldType.char, widget: 'email'),
      ]);
      expect(XmlGenerator.generateSingle(form), contains('widget="email"'));
    });
  });

  // ── generateFile() ────────────────────────────────────────────────────────

  group('XmlGenerator.generateFile()', () {
    test('returns well-formed XML for multiple views', () {
      final form = _partnerForm(type: ViewType.form, fields: [
        OdooField.create(name: 'name', fieldType: OdooFieldType.char),
      ]);
      final tree = _partnerForm(type: ViewType.tree, fields: [
        OdooField.create(name: 'name', fieldType: OdooFieldType.char),
      ]);
      final xmlStr = XmlGenerator.generateFile([form, tree]);
      expect(() => xml.XmlDocument.parse(xmlStr), returnsNormally);
    });

    test('contains both view records', () {
      final views = [
        _partnerForm(type: ViewType.form),
        _partnerForm(type: ViewType.tree),
      ];
      final xmlStr = XmlGenerator.generateFile(views);
      final doc = xml.XmlDocument.parse(xmlStr);
      final records = doc.descendants
          .whereType<xml.XmlElement>()
          .where((e) =>
              e.name.local == 'record' &&
              e.getAttribute('model') == 'ir.ui.view')
          .toList();
      expect(records.length, 2);
    });

    test('includes module name comment when provided', () {
      final xmlStr = XmlGenerator.generateFile(
        [_partnerForm()],
        moduleName: 'my_module',
      );
      expect(xmlStr, contains('my_module'));
    });

    test('handles empty view list', () {
      final xmlStr = XmlGenerator.generateFile([]);
      expect(() => xml.XmlDocument.parse(xmlStr), returnsNormally);
    });
  });

  // ── validateXml() ─────────────────────────────────────────────────────────

  group('XmlGenerator.validateXml()', () {
    test('returns true for well-formed XML', () {
      expect(
        XmlGenerator.validateXml('<root><child/></root>'),
        isTrue,
      );
    });

    test('returns false for malformed XML', () {
      expect(
        XmlGenerator.validateXml('<root><unclosed>'),
        isFalse,
      );
    });

    test('returns false for empty string', () {
      expect(XmlGenerator.validateXml(''), isFalse);
    });
  });
}
