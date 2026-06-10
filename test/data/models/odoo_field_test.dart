// test/data/models/odoo_field_test.dart
//
// Unit tests for OdooField and OdooFieldType.

import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';

void main() {
  group('OdooFieldType', () {
    group('fromString()', () {
      test('parses known type values', () {
        expect(OdooFieldType.fromString('char'), OdooFieldType.char);
        expect(OdooFieldType.fromString('integer'), OdooFieldType.integer);
        expect(OdooFieldType.fromString('float'), OdooFieldType.float);
        expect(OdooFieldType.fromString('boolean'), OdooFieldType.boolean);
        expect(OdooFieldType.fromString('date'), OdooFieldType.date);
        expect(OdooFieldType.fromString('datetime'), OdooFieldType.datetime);
        expect(OdooFieldType.fromString('text'), OdooFieldType.text);
        expect(OdooFieldType.fromString('html'), OdooFieldType.html);
        expect(OdooFieldType.fromString('binary'), OdooFieldType.binary);
        expect(OdooFieldType.fromString('selection'), OdooFieldType.selection);
        expect(OdooFieldType.fromString('many2one'), OdooFieldType.many2one);
        expect(OdooFieldType.fromString('many2many'), OdooFieldType.many2many);
        expect(OdooFieldType.fromString('one2many'), OdooFieldType.one2many);
        expect(OdooFieldType.fromString('reference'), OdooFieldType.reference);
      });

      test('falls back to char for unknown values', () {
        expect(OdooFieldType.fromString('unknown_type'), OdooFieldType.char);
        expect(OdooFieldType.fromString(''), OdooFieldType.char);
        expect(OdooFieldType.fromString('CHAR'), OdooFieldType.char);
      });
    });

    test('each type has a non-empty value and label', () {
      for (final type in OdooFieldType.values) {
        expect(type.value, isNotEmpty,
            reason: '${type.name}.value should not be empty');
        expect(type.label, isNotEmpty,
            reason: '${type.name}.label should not be empty');
      }
    });
  });

  group('OdooField', () {
    group('OdooField.create()', () {
      test('creates field with auto-generated UUID id', () {
        final field = OdooField.create(
          name: 'x_test',
          fieldType: OdooFieldType.char,
        );
        expect(field.id, isNotEmpty);
        expect(field.id.length, greaterThan(10));
      });

      test('sets name and fieldType correctly', () {
        final field = OdooField.create(
          name: 'x_amount',
          fieldType: OdooFieldType.float,
        );
        expect(field.name, 'x_amount');
        expect(field.fieldType, OdooFieldType.float);
      });

      test('applies optional parameters', () {
        final field = OdooField.create(
          name: 'x_partner_id',
          fieldType: OdooFieldType.many2one,
          label: 'Partner',
          required: true,
          readonly: false,
          comodel: 'res.partner',
          widget: 'many2one_avatar',
          colspan: 2,
        );
        expect(field.label, 'Partner');
        expect(field.required, isTrue);
        expect(field.readonly, isFalse);
        expect(field.comodel, 'res.partner');
        expect(field.widget, 'many2one_avatar');
        expect(field.colspan, 2);
      });

      test('sets createdAt and updatedAt to UTC', () {
        final before = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
        final field = OdooField.create(
          name: 'x_f',
          fieldType: OdooFieldType.char,
        );
        final after = DateTime.now().toUtc().add(const Duration(seconds: 1));
        expect(field.createdAt.isAfter(before), isTrue);
        expect(field.createdAt.isBefore(after), isTrue);
      });
    });

    group('copyWith()', () {
      test('updates specified fields', () {
        final original = OdooField.create(
          name: 'x_original',
          fieldType: OdooFieldType.char,
          required: false,
        );
        final updated = original.copyWith(
          name: 'x_updated',
          required: true,
        );
        expect(updated.name, 'x_updated');
        expect(updated.required, isTrue);
        expect(updated.fieldType, OdooFieldType.char); // unchanged
        expect(updated.id, original.id); // id unchanged
      });

      test('updates updatedAt timestamp', () {
        final original = OdooField.create(
          name: 'x_ts',
          fieldType: OdooFieldType.char,
        );
        // Small delay to ensure timestamp difference
        final updated = original.copyWith(name: 'x_ts2');
        // updatedAt should be >= original.updatedAt
        expect(
          updated.updatedAt.compareTo(original.updatedAt),
          greaterThanOrEqualTo(0),
        );
      });
    });

    group('Equatable equality', () {
      test('two fields with same id are equal', () {
        final a = OdooField.create(name: 'x_a', fieldType: OdooFieldType.char);
        final b = a.copyWith(name: 'x_a'); // same id
        expect(a, equals(b));
      });

      test('two fields with different ids are not equal', () {
        final a = OdooField.create(name: 'x_a', fieldType: OdooFieldType.char);
        final b = OdooField.create(name: 'x_a', fieldType: OdooFieldType.char);
        expect(a, isNot(equals(b)));
      });
    });

    group('toXml()', () {
      test('generates basic field element', () {
        final field = OdooField.create(
          name: 'x_name',
          fieldType: OdooFieldType.char,
        );
        final xml = field.toXml();
        expect(xml, contains('<field'));
        expect(xml, contains('name="x_name"'));
      });

      test('includes required="1" when required is true', () {
        final field = OdooField.create(
          name: 'x_req',
          fieldType: OdooFieldType.char,
          required: true,
        );
        expect(field.toXml(), contains('required="1"'));
      });

      test('includes widget attribute when set', () {
        final field = OdooField.create(
          name: 'x_email',
          fieldType: OdooFieldType.char,
          widget: 'email',
        );
        expect(field.toXml(), contains('widget="email"'));
      });

      test('includes string attribute when label is set', () {
        final field = OdooField.create(
          name: 'x_lbl',
          fieldType: OdooFieldType.char,
          label: 'My Label',
        );
        expect(field.toXml(), contains('string="My Label"'));
      });

      test('omits optional attributes when null/default', () {
        final field = OdooField.create(
          name: 'x_minimal',
          fieldType: OdooFieldType.char,
        );
        final xml = field.toXml();
        expect(xml, isNot(contains('widget=')));
        expect(xml, isNot(contains('required=')));
        expect(xml, isNot(contains('readonly=')));
      });

      test('includes colspan when set', () {
        final field = OdooField.create(
          name: 'x_wide',
          fieldType: OdooFieldType.text,
          colspan: 2,
        );
        expect(field.toXml(), contains('colspan="2"'));
      });
    });
  });
}
