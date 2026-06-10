// test/utils/validators/field_name_validator_test.dart
//
// Unit tests for FieldNameValidator.
// Coverage targets:
//   • All 9 rules (FN001–FN009)
//   • isValid() convenience method
//   • firstError() convenience method
//   • autoFix() transformations

import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/utils/validators/field_name_validator.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // FN001 — empty / blank
  // ──────────────────────────────────────────────────────────────────────────
  group('FN001 — empty field name', () {
    test('empty string produces FN001 error', () {
      final result = FieldNameValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'FN001'), isTrue);
    });

    test('whitespace-only string produces FN001 error', () {
      final result = FieldNameValidator.validate('   ');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'FN001'), isTrue);
    });

    test('returns immediately with only FN001 on empty', () {
      final result = FieldNameValidator.validate('');
      expect(result.issues.length, equals(1));
      expect(result.issues.first.code, equals('FN001'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN002 — starts with digit
  // ──────────────────────────────────────────────────────────────────────────
  group('FN002 — starts with digit', () {
    test('field starting with digit triggers FN002', () {
      final result = FieldNameValidator.validate('1field');
      expect(result.errors.any((e) => e.code == 'FN002'), isTrue);
    });

    test('field starting with zero triggers FN002', () {
      final result = FieldNameValidator.validate('0abc');
      expect(result.errors.any((e) => e.code == 'FN002'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN003 — allowed characters
  // ──────────────────────────────────────────────────────────────────────────
  group('FN003 — invalid characters', () {
    test('uppercase letters trigger FN003', () {
      final result = FieldNameValidator.validate('MyField');
      expect(result.errors.any((e) => e.code == 'FN003'), isTrue);
    });

    test('spaces trigger FN003', () {
      final result = FieldNameValidator.validate('my field');
      expect(result.errors.any((e) => e.code == 'FN003'), isTrue);
    });

    test('hyphens trigger FN003', () {
      final result = FieldNameValidator.validate('my-field');
      expect(result.errors.any((e) => e.code == 'FN003'), isTrue);
    });

    test('dots trigger FN003', () {
      final result = FieldNameValidator.validate('my.field');
      expect(result.errors.any((e) => e.code == 'FN003'), isTrue);
    });

    test('valid lowercase with digits and underscores does not trigger FN003', () {
      final result = FieldNameValidator.validate('x_my_field_01');
      expect(result.errors.any((e) => e.code == 'FN003'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN004 — max length 63
  // ──────────────────────────────────────────────────────────────────────────
  group('FN004 — max length', () {
    test('63-char name does not trigger FN004', () {
      final name = 'x_${'a' * 61}'; // x_ + 61 = 63
      expect(name.length, equals(63));
      final result = FieldNameValidator.validate(name);
      expect(result.errors.any((e) => e.code == 'FN004'), isFalse);
    });

    test('64-char name triggers FN004', () {
      final name = 'x_${'a' * 62}'; // 64 chars
      expect(name.length, equals(64));
      final result = FieldNameValidator.validate(name);
      expect(result.errors.any((e) => e.code == 'FN004'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN005 — reserved ORM field names
  // ──────────────────────────────────────────────────────────────────────────
  group('FN005 — reserved ORM fields', () {
    final reserved = [
      'id',
      'create_uid',
      'create_date',
      'write_uid',
      'write_date',
      'display_name',
    ];

    for (final name in reserved) {
      test('reserved name "$name" triggers FN005', () {
        final result = FieldNameValidator.validate(name);
        expect(result.errors.any((e) => e.code == 'FN005'), isTrue,
            reason: '$name should be flagged as reserved ORM field');
      });
    }

    test('non-reserved name does not trigger FN005', () {
      final result = FieldNameValidator.validate('x_custom_field');
      expect(result.errors.any((e) => e.code == 'FN005'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN006 — dunder pattern
  // ──────────────────────────────────────────────────────────────────────────
  group('FN006 — dunder (double underscore) pattern', () {
    test('__dunder__ triggers FN006 warning', () {
      final result = FieldNameValidator.validate('__myfield__');
      expect(result.warnings.any((w) => w.code == 'FN006'), isTrue);
    });

    test('regular name starting with _ does not trigger FN006', () {
      final result = FieldNameValidator.validate('_single_under');
      expect(result.warnings.any((w) => w.code == 'FN006'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN007 — SQL keyword clash
  // ──────────────────────────────────────────────────────────────────────────
  group('FN007 — SQL reserved words', () {
    final sqlKeywords = ['select', 'from', 'where', 'order', 'group', 'view'];

    for (final kw in sqlKeywords) {
      test('SQL keyword "$kw" triggers FN007 warning', () {
        final result = FieldNameValidator.validate(kw);
        expect(result.warnings.any((w) => w.code == 'FN007'), isTrue,
            reason: '"$kw" should be flagged as SQL keyword');
      });
    }

    test('non-SQL word does not trigger FN007', () {
      final result = FieldNameValidator.validate('x_my_value');
      expect(result.warnings.any((w) => w.code == 'FN007'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN008 — common Odoo field names
  // ──────────────────────────────────────────────────────────────────────────
  group('FN008 — common Odoo field names', () {
    final commonNames = [
      'name',
      'active',
      'state',
      'company_id',
      'user_id',
      'date',
    ];

    for (final nm in commonNames) {
      test('common Odoo field "$nm" triggers FN008 warning', () {
        final result = FieldNameValidator.validate(nm);
        expect(result.warnings.any((w) => w.code == 'FN008'), isTrue,
            reason: '"$nm" should trigger FN008');
      });
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FN009 — missing x_ prefix
  // ──────────────────────────────────────────────────────────────────────────
  group('FN009 — missing x_ prefix on custom fields', () {
    test('name without x_ prefix triggers FN009 warning', () {
      final result = FieldNameValidator.validate('my_custom_field');
      expect(result.warnings.any((w) => w.code == 'FN009'), isTrue);
    });

    test('name WITH x_ prefix does NOT trigger FN009', () {
      final result = FieldNameValidator.validate('x_my_custom_field');
      expect(result.warnings.any((w) => w.code == 'FN009'), isFalse);
    });

    test('name starting with _ does NOT trigger FN009', () {
      final result = FieldNameValidator.validate('_internal');
      expect(result.warnings.any((w) => w.code == 'FN009'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Valid names — should have NO errors
  // ──────────────────────────────────────────────────────────────────────────
  group('valid field names — no errors', () {
    final validNames = [
      'x_custom_field',
      'x_partner_id',
      'x_amount_total',
      'x_is_active',
      'x_date_start',
      'x_int_qty',
      'name',
      'state',
      'active',
    ];

    for (final nm in validNames) {
      test('"$nm" has no errors', () {
        final result = FieldNameValidator.validate(nm);
        expect(result.errors, isEmpty,
            reason: '"$nm" should produce no errors');
      });
    }
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isValid() convenience
  // ──────────────────────────────────────────────────────────────────────────
  group('isValid()', () {
    test('returns true for x_ prefixed valid name', () {
      expect(FieldNameValidator.isValid('x_my_field'), isTrue);
    });

    test('returns false for empty string', () {
      expect(FieldNameValidator.isValid(''), isFalse);
    });

    test('returns false for reserved ORM field', () {
      expect(FieldNameValidator.isValid('id'), isFalse);
    });

    test('returns false for name with uppercase', () {
      expect(FieldNameValidator.isValid('MyField'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // firstError() convenience
  // ──────────────────────────────────────────────────────────────────────────
  group('firstError()', () {
    test('returns null for valid name', () {
      expect(FieldNameValidator.firstError('x_valid_name'), isNull);
    });

    test('returns error message for null input', () {
      expect(FieldNameValidator.firstError(null), isNotNull);
      expect(FieldNameValidator.firstError(null), contains('required'));
    });

    test('returns error message for empty string', () {
      final msg = FieldNameValidator.firstError('');
      expect(msg, isNotNull);
    });

    test('returns error message for reserved name', () {
      final msg = FieldNameValidator.firstError('id');
      expect(msg, isNotNull);
      expect(msg, contains('reserved'));
    });

    test('is suitable as TextFormField validator (returns String?)', () {
      // Verify the signature matches what Flutter expects
      String? Function(String?) fn = FieldNameValidator.firstError;
      expect(fn('x_valid'), isNull);
      expect(fn(''), isNotNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // autoFix()
  // ──────────────────────────────────────────────────────────────────────────
  group('autoFix()', () {
    test('lowercases input', () {
      expect(FieldNameValidator.autoFix('MyField'), contains('myfield'));
    });

    test('replaces spaces with underscores', () {
      final result = FieldNameValidator.autoFix('my field name');
      expect(result, isNot(contains(' ')));
    });

    test('replaces dashes with underscores', () {
      final result = FieldNameValidator.autoFix('my-field');
      expect(result, isNot(contains('-')));
    });

    test('strips leading digits', () {
      final result = FieldNameValidator.autoFix('123field');
      expect(result, isNot(matches(RegExp(r'^[0-9]'))));
    });

    test('collapses consecutive underscores', () {
      final result = FieldNameValidator.autoFix('my___field');
      expect(result, isNot(contains('__')));
    });

    test('adds x_ prefix for non-standard names', () {
      final result = FieldNameValidator.autoFix('custom_field');
      expect(result.startsWith('x_'), isTrue);
    });

    test('does not add x_ prefix for common Odoo fields', () {
      // 'name' is in _commonOdooFields, so no x_ added
      final result = FieldNameValidator.autoFix('name');
      expect(result, equals('name'));
    });

    test('empty input returns x_field fallback', () {
      final result = FieldNameValidator.autoFix('');
      expect(result, isNotEmpty);
    });

    test('returns empty string for completely invalid input → x_field', () {
      final result = FieldNameValidator.autoFix('!!!');
      expect(result, isNotEmpty);
    });

    test('enforces max length 63', () {
      final longInput = 'a' * 100;
      final result = FieldNameValidator.autoFix(longInput);
      expect(result.length, lessThanOrEqualTo(63));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FieldNameValidationIssue properties
  // ──────────────────────────────────────────────────────────────────────────
  group('FieldNameValidationIssue', () {
    test('isError is true for error severity', () {
      final issue = FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN001',
        message: 'test',
      );
      expect(issue.isError, isTrue);
      expect(issue.isWarning, isFalse);
    });

    test('isWarning is true for warning severity', () {
      final issue = FieldNameValidationIssue(
        severity: IssueSeverity.warning,
        code: 'FN009',
        message: 'test warning',
      );
      expect(issue.isWarning, isTrue);
      expect(issue.isError, isFalse);
    });

    test('toString includes severity, code and message', () {
      final issue = FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN001',
        message: 'Must not be empty',
      );
      final str = issue.toString();
      expect(str, contains('ERROR'));
      expect(str, contains('FN001'));
      expect(str, contains('Must not be empty'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FieldNameValidationResult
  // ──────────────────────────────────────────────────────────────────────────
  group('FieldNameValidationResult', () {
    test('isValid is true when all issues are warnings', () {
      final result = FieldNameValidator.validate('name'); // triggers FN008 warning
      expect(result.isValid, isTrue);
      expect(result.warnings, isNotEmpty);
    });

    test('isValid is false when there is at least one error', () {
      final result = FieldNameValidator.validate('id'); // reserved ORM → error
      expect(result.isValid, isFalse);
    });

    test('errors and warnings are properly split', () {
      final result = FieldNameValidator.validate('MyField');
      // FN003 (uppercase → error) + FN009 (no x_ → warning)
      expect(result.errors, isNotEmpty);
    });

    test('toString contains valid flag and issue count', () {
      final result = FieldNameValidator.validate('x_ok_field');
      final str = result.toString();
      expect(str, contains('valid='));
      expect(str, contains('issues='));
    });
  });
}
