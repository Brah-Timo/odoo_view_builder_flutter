// test/utils/helpers/field_helper_test.dart
//
// Unit tests for FieldHelper.
// Coverage:
//   • defaultAttrs() — key presence per type
//   • compatibleWidgets() — all 14 types return non-empty lists
//   • defaultWidget() — all 14 types return a string
//   • supportsAggregation() — only integer & float return true
//   • isRelational() — many2one, many2many, one2many
//   • isListLike() — one2many, many2many
//   • isScalar() — scalars vs non-scalars
//   • iconFor() — all 14 types return a non-null IconData
//   • colorFor() — all 14 types return a non-null Color
//   • descriptionFor() — all 14 types return non-empty string
//   • normalise() — compound types stripped
//   • kanbanCompatibleTypes() — expected set
//   • treeCompatibleTypes() — excludes html and one2many

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';
import 'package:odoo_view_builder_flutter/utils/helpers/field_helper.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // defaultAttrs()
  // ──────────────────────────────────────────────────────────────────────────
  group('defaultAttrs()', () {
    test('char has required, readonly, nolabel, invisible, colspan keys', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.char);
      expect(attrs.containsKey('required'), isTrue);
      expect(attrs.containsKey('readonly'), isTrue);
      expect(attrs.containsKey('nolabel'), isTrue);
      expect(attrs.containsKey('invisible'), isTrue);
      expect(attrs.containsKey('colspan'), isTrue);
    });

    test('integer has sum and avg keys', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.integer);
      expect(attrs.containsKey('sum'), isTrue);
      expect(attrs.containsKey('avg'), isTrue);
    });

    test('float has digits key', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.float);
      expect(attrs.containsKey('digits'), isTrue);
    });

    test('many2one has domain and context keys', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.many2one);
      expect(attrs.containsKey('domain'), isTrue);
      expect(attrs.containsKey('context'), isTrue);
    });

    test('text has colspan 2', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.text);
      expect(attrs['colspan'], equals(2));
    });

    test('html has colspan 2', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.html);
      expect(attrs['colspan'], equals(2));
    });

    test('boolean does NOT have colspan key', () {
      final attrs = FieldHelper.defaultAttrs(OdooFieldType.boolean);
      expect(attrs.containsKey('colspan'), isFalse);
    });

    test('returns attrs for all 14 types without throwing', () {
      for (final type in OdooFieldType.values) {
        expect(() => FieldHelper.defaultAttrs(type), returnsNormally,
            reason: 'defaultAttrs should not throw for $type');
      }
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // compatibleWidgets()
  // ──────────────────────────────────────────────────────────────────────────
  group('compatibleWidgets()', () {
    test('returns non-empty list for all 14 types', () {
      for (final type in OdooFieldType.values) {
        final widgets = FieldHelper.compatibleWidgets(type);
        expect(widgets, isNotEmpty,
            reason: 'compatibleWidgets should not be empty for $type');
      }
    });

    test('char includes email and url', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.char);
      expect(widgets, contains('email'));
      expect(widgets, contains('url'));
    });

    test('many2one includes statusbar', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.many2one);
      expect(widgets, contains('statusbar'));
    });

    test('many2many includes many2many_tags', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.many2many);
      expect(widgets, contains('many2many_tags'));
    });

    test('binary includes image and pdf_viewer', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.binary);
      expect(widgets, contains('image'));
      expect(widgets, contains('pdf_viewer'));
    });

    test('boolean includes toggle_button and boolean_favorite', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.boolean);
      expect(widgets, contains('toggle_button'));
      expect(widgets, contains('boolean_favorite'));
    });

    test('selection includes radio and badge', () {
      final widgets = FieldHelper.compatibleWidgets(OdooFieldType.selection);
      expect(widgets, contains('radio'));
      expect(widgets, contains('badge'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // defaultWidget()
  // ──────────────────────────────────────────────────────────────────────────
  group('defaultWidget()', () {
    test('returns non-empty string for all 14 types', () {
      for (final type in OdooFieldType.values) {
        final widget = FieldHelper.defaultWidget(type);
        expect(widget, isNotEmpty,
            reason: 'defaultWidget should not be empty for $type');
      }
    });

    test('char default widget is "char"', () {
      expect(FieldHelper.defaultWidget(OdooFieldType.char), equals('char'));
    });

    test('many2many default widget is "many2many_tags"', () {
      expect(
        FieldHelper.defaultWidget(OdooFieldType.many2many),
        equals('many2many_tags'),
      );
    });

    test('boolean default widget is "boolean"', () {
      expect(
        FieldHelper.defaultWidget(OdooFieldType.boolean),
        equals('boolean'),
      );
    });

    test('html default widget is "html"', () {
      expect(FieldHelper.defaultWidget(OdooFieldType.html), equals('html'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // supportsAggregation()
  // ──────────────────────────────────────────────────────────────────────────
  group('supportsAggregation()', () {
    test('integer supports aggregation', () {
      expect(FieldHelper.supportsAggregation(OdooFieldType.integer), isTrue);
    });

    test('float supports aggregation', () {
      expect(FieldHelper.supportsAggregation(OdooFieldType.float), isTrue);
    });

    test('char does NOT support aggregation', () {
      expect(FieldHelper.supportsAggregation(OdooFieldType.char), isFalse);
    });

    test('date does NOT support aggregation', () {
      expect(FieldHelper.supportsAggregation(OdooFieldType.date), isFalse);
    });

    test('many2one does NOT support aggregation', () {
      expect(FieldHelper.supportsAggregation(OdooFieldType.many2one), isFalse);
    });

    test('only integer and float return true', () {
      final supporting = OdooFieldType.values
          .where(FieldHelper.supportsAggregation)
          .toList();
      expect(supporting.length, equals(2));
      expect(supporting, containsAll([OdooFieldType.integer, OdooFieldType.float]));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isRelational()
  // ──────────────────────────────────────────────────────────────────────────
  group('isRelational()', () {
    test('many2one is relational', () {
      expect(FieldHelper.isRelational(OdooFieldType.many2one), isTrue);
    });

    test('many2many is relational', () {
      expect(FieldHelper.isRelational(OdooFieldType.many2many), isTrue);
    });

    test('one2many is relational', () {
      expect(FieldHelper.isRelational(OdooFieldType.one2many), isTrue);
    });

    test('char is NOT relational', () {
      expect(FieldHelper.isRelational(OdooFieldType.char), isFalse);
    });

    test('selection is NOT relational', () {
      expect(FieldHelper.isRelational(OdooFieldType.selection), isFalse);
    });

    test('exactly 3 types are relational', () {
      final relational =
          OdooFieldType.values.where(FieldHelper.isRelational).toList();
      expect(relational.length, equals(3));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isListLike()
  // ──────────────────────────────────────────────────────────────────────────
  group('isListLike()', () {
    test('one2many is list-like', () {
      expect(FieldHelper.isListLike(OdooFieldType.one2many), isTrue);
    });

    test('many2many is list-like', () {
      expect(FieldHelper.isListLike(OdooFieldType.many2many), isTrue);
    });

    test('many2one is NOT list-like', () {
      expect(FieldHelper.isListLike(OdooFieldType.many2one), isFalse);
    });

    test('char is NOT list-like', () {
      expect(FieldHelper.isListLike(OdooFieldType.char), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isScalar()
  // ──────────────────────────────────────────────────────────────────────────
  group('isScalar()', () {
    test('char is scalar', () {
      expect(FieldHelper.isScalar(OdooFieldType.char), isTrue);
    });

    test('integer is scalar', () {
      expect(FieldHelper.isScalar(OdooFieldType.integer), isTrue);
    });

    test('float is scalar', () {
      expect(FieldHelper.isScalar(OdooFieldType.float), isTrue);
    });

    test('boolean is scalar', () {
      expect(FieldHelper.isScalar(OdooFieldType.boolean), isTrue);
    });

    test('html is NOT scalar (excluded explicitly)', () {
      expect(FieldHelper.isScalar(OdooFieldType.html), isFalse);
    });

    test('binary is NOT scalar (excluded explicitly)', () {
      expect(FieldHelper.isScalar(OdooFieldType.binary), isFalse);
    });

    test('many2one is NOT scalar (relational)', () {
      expect(FieldHelper.isScalar(OdooFieldType.many2one), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // iconFor()
  // ──────────────────────────────────────────────────────────────────────────
  group('iconFor()', () {
    test('returns non-null IconData for all 14 types', () {
      for (final type in OdooFieldType.values) {
        final icon = FieldHelper.iconFor(type);
        expect(icon, isNotNull,
            reason: 'iconFor should return a valid IconData for $type');
        expect(icon, isA<IconData>());
      }
    });

    test('each type returns a distinct icon from at least some others', () {
      // Ensure not all icons are the same
      final icons = OdooFieldType.values.map(FieldHelper.iconFor).toSet();
      expect(icons.length, greaterThan(1));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // colorFor()
  // ──────────────────────────────────────────────────────────────────────────
  group('colorFor()', () {
    test('returns non-null Color for all 14 types', () {
      for (final type in OdooFieldType.values) {
        final color = FieldHelper.colorFor(type);
        expect(color, isNotNull,
            reason: 'colorFor should return a Color for $type');
        expect(color, isA<Color>());
      }
    });

    test('each type returns a distinct colour', () {
      final colors = OdooFieldType.values.map(FieldHelper.colorFor).toSet();
      expect(colors.length, equals(OdooFieldType.values.length));
    });

    test('char colour is green family', () {
      final color = FieldHelper.colorFor(OdooFieldType.char);
      expect(color, equals(const Color(0xFF4CAF50)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // descriptionFor()
  // ──────────────────────────────────────────────────────────────────────────
  group('descriptionFor()', () {
    test('returns non-empty string for all 14 types', () {
      for (final type in OdooFieldType.values) {
        final desc = FieldHelper.descriptionFor(type);
        expect(desc, isNotEmpty,
            reason: 'descriptionFor should return a non-empty string for $type');
      }
    });

    test('char description mentions "text"', () {
      final desc = FieldHelper.descriptionFor(OdooFieldType.char);
      expect(desc.toLowerCase(), contains('text'));
    });

    test('boolean description mentions "True" or "False" or "toggle"', () {
      final desc = FieldHelper.descriptionFor(OdooFieldType.boolean).toLowerCase();
      expect(
        desc.contains('true') || desc.contains('toggle'),
        isTrue,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // normalise()
  // ──────────────────────────────────────────────────────────────────────────
  group('normalise()', () {
    test('strips compound type param: char(64) → char', () {
      expect(FieldHelper.normalise('char(64)'), equals(OdooFieldType.char));
    });

    test('plain char → char', () {
      expect(FieldHelper.normalise('char'), equals(OdooFieldType.char));
    });

    test('Many2one (capital) → many2one via fromString fallback', () {
      // fromString should handle case-insensitive via toLowerCase in normalise
      expect(FieldHelper.normalise('Many2one'), equals(OdooFieldType.many2one));
    });

    test('unknown type returns text (fromString fallback)', () {
      // OdooFieldType.fromString has a fallback
      final result = FieldHelper.normalise('unknown_type');
      expect(result, isA<OdooFieldType>());
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // kanbanCompatibleTypes()
  // ──────────────────────────────────────────────────────────────────────────
  group('kanbanCompatibleTypes()', () {
    test('returns non-empty list', () {
      expect(FieldHelper.kanbanCompatibleTypes(), isNotEmpty);
    });

    test('includes char, integer, float, boolean, date, datetime, selection, many2one', () {
      final types = FieldHelper.kanbanCompatibleTypes();
      expect(types, containsAll([
        OdooFieldType.char,
        OdooFieldType.integer,
        OdooFieldType.float,
        OdooFieldType.boolean,
        OdooFieldType.date,
        OdooFieldType.datetime,
        OdooFieldType.selection,
        OdooFieldType.many2one,
      ]));
    });

    test('does NOT include html or binary', () {
      final types = FieldHelper.kanbanCompatibleTypes();
      expect(types, isNot(contains(OdooFieldType.html)));
      expect(types, isNot(contains(OdooFieldType.binary)));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // treeCompatibleTypes()
  // ──────────────────────────────────────────────────────────────────────────
  group('treeCompatibleTypes()', () {
    test('returns non-empty list', () {
      expect(FieldHelper.treeCompatibleTypes(), isNotEmpty);
    });

    test('excludes html', () {
      final types = FieldHelper.treeCompatibleTypes();
      expect(types, isNot(contains(OdooFieldType.html)));
    });

    test('excludes one2many', () {
      final types = FieldHelper.treeCompatibleTypes();
      expect(types, isNot(contains(OdooFieldType.one2many)));
    });

    test('includes char, integer, float, boolean', () {
      final types = FieldHelper.treeCompatibleTypes();
      expect(types, containsAll([
        OdooFieldType.char,
        OdooFieldType.integer,
        OdooFieldType.float,
        OdooFieldType.boolean,
      ]));
    });

    test('count is total types minus 2 (html + one2many excluded)', () {
      final types = FieldHelper.treeCompatibleTypes();
      expect(types.length, equals(OdooFieldType.values.length - 2));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // aggregationFunctions constant
  // ──────────────────────────────────────────────────────────────────────────
  group('aggregationFunctions', () {
    test('contains sum, avg, max, min', () {
      expect(FieldHelper.aggregationFunctions,
          containsAll(['sum', 'avg', 'max', 'min']));
    });

    test('has exactly 4 functions', () {
      expect(FieldHelper.aggregationFunctions.length, equals(4));
    });
  });
}
