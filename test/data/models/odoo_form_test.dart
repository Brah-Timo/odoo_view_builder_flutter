// test/data/models/odoo_form_test.dart
//
// Unit tests for OdooForm (OdooView) and ViewType.

import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_form.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_group.dart';

void main() {
  group('ViewType', () {
    test('fromString() maps known values', () {
      expect(ViewType.fromString('form'), ViewType.form);
      expect(ViewType.fromString('tree'), ViewType.tree);
      expect(ViewType.fromString('kanban'), ViewType.kanban);
    });

    test('fromString() falls back to form for unknown values', () {
      expect(ViewType.fromString('unknown'), ViewType.form);
      expect(ViewType.fromString(''), ViewType.form);
    });

    test('each type has a non-empty value and label', () {
      for (final vt in ViewType.values) {
        expect(vt.value, isNotEmpty);
        expect(vt.label, isNotEmpty);
      }
    });
  });

  group('OdooForm.create()', () {
    test('creates form with default id when none provided', () {
      final form = OdooForm.create(
        name: 'Test Form',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[],
      );
      expect(form.id, isNotEmpty);
      expect(form.name, 'Test Form');
      expect(form.model, 'res.partner');
      expect(form.viewType, ViewType.form);
    });

    test('uses provided id when given', () {
      final form = OdooForm.create(
        id: 'my_module.view_partner_form',
        name: 'Partner Form',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[],
      );
      expect(form.id, 'my_module.view_partner_form');
    });
  });

  group('OdooForm.copyWith()', () {
    late OdooForm baseForm;

    setUp(() {
      baseForm = OdooForm.create(
        name: 'Base Form',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[],
      );
    });

    test('updates name while preserving other fields', () {
      final updated = baseForm.copyWith(name: 'Updated Form');
      expect(updated.name, 'Updated Form');
      expect(updated.model, baseForm.model);
      expect(updated.viewType, baseForm.viewType);
      expect(updated.id, baseForm.id);
    });

    test('updates model', () {
      final updated = baseForm.copyWith(model: 'sale.order');
      expect(updated.model, 'sale.order');
    });

    test('updates viewType', () {
      final updated = baseForm.copyWith(viewType: ViewType.tree);
      expect(updated.viewType, ViewType.tree);
    });

    test('updates fields list', () {
      final field = OdooField.create(
          name: 'x_f', fieldType: OdooFieldType.char);
      final updated = baseForm.copyWith(fields: <OdooField>[field]);
      expect(updated.fields.length, 1);
      expect(updated.fields.first.name, 'x_f');
    });
  });

  group('OdooForm with fields and groups', () {
    test('stores fields correctly', () {
      final f1 = OdooField.create(name: 'name', fieldType: OdooFieldType.char);
      final f2 = OdooField.create(name: 'email', fieldType: OdooFieldType.char);
      final form = OdooForm.create(
        name: 'Test',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[f1, f2],
        groups: <OdooGroup>[],
      );
      expect(form.fields.length, 2);
      expect(form.fields[0].name, 'name');
      expect(form.fields[1].name, 'email');
    });

    test('stores groups correctly', () {
      final group = OdooGroup.create(
        label: 'Contact',
        fields: <OdooField>[
          OdooField.create(name: 'phone', fieldType: OdooFieldType.char),
        ],
      );
      final form = OdooForm.create(
        name: 'Test',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[group],
      );
      expect(form.groups.length, 1);
      expect(form.groups.first.label, 'Contact');
      expect(form.groups.first.fields.length, 1);
    });
  });

  group('OdooForm.generateXml()', () {
    test('returns non-empty XML string', () {
      final form = OdooForm.create(
        name: 'Test',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[
          OdooField.create(name: 'name', fieldType: OdooFieldType.char),
        ],
        groups: <OdooGroup>[],
      );
      final xml = form.generateXml();
      expect(xml, isNotEmpty);
      expect(xml, contains('<form'));
      expect(xml, contains('res.partner'));
      expect(xml, contains('name="name"'));
    });

    test('tree view generates <tree> root element', () {
      final form = OdooForm.create(
        name: 'Tree',
        model: 'res.partner',
        viewType: ViewType.tree,
        fields: <OdooField>[
          OdooField.create(name: 'name', fieldType: OdooFieldType.char),
        ],
        groups: <OdooGroup>[],
      );
      final xml = form.generateXml();
      expect(xml, contains('<tree'));
    });

    test('kanban view generates <kanban> root element', () {
      final form = OdooForm.create(
        name: 'Kanban',
        model: 'res.partner',
        viewType: ViewType.kanban,
        fields: <OdooField>[
          OdooField.create(name: 'name', fieldType: OdooFieldType.char),
        ],
        groups: <OdooGroup>[],
      );
      final xml = form.generateXml();
      expect(xml, contains('<kanban'));
    });

    test('contains XML declaration', () {
      final form = OdooForm.create(
        name: 'Test',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[],
      );
      expect(form.generateXml(), contains('<?xml version='));
    });

    test('contains ir.ui.view record wrapper', () {
      final form = OdooForm.create(
        name: 'Test',
        model: 'res.partner',
        viewType: ViewType.form,
        fields: <OdooField>[],
        groups: <OdooGroup>[],
      );
      final xml = form.generateXml();
      expect(xml, contains('model="ir.ui.view"'));
      expect(xml, contains('<field name="arch" type="xml">'));
    });
  });
}
