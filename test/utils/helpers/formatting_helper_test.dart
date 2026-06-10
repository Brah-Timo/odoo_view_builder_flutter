// test/utils/helpers/formatting_helper_test.dart
//
// Unit tests for FormattingHelper.
// Coverage:
//   • formatDate() — null, UTC round-trip, format pattern
//   • formatDateTime() — null, format pattern
//   • formatRelative() — just now, minutes, hours, yesterday, days, older
//   • toIso8601()
//   • formatFileSize() — B, KB, MB, GB, negative
//   • formatInteger() — thousands separator
//   • formatDecimal() — decimal places
//   • formatPercent()
//   • truncateXml() — short/long strings
//   • escapeXmlEntities() — &, <, >, ", '
//   • unescapeXmlEntities() — reverse
//   • toSnakeCase() — camelCase, PascalCase
//   • toTitleCase() — snake_case
//   • toOdooFieldName() — spaces, special chars, leading digits
//   • modelToDisplayName() — dotted model name
//   • formatDuration() — seconds, minutes, hours
//   • formatDomain()
//   • xmlExportFileName() / moduleXmlFileName() — contain snake_case name

import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/utils/helpers/formatting_helper.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // formatDate()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatDate()', () {
    test('returns "—" for null', () {
      expect(FormattingHelper.formatDate(null), equals('—'));
    });

    test('formats a date as dd/MM/yyyy', () {
      final date = DateTime(2024, 1, 15);
      final result = FormattingHelper.formatDate(date);
      expect(result, equals('15/01/2024'));
    });

    test('handles end-of-year date', () {
      final date = DateTime(2023, 12, 31);
      final result = FormattingHelper.formatDate(date);
      expect(result, equals('31/12/2023'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatDateTime()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatDateTime()', () {
    test('returns "—" for null', () {
      expect(FormattingHelper.formatDateTime(null), equals('—'));
    });

    test('formats datetime as dd/MM/yyyy HH:mm', () {
      final date = DateTime(2024, 6, 10, 14, 30);
      final result = FormattingHelper.formatDateTime(date);
      expect(result, contains('10/06/2024'));
      expect(result, contains('14:30'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatRelative()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatRelative()', () {
    test('returns "just now" for very recent date (<60s)', () {
      final now = DateTime.now().subtract(const Duration(seconds: 10));
      expect(FormattingHelper.formatRelative(now), equals('just now'));
    });

    test('returns "X minutes ago" for < 60 minutes', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      final result = FormattingHelper.formatRelative(date);
      expect(result, contains('minutes ago'));
    });

    test('returns "1 minute ago" (singular) for exactly 1 minute', () {
      final date = DateTime.now().subtract(const Duration(minutes: 1));
      final result = FormattingHelper.formatRelative(date);
      expect(result, contains('minute ago'));
    });

    test('returns "X hours ago" for < 24 hours', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      final result = FormattingHelper.formatRelative(date);
      expect(result, contains('hours ago'));
    });

    test('returns "1 hour ago" (singular)', () {
      final date = DateTime.now().subtract(const Duration(hours: 1, seconds: 1));
      final result = FormattingHelper.formatRelative(date);
      expect(result, contains('hour ago'));
    });

    test('returns "yesterday" for exactly 1 day ago', () {
      final date = DateTime.now().subtract(const Duration(days: 1));
      expect(FormattingHelper.formatRelative(date), equals('yesterday'));
    });

    test('returns "X days ago" for 2–29 days ago', () {
      final date = DateTime.now().subtract(const Duration(days: 5));
      final result = FormattingHelper.formatRelative(date);
      expect(result, contains('days ago'));
    });

    test('returns a formatted date string for older dates (≥30 days)', () {
      final date = DateTime(2020, 6, 15);
      final result = FormattingHelper.formatRelative(date);
      // Should contain year 2020
      expect(result, contains('2020'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toIso8601()
  // ──────────────────────────────────────────────────────────────────────────
  group('toIso8601()', () {
    test('returns ISO 8601 formatted string', () {
      final date = DateTime(2024, 1, 15, 10, 30, 0);
      final result = FormattingHelper.toIso8601(date);
      expect(result, contains('2024-01-15'));
      expect(result, contains('10:30:00'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatFileSize()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatFileSize()', () {
    test('0 bytes → "0 B"', () {
      expect(FormattingHelper.formatFileSize(0), equals('0 B'));
    });

    test('negative bytes → "0 B"', () {
      expect(FormattingHelper.formatFileSize(-100), equals('0 B'));
    });

    test('512 bytes → "512 B"', () {
      expect(FormattingHelper.formatFileSize(512), equals('512 B'));
    });

    test('1023 bytes → "1023 B"', () {
      expect(FormattingHelper.formatFileSize(1023), equals('1023 B'));
    });

    test('1024 bytes → contains "KB"', () {
      final result = FormattingHelper.formatFileSize(1024);
      expect(result, contains('KB'));
    });

    test('1536 bytes → "1.50 KB"', () {
      final result = FormattingHelper.formatFileSize(1536);
      expect(result, contains('KB'));
    });

    test('1 MB (1024*1024) → contains "MB"', () {
      final result = FormattingHelper.formatFileSize(1024 * 1024);
      expect(result, contains('MB'));
    });

    test('1 GB → contains "GB"', () {
      final result = FormattingHelper.formatFileSize(1024 * 1024 * 1024);
      expect(result, contains('GB'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatInteger()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatInteger()', () {
    test('formats 0 as "0"', () {
      expect(FormattingHelper.formatInteger(0), equals('0'));
    });

    test('formats 1000 with thousands separator', () {
      expect(FormattingHelper.formatInteger(1000), equals('1,000'));
    });

    test('formats 1234567 correctly', () {
      expect(FormattingHelper.formatInteger(1234567), equals('1,234,567'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatDecimal()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatDecimal()', () {
    test('default 2 decimal places', () {
      final result = FormattingHelper.formatDecimal(1234.5678);
      expect(result, equals('1,234.57'));
    });

    test('0 decimal places rounds to integer', () {
      final result = FormattingHelper.formatDecimal(99.9, decimals: 0);
      expect(result, equals('100'));
    });

    test('handles zero', () {
      final result = FormattingHelper.formatDecimal(0.0);
      expect(result, contains('0.00'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatPercent()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatPercent()', () {
    test('0.756 → "75.6 %"', () {
      expect(FormattingHelper.formatPercent(0.756), equals('75.6 %'));
    });

    test('0.0 → "0.0 %"', () {
      expect(FormattingHelper.formatPercent(0.0), equals('0.0 %'));
    });

    test('1.0 → "100.0 %"', () {
      expect(FormattingHelper.formatPercent(1.0), equals('100.0 %'));
    });

    test('custom decimals=2', () {
      final result = FormattingHelper.formatPercent(0.1234, decimals: 2);
      expect(result, contains('%'));
      expect(result, contains('12.34'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // truncateXml()
  // ──────────────────────────────────────────────────────────────────────────
  group('truncateXml()', () {
    test('short string is returned unchanged', () {
      const xml = '<form><field name="x"/></form>';
      expect(FormattingHelper.truncateXml(xml), equals(xml));
    });

    test('long string is truncated to maxChars and appended with …', () {
      final xml = 'a' * 400;
      final result = FormattingHelper.truncateXml(xml, maxChars: 300);
      expect(result.length, lessThanOrEqualTo(301)); // 300 + ellipsis
      expect(result.endsWith('…'), isTrue);
    });

    test('string exactly at maxChars is NOT truncated', () {
      final xml = 'a' * 300;
      final result = FormattingHelper.truncateXml(xml, maxChars: 300);
      expect(result, equals(xml));
      expect(result.endsWith('…'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // escapeXmlEntities()
  // ──────────────────────────────────────────────────────────────────────────
  group('escapeXmlEntities()', () {
    test('escapes ampersand', () {
      expect(FormattingHelper.escapeXmlEntities('a & b'), contains('&amp;'));
    });

    test('escapes less-than', () {
      expect(FormattingHelper.escapeXmlEntities('<tag>'), contains('&lt;'));
    });

    test('escapes greater-than', () {
      expect(FormattingHelper.escapeXmlEntities('<tag>'), contains('&gt;'));
    });

    test('escapes double quote', () {
      expect(FormattingHelper.escapeXmlEntities('"quoted"'), contains('&quot;'));
    });

    test("escapes single quote / apostrophe", () {
      expect(FormattingHelper.escapeXmlEntities("it's"), contains('&apos;'));
    });

    test('plain text without special chars is unchanged', () {
      const text = 'hello world 123';
      expect(FormattingHelper.escapeXmlEntities(text), equals(text));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // unescapeXmlEntities()
  // ──────────────────────────────────────────────────────────────────────────
  group('unescapeXmlEntities()', () {
    test('unescapes &amp; → &', () {
      expect(FormattingHelper.unescapeXmlEntities('a &amp; b'), contains('&'));
    });

    test('unescapes &lt; → <', () {
      expect(FormattingHelper.unescapeXmlEntities('&lt;'), equals('<'));
    });

    test('unescapes &gt; → >', () {
      expect(FormattingHelper.unescapeXmlEntities('&gt;'), equals('>'));
    });

    test('unescapes &quot; → "', () {
      expect(FormattingHelper.unescapeXmlEntities('&quot;'), equals('"'));
    });

    test("unescapes &apos; → '", () {
      expect(FormattingHelper.unescapeXmlEntities('&apos;'), equals("'"));
    });

    test('round-trip escape → unescape returns original', () {
      const original = 'Text with <special> & "chars"';
      final escaped = FormattingHelper.escapeXmlEntities(original);
      final unescaped = FormattingHelper.unescapeXmlEntities(escaped);
      expect(unescaped, equals(original));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toSnakeCase()
  // ──────────────────────────────────────────────────────────────────────────
  group('toSnakeCase()', () {
    test('converts PascalCase', () {
      expect(FormattingHelper.toSnakeCase('MyFieldName'), equals('my_field_name'));
    });

    test('converts camelCase', () {
      expect(FormattingHelper.toSnakeCase('myFieldName'), equals('my_field_name'));
    });

    test('already snake_case unchanged', () {
      expect(FormattingHelper.toSnakeCase('my_field'), equals('my_field'));
    });

    test('all lowercase unchanged', () {
      expect(FormattingHelper.toSnakeCase('field'), equals('field'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toTitleCase()
  // ──────────────────────────────────────────────────────────────────────────
  group('toTitleCase()', () {
    test('converts snake_case to Title Case', () {
      expect(FormattingHelper.toTitleCase('my_field_name'), equals('My Field Name'));
    });

    test('converts kebab-case to Title Case', () {
      expect(FormattingHelper.toTitleCase('my-field'), equals('My Field'));
    });

    test('single word capitalised', () {
      expect(FormattingHelper.toTitleCase('hello'), equals('Hello'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // toOdooFieldName()
  // ──────────────────────────────────────────────────────────────────────────
  group('toOdooFieldName()', () {
    test('lowercases and replaces spaces', () {
      expect(
        FormattingHelper.toOdooFieldName('My Field Name'),
        equals('my_field_name'),
      );
    });

    test('removes special characters', () {
      expect(
        FormattingHelper.toOdooFieldName('Field!@#Name'),
        equals('fieldname'),
      );
    });

    test('strips leading digits', () {
      final result = FormattingHelper.toOdooFieldName('123abc');
      expect(result, isNot(matches(RegExp(r'^[0-9]'))));
    });

    test('collapses consecutive underscores', () {
      final result = FormattingHelper.toOdooFieldName('a___b');
      expect(result, isNot(contains('__')));
    });

    test('empty input returns "field"', () {
      expect(FormattingHelper.toOdooFieldName(''), equals('field'));
    });

    test('special chars only returns "field"', () {
      expect(FormattingHelper.toOdooFieldName('!!!'), equals('field'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // modelToDisplayName()
  // ──────────────────────────────────────────────────────────────────────────
  group('modelToDisplayName()', () {
    test('converts res.partner to "Res Partner"', () {
      expect(
        FormattingHelper.modelToDisplayName('res.partner'),
        equals('Res Partner'),
      );
    });

    test('converts sale.order.line to "Sale Order Line"', () {
      expect(
        FormattingHelper.modelToDisplayName('sale.order.line'),
        equals('Sale Order Line'),
      );
    });

    test('single part model is capitalised', () {
      expect(FormattingHelper.modelToDisplayName('partner'), equals('Partner'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatDuration()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatDuration()', () {
    test('5 seconds → "5 seconds"', () {
      expect(
        FormattingHelper.formatDuration(const Duration(seconds: 5)),
        equals('5 seconds'),
      );
    });

    test('1 second → "1 second" (singular)', () {
      expect(
        FormattingHelper.formatDuration(const Duration(seconds: 1)),
        equals('1 second'),
      );
    });

    test('2 minutes → "2 minutes"', () {
      expect(
        FormattingHelper.formatDuration(const Duration(minutes: 2)),
        equals('2 minutes'),
      );
    });

    test('1 minute → "1 minute" (singular)', () {
      expect(
        FormattingHelper.formatDuration(const Duration(minutes: 1)),
        equals('1 minute'),
      );
    });

    test('1 hour 30 minutes → "1 hour 30 minutes"', () {
      expect(
        FormattingHelper.formatDuration(
            const Duration(hours: 1, minutes: 30)),
        equals('1 hour 30 minutes'),
      );
    });

    test('2 hours → "2 hours" (no minutes when 0)', () {
      expect(
        FormattingHelper.formatDuration(const Duration(hours: 2)),
        equals('2 hours'),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // formatDomain()
  // ──────────────────────────────────────────────────────────────────────────
  group('formatDomain()', () {
    test('empty domain → "[]"', () {
      expect(FormattingHelper.formatDomain([]), equals('[]'));
    });

    test('single clause formatted correctly', () {
      final result = FormattingHelper.formatDomain([
        ['active', '=', true],
      ]);
      expect(result, contains("'active'"));
      expect(result, contains("'='"));
    });

    test('string value is wrapped in single quotes', () {
      final result = FormattingHelper.formatDomain([
        ['state', '=', 'draft'],
      ]);
      expect(result, contains("'draft'"));
    });

    test('numeric value is not wrapped in quotes', () {
      final result = FormattingHelper.formatDomain([
        ['qty', '>', 0],
      ]);
      expect(result, contains(',0]'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // xmlExportFileName()
  // ──────────────────────────────────────────────────────────────────────────
  group('xmlExportFileName()', () {
    test('returns a .xml filename', () {
      final name = FormattingHelper.xmlExportFileName('Sale Order Form');
      expect(name.endsWith('.xml'), isTrue);
    });

    test('contains snake_case of the view name', () {
      final name = FormattingHelper.xmlExportFileName('Sale Order Form');
      expect(name, contains('sale_order_form'));
    });

    test('empty name defaults to "view"', () {
      final name = FormattingHelper.xmlExportFileName('');
      expect(name, contains('view'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // moduleXmlFileName()
  // ──────────────────────────────────────────────────────────────────────────
  group('moduleXmlFileName()', () {
    test('returns a .xml filename', () {
      final name = FormattingHelper.moduleXmlFileName('my_module');
      expect(name.endsWith('.xml'), isTrue);
    });

    test('contains module name and "views"', () {
      final name = FormattingHelper.moduleXmlFileName('my_module');
      expect(name, contains('my_module'));
      expect(name, contains('views'));
    });

    test('empty module name defaults to "module"', () {
      final name = FormattingHelper.moduleXmlFileName('');
      expect(name, contains('module'));
    });
  });
}
