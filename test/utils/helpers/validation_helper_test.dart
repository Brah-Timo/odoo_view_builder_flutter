// test/utils/helpers/validation_helper_test.dart
//
// Unit tests for ValidationHelper and ValidationResult.
// Coverage:
//   • requiredNonEmpty()
//   • maxLength() / minLength()
//   • odooModelName() — valid, invalid patterns
//   • odooFieldName() — valid, invalid, reserved
//   • externalId()
//   • integer() / positiveInteger() / integerRange()
//   • httpUrl() / odooBaseUrl()
//   • validateField() — OdooField level
//   • validateForm() — OdooForm level (tree w/o fields, empty form)
//   • compose()
//   • ValidationResult factory constructors

import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_form.dart';
import 'package:odoo_view_builder_flutter/utils/helpers/validation_helper.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // ValidationResult
  // ──────────────────────────────────────────────────────────────────────────
  group('ValidationResult', () {
    test('pass() sets isValid = true', () {
      final result = ValidationResult.pass();
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('pass() with warnings keeps isValid = true', () {
      final result = ValidationResult.pass(warnings: ['a warning']);
      expect(result.isValid, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('fail() with errors sets isValid = false', () {
      final result = ValidationResult.fail(['an error']);
      expect(result.isValid, isFalse);
      expect(result.errors, contains('an error'));
    });

    test('fail() with warnings preserves them', () {
      final result = ValidationResult.fail(['error'], warnings: ['warn']);
      expect(result.warnings, contains('warn'));
    });

    test('toString shows pass/fail state', () {
      final pass = ValidationResult.pass();
      expect(pass.toString(), contains('pass'));

      final fail = ValidationResult.fail(['bad']);
      expect(fail.toString(), contains('fail'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // requiredNonEmpty()
  // ──────────────────────────────────────────────────────────────────────────
  group('requiredNonEmpty()', () {
    test('null value returns error', () {
      expect(ValidationHelper.requiredNonEmpty(null), isNotNull);
    });

    test('empty string returns error', () {
      expect(ValidationHelper.requiredNonEmpty(''), isNotNull);
    });

    test('whitespace-only returns error', () {
      expect(ValidationHelper.requiredNonEmpty('   '), isNotNull);
    });

    test('non-empty string returns null', () {
      expect(ValidationHelper.requiredNonEmpty('hello'), isNull);
    });

    test('custom label appears in error message', () {
      final msg = ValidationHelper.requiredNonEmpty('', label: 'Model name');
      expect(msg, contains('Model name'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // maxLength()
  // ──────────────────────────────────────────────────────────────────────────
  group('maxLength()', () {
    test('null value passes (optional field)', () {
      expect(ValidationHelper.maxLength(null, 10), isNull);
    });

    test('value within limit passes', () {
      expect(ValidationHelper.maxLength('hello', 10), isNull);
    });

    test('value exactly at limit passes', () {
      expect(ValidationHelper.maxLength('12345', 5), isNull);
    });

    test('value exceeding limit returns error', () {
      expect(ValidationHelper.maxLength('1234567', 5), isNotNull);
    });

    test('error message includes max and current length', () {
      final msg = ValidationHelper.maxLength('1234567', 5);
      expect(msg, contains('5'));
      expect(msg, contains('7'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // minLength()
  // ──────────────────────────────────────────────────────────────────────────
  group('minLength()', () {
    test('null value fails (must be at least min chars)', () {
      expect(ValidationHelper.minLength(null, 3), isNotNull);
    });

    test('value meeting min length passes', () {
      expect(ValidationHelper.minLength('abc', 3), isNull);
    });

    test('value below min length returns error', () {
      expect(ValidationHelper.minLength('ab', 3), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // odooModelName()
  // ──────────────────────────────────────────────────────────────────────────
  group('odooModelName()', () {
    test('null returns error', () {
      expect(ValidationHelper.odooModelName(null), isNotNull);
    });

    test('empty string returns error', () {
      expect(ValidationHelper.odooModelName(''), isNotNull);
    });

    test('valid "res.partner" passes', () {
      expect(ValidationHelper.odooModelName('res.partner'), isNull);
    });

    test('valid "sale.order.line" passes', () {
      expect(ValidationHelper.odooModelName('sale.order.line'), isNull);
    });

    test('PascalCase "ResPartner" fails', () {
      expect(ValidationHelper.odooModelName('ResPartner'), isNotNull);
    });

    test('no-dot single word fails', () {
      expect(ValidationHelper.odooModelName('partner'), isNotNull);
    });

    test('starts with dot fails', () {
      expect(ValidationHelper.odooModelName('.partner'), isNotNull);
    });

    test('ends with dot fails', () {
      expect(ValidationHelper.odooModelName('res.'), isNotNull);
    });

    test('spaces fail', () {
      expect(ValidationHelper.odooModelName('res partner'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // odooFieldName()
  // ──────────────────────────────────────────────────────────────────────────
  group('odooFieldName()', () {
    test('null returns error', () {
      expect(ValidationHelper.odooFieldName(null), isNotNull);
    });

    test('empty string returns error', () {
      expect(ValidationHelper.odooFieldName(''), isNotNull);
    });

    test('valid "x_custom_field" passes', () {
      expect(ValidationHelper.odooFieldName('x_custom_field'), isNull);
    });

    test('valid "_field" (underscore start) passes', () {
      expect(ValidationHelper.odooFieldName('_field'), isNull);
    });

    test('uppercase fails', () {
      expect(ValidationHelper.odooFieldName('MyField'), isNotNull);
    });

    test('starts with digit fails', () {
      expect(ValidationHelper.odooFieldName('1field'), isNotNull);
    });

    test('reserved name "id" returns error', () {
      expect(ValidationHelper.odooFieldName('id'), isNotNull);
    });

    test('reserved name "create_uid" returns error', () {
      expect(ValidationHelper.odooFieldName('create_uid'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // externalId()
  // ──────────────────────────────────────────────────────────────────────────
  group('externalId()', () {
    test('null returns error', () {
      expect(ValidationHelper.externalId(null), isNotNull);
    });

    test('empty returns error', () {
      expect(ValidationHelper.externalId(''), isNotNull);
    });

    test('plain "view_partner_form" passes', () {
      expect(ValidationHelper.externalId('view_partner_form'), isNull);
    });

    test('"my_module.view_partner_form" passes', () {
      expect(
        ValidationHelper.externalId('my_module.view_partner_form'),
        isNull,
      );
    });

    test('spaces fail', () {
      expect(ValidationHelper.externalId('my module.view'), isNotNull);
    });

    test('double dot fails', () {
      expect(ValidationHelper.externalId('mod..view'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // integer()
  // ──────────────────────────────────────────────────────────────────────────
  group('integer()', () {
    test('null passes (optional)', () {
      expect(ValidationHelper.integer(null), isNull);
    });

    test('empty passes (optional)', () {
      expect(ValidationHelper.integer(''), isNull);
    });

    test('"42" passes', () {
      expect(ValidationHelper.integer('42'), isNull);
    });

    test('"3.14" fails', () {
      expect(ValidationHelper.integer('3.14'), isNotNull);
    });

    test('"abc" fails', () {
      expect(ValidationHelper.integer('abc'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // positiveInteger()
  // ──────────────────────────────────────────────────────────────────────────
  group('positiveInteger()', () {
    test('"1" passes', () {
      expect(ValidationHelper.positiveInteger('1'), isNull);
    });

    test('"0" fails (must be > 0)', () {
      expect(ValidationHelper.positiveInteger('0'), isNotNull);
    });

    test('negative fails', () {
      expect(ValidationHelper.positiveInteger('-5'), isNotNull);
    });

    test('null passes (optional)', () {
      expect(ValidationHelper.positiveInteger(null), isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // integerRange()
  // ──────────────────────────────────────────────────────────────────────────
  group('integerRange()', () {
    test('value in range passes', () {
      expect(
        ValidationHelper.integerRange('5', min: 1, max: 12),
        isNull,
      );
    });

    test('value at lower bound passes', () {
      expect(
        ValidationHelper.integerRange('1', min: 1, max: 12),
        isNull,
      );
    });

    test('value at upper bound passes', () {
      expect(
        ValidationHelper.integerRange('12', min: 1, max: 12),
        isNull,
      );
    });

    test('value below range fails', () {
      expect(
        ValidationHelper.integerRange('0', min: 1, max: 12),
        isNotNull,
      );
    });

    test('value above range fails', () {
      expect(
        ValidationHelper.integerRange('13', min: 1, max: 12),
        isNotNull,
      );
    });

    test('null passes (optional)', () {
      expect(
        ValidationHelper.integerRange(null, min: 1, max: 12),
        isNull,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // httpUrl()
  // ──────────────────────────────────────────────────────────────────────────
  group('httpUrl()', () {
    test('null returns error', () {
      expect(ValidationHelper.httpUrl(null), isNotNull);
    });

    test('"https://odoo.example.com" passes', () {
      expect(ValidationHelper.httpUrl('https://odoo.example.com'), isNull);
    });

    test('"http://localhost:8069" passes', () {
      expect(ValidationHelper.httpUrl('http://localhost:8069'), isNull);
    });

    test('plain "example.com" without scheme fails', () {
      expect(ValidationHelper.httpUrl('example.com'), isNotNull);
    });

    test('"ftp://host" fails (not http/https)', () {
      expect(ValidationHelper.httpUrl('ftp://host'), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // odooBaseUrl()
  // ──────────────────────────────────────────────────────────────────────────
  group('odooBaseUrl()', () {
    test('valid URL without trailing slash passes', () {
      expect(
        ValidationHelper.odooBaseUrl('https://odoo.example.com'),
        isNull,
      );
    });

    test('valid URL with trailing slash passes (stripped internally)', () {
      expect(
        ValidationHelper.odooBaseUrl('https://odoo.example.com/'),
        isNull,
      );
    });

    test('null returns error', () {
      expect(ValidationHelper.odooBaseUrl(null), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // validateField()
  // ──────────────────────────────────────────────────────────────────────────
  group('validateField()', () {
    test('valid char field passes', () {
      final field = OdooField.create(
        name: 'x_custom_name',
        fieldType: OdooFieldType.char,
        label: 'Custom Name',
      );
      final result = ValidationHelper.validateField(field);
      expect(result.isValid, isTrue);
    });

    test('invalid field name returns error', () {
      final field = OdooField.create(
        name: 'id', // reserved
        fieldType: OdooFieldType.char,
        label: 'ID',
      );
      final result = ValidationHelper.validateField(field);
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('colspan out of range (0) returns error', () {
      final field = OdooField.create(
        name: 'x_name',
        fieldType: OdooFieldType.char,
        label: 'Name',
      ).copyWith(colspan: 0);
      final result = ValidationHelper.validateField(field);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Colspan')), isTrue);
    });

    test('colspan out of range (13) returns error', () {
      final field = OdooField.create(
        name: 'x_note',
        fieldType: OdooFieldType.text,
        label: 'Note',
      ).copyWith(colspan: 13);
      final result = ValidationHelper.validateField(field);
      expect(result.isValid, isFalse);
    });

    test('many2one without comodel produces warning', () {
      final field = OdooField.create(
        name: 'x_partner_id',
        fieldType: OdooFieldType.many2one,
        label: 'Partner',
      );
      final result = ValidationHelper.validateField(field);
      expect(result.isValid, isTrue); // warnings don't block
      expect(result.warnings, isNotEmpty);
    });

    test('one2many without relation_field produces warning', () {
      final field = OdooField.create(
        name: 'x_line_ids',
        fieldType: OdooFieldType.one2many,
        label: 'Lines',
      ).copyWith(comodel: 'sale.order.line');
      final result = ValidationHelper.validateField(field);
      expect(result.warnings.any((w) => w.contains('relation_field')), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // validateForm()
  // ──────────────────────────────────────────────────────────────────────────
  group('validateForm()', () {
    test('valid form with fields passes', () {
      final field = OdooField.create(
        name: 'x_name',
        fieldType: OdooFieldType.char,
        label: 'Name',
      );
      final form = OdooForm.create(
        name: 'test.form',
        model: 'res.partner',
        viewType: ViewType.form,
      ).copyWith(fields: [field]);
      final result = ValidationHelper.validateForm(form);
      expect(result.isValid, isTrue);
    });

    test('form with empty name returns error', () {
      final form = OdooForm.create(
        name: '',
        model: 'res.partner',
        viewType: ViewType.form,
      );
      final result = ValidationHelper.validateForm(form);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('name')), isTrue);
    });

    test('form with invalid model name returns error', () {
      final form = OdooForm.create(
        name: 'my.form',
        model: 'InvalidModel', // no dots, PascalCase
        viewType: ViewType.form,
      );
      final result = ValidationHelper.validateForm(form);
      expect(result.isValid, isFalse);
    });

    test('form with no fields produces warning', () {
      final form = OdooForm.create(
        name: 'my.form',
        model: 'res.partner',
        viewType: ViewType.form,
      );
      final result = ValidationHelper.validateForm(form);
      // No fields → warning, but may still be valid depending on model/name
      expect(result.warnings, isNotEmpty);
    });

    test('tree view with no fields returns error', () {
      final form = OdooForm.create(
        name: 'res.partner.tree',
        model: 'res.partner',
        viewType: ViewType.tree,
      );
      final result = ValidationHelper.validateForm(form);
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.contains('Tree view')),
        isTrue,
      );
    });

    test('tree view WITH fields passes', () {
      final field = OdooField.create(
        name: 'x_name',
        fieldType: OdooFieldType.char,
        label: 'Name',
      );
      final form = OdooForm.create(
        name: 'res.partner.tree',
        model: 'res.partner',
        viewType: ViewType.tree,
      ).copyWith(fields: [field]);
      final result = ValidationHelper.validateForm(form);
      expect(result.isValid, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // compose()
  // ──────────────────────────────────────────────────────────────────────────
  group('compose()', () {
    test('returns null when all validators pass', () {
      final result = ValidationHelper.compose(
        'res.partner',
        [
          (v) => ValidationHelper.requiredNonEmpty(v),
          (v) => ValidationHelper.odooModelName(v),
        ],
      );
      expect(result, isNull);
    });

    test('returns first error from chained validators', () {
      final result = ValidationHelper.compose(
        '',
        [
          (v) => ValidationHelper.requiredNonEmpty(v, label: 'Model'),
          (v) => ValidationHelper.odooModelName(v),
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('Model')); // first validator's message
    });

    test('returns second error if first passes but second fails', () {
      final result = ValidationHelper.compose(
        'InvalidModel', // not empty, but fails odooModelName
        [
          (v) => ValidationHelper.requiredNonEmpty(v),
          (v) => ValidationHelper.odooModelName(v),
        ],
      );
      expect(result, isNotNull);
      expect(result, contains('lowercase'));
    });
  });
}
