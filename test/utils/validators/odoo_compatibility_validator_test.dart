// test/utils/validators/odoo_compatibility_validator_test.dart
//
// Unit tests for OdooCompatibilityValidator.
// Coverage:
//   • OdooVersion enum parsing
//   • OC001 — tree view renamed to list in Odoo 17+
//   • OC002 — empty kanban view before Odoo 17
//   • OC003 — `attrs` removed in Odoo 17
//   • OC004 — `states` removed in Odoo 17
//   • OC005 — aggregation on non-numeric fields
//   • OC006 — relational fields in tree
//   • OC007 — HTML fields in tree
//   • OC008 — relational fields missing comodel
//   • OC012 — OWL chatter info (Odoo 17+ forms)
//   • OC013 — sheet wrapper info (Odoo 14 forms)
//   • isCompatible / validateField

import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/data/models/odoo_field.dart';
import 'package:odoo_view_builder_flutter/data/models/odoo_form.dart';
import 'package:odoo_view_builder_flutter/utils/validators/odoo_compatibility_validator.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

OdooField _field({
  String name = 'x_test',
  OdooFieldType type = OdooFieldType.char,
  String? widget,
  String? comodel,
  String? attrs,
  Map<String, String> extraAttrs = const {},
  String? sum,
}) =>
    OdooField.create(
      name: name,
      fieldType: type,
      label: 'Test Field',
    ).copyWith(
      widget: widget,
      comodel: comodel,
      attrs: attrs,
      extraAttrs: extraAttrs,
      sum: sum,
    );

OdooForm _form({
  ViewType viewType = ViewType.form,
  List<OdooField> fields = const [],
  bool editableTree = false,
}) =>
    OdooForm.create(
      name: 'test.view',
      model: 'res.partner',
      viewType: viewType,
    ).copyWith(
      fields: fields,
      editableTree: editableTree,
    );

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // OdooVersion enum
  // ──────────────────────────────────────────────────────────────────────────
  group('OdooVersion', () {
    test('fromString("14.0") returns v14', () {
      expect(OdooVersion.fromString('14.0'), equals(OdooVersion.v14));
    });

    test('fromString("15.0") returns v15', () {
      expect(OdooVersion.fromString('15.0'), equals(OdooVersion.v15));
    });

    test('fromString("16.0") returns v16', () {
      expect(OdooVersion.fromString('16.0'), equals(OdooVersion.v16));
    });

    test('fromString("17.0") returns v17', () {
      expect(OdooVersion.fromString('17.0'), equals(OdooVersion.v17));
    });

    test('fromString("18.0") returns v18', () {
      expect(OdooVersion.fromString('18.0'), equals(OdooVersion.v18));
    });

    test('fromString with unknown version returns v17 (default)', () {
      expect(OdooVersion.fromString('99.0'), equals(OdooVersion.v17));
    });

    test('major values are correct', () {
      expect(OdooVersion.v14.major, equals(14));
      expect(OdooVersion.v17.major, equals(17));
    });

    test('label values are correct', () {
      expect(OdooVersion.v16.label, equals('16.0'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC001 — tree view in Odoo 17+
  // ──────────────────────────────────────────────────────────────────────────
  group('OC001 — tree view renamed to list in Odoo 17+', () {
    test('editable tree in Odoo 17 triggers OC001 info', () {
      final form = _form(viewType: ViewType.tree, editableTree: true);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.infos.any((i) => i.code == 'OC001'), isTrue);
    });

    test('editable tree in Odoo 16 does NOT trigger OC001', () {
      final form = _form(viewType: ViewType.tree, editableTree: true);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.infos.any((i) => i.code == 'OC001'), isFalse);
    });

    test('non-editable tree in Odoo 17 does NOT trigger OC001', () {
      final form = _form(
        viewType: ViewType.tree,
        editableTree: false,
        fields: [_field(name: 'name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.infos.any((i) => i.code == 'OC001'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC002 — empty kanban before Odoo 17
  // ──────────────────────────────────────────────────────────────────────────
  group('OC002 — empty kanban view before Odoo 17', () {
    test('empty kanban in Odoo 16 triggers OC002 warning', () {
      final form = _form(viewType: ViewType.kanban);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.warnings.any((w) => w.code == 'OC002'), isTrue);
    });

    test('kanban with fields in Odoo 16 does NOT trigger OC002', () {
      final form = _form(
        viewType: ViewType.kanban,
        fields: [_field(name: 'name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.warnings.any((w) => w.code == 'OC002'), isFalse);
    });

    test('empty kanban in Odoo 17 does NOT trigger OC002', () {
      final form = _form(viewType: ViewType.kanban);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC002'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC003 — `attrs` removed in Odoo 17
  // ──────────────────────────────────────────────────────────────────────────
  group('OC003 — attrs removed in Odoo 17', () {
    test('field with attrs in Odoo 17 triggers OC003 error', () {
      final form = _form(
        fields: [
          _field(
            name: 'x_status',
            attrs: "{'invisible': [['state', '=', 'done']]}",
          ),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.errors.any((e) => e.code == 'OC003'), isTrue);
    });

    test('field with attrs in Odoo 16 does NOT trigger OC003', () {
      final form = _form(
        fields: [
          _field(
            name: 'x_status',
            attrs: "{'invisible': [['state', '=', 'done']]}",
          ),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.errors.any((e) => e.code == 'OC003'), isFalse);
    });

    test('field without attrs does NOT trigger OC003', () {
      final form = _form(
        fields: [_field(name: 'x_name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.errors.any((e) => e.code == 'OC003'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC004 — `states` removed in Odoo 17
  // ──────────────────────────────────────────────────────────────────────────
  group('OC004 — states removed in Odoo 17', () {
    test('field with states extra attr in Odoo 17 triggers OC004', () {
      final form = _form(
        fields: [
          _field(
            name: 'x_desc',
            extraAttrs: {'states': "draft:invisible=1"},
          ),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.errors.any((e) => e.code == 'OC004'), isTrue);
    });

    test('field with states in Odoo 16 does NOT trigger OC004', () {
      final form = _form(
        fields: [
          _field(
            name: 'x_desc',
            extraAttrs: {'states': "draft:invisible=1"},
          ),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.errors.any((e) => e.code == 'OC004'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC005 — aggregation on non-numeric fields
  // ──────────────────────────────────────────────────────────────────────────
  group('OC005 — aggregation on non-numeric fields', () {
    test('sum on char field triggers OC005 warning', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [_field(name: 'x_name', type: OdooFieldType.char, sum: 'Total')],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC005'), isTrue);
    });

    test('sum on integer field does NOT trigger OC005', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [
          _field(name: 'x_qty', type: OdooFieldType.integer, sum: 'Total Qty'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC005'), isFalse);
    });

    test('sum on float field does NOT trigger OC005', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [
          _field(name: 'x_amount', type: OdooFieldType.float, sum: 'Total'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC005'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC006 — relational fields in tree
  // ──────────────────────────────────────────────────────────────────────────
  group('OC006 — relational fields in tree', () {
    test('one2many in tree triggers OC006 warning', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [
          _field(name: 'x_line_ids', type: OdooFieldType.one2many,
              comodel: 'sale.order.line'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC006'), isTrue);
    });

    test('many2many in tree triggers OC006 warning', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [
          _field(name: 'x_tag_ids', type: OdooFieldType.many2many,
              comodel: 'res.partner.category'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC006'), isTrue);
    });

    test('many2one in tree does NOT trigger OC006', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [
          _field(name: 'partner_id', type: OdooFieldType.many2one,
              comodel: 'res.partner'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC006'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC007 — HTML in tree
  // ──────────────────────────────────────────────────────────────────────────
  group('OC007 — HTML fields in tree columns', () {
    test('html field in tree triggers OC007 warning', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [_field(name: 'x_notes', type: OdooFieldType.html)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC007'), isTrue);
    });

    test('html field in form does NOT trigger OC007', () {
      final form = _form(
        viewType: ViewType.form,
        fields: [_field(name: 'x_notes', type: OdooFieldType.html)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC007'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC008 — relational missing comodel
  // ──────────────────────────────────────────────────────────────────────────
  group('OC008 — relational field missing comodel', () {
    test('many2one without comodel triggers OC008 warning', () {
      final form = _form(
        fields: [_field(name: 'x_partner_id', type: OdooFieldType.many2one)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC008'), isTrue);
    });

    test('many2one WITH comodel does NOT trigger OC008', () {
      final form = _form(
        fields: [
          _field(name: 'x_partner_id', type: OdooFieldType.many2one,
              comodel: 'res.partner'),
        ],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC008'), isFalse);
    });

    test('char field without comodel does NOT trigger OC008', () {
      final form = _form(
        fields: [_field(name: 'x_name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.warnings.any((w) => w.code == 'OC008'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC012 — OWL chatter info (Odoo 17+ form)
  // ──────────────────────────────────────────────────────────────────────────
  group('OC012 — OWL chatter info for Odoo 17+ forms', () {
    test('form view in Odoo 17 includes OC012 info', () {
      final form = _form(viewType: ViewType.form);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.infos.any((i) => i.code == 'OC012'), isTrue);
    });

    test('form view in Odoo 16 does NOT include OC012', () {
      final form = _form(viewType: ViewType.form);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.infos.any((i) => i.code == 'OC012'), isFalse);
    });

    test('tree view in Odoo 17 does NOT include OC012', () {
      final form = _form(
        viewType: ViewType.tree,
        fields: [_field(name: 'name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.infos.any((i) => i.code == 'OC012'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // OC013 — sheet wrapper info (Odoo 14 forms)
  // ──────────────────────────────────────────────────────────────────────────
  group('OC013 — sheet wrapper info for Odoo 14 forms', () {
    test('form view in Odoo 14 includes OC013 info', () {
      final form = _form(viewType: ViewType.form);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v14,
      );
      expect(result.infos.any((i) => i.code == 'OC013'), isTrue);
    });

    test('form view in Odoo 17 does NOT include OC013', () {
      final form = _form(viewType: ViewType.form);
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      expect(result.infos.any((i) => i.code == 'OC013'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // validateField — single field
  // ──────────────────────────────────────────────────────────────────────────
  group('validateField()', () {
    test('clean char field has no issues', () {
      final field = _field(name: 'x_note', type: OdooFieldType.char);
      final result = OdooCompatibilityValidator.validateField(
        field,
        ViewType.form,
        target: OdooVersion.v17,
      );
      // OC012/OC013 are form-level checks, not per-field
      expect(result.errors, isEmpty);
    });

    test('field with attrs in Odoo 17 is an error', () {
      final field = _field(
        name: 'x_desc',
        attrs: "{'readonly': [['state', '!=', 'draft']]}",
      );
      final result = OdooCompatibilityValidator.validateField(
        field,
        ViewType.form,
        target: OdooVersion.v17,
      );
      expect(result.isCompatible, isFalse);
      expect(result.errors.any((e) => e.code == 'OC003'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // CompatibilityValidationResult
  // ──────────────────────────────────────────────────────────────────────────
  group('CompatibilityValidationResult', () {
    test('isCompatible is true when no errors', () {
      final form = _form(
        viewType: ViewType.form,
        fields: [_field(name: 'x_name', type: OdooFieldType.char)],
      );
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v16,
      );
      expect(result.isCompatible, isTrue);
    });

    test('targetVersion is preserved in result', () {
      final form = _form();
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v15,
      );
      expect(result.targetVersion, equals(OdooVersion.v15));
    });

    test('toString includes target version and compatibility flag', () {
      final form = _form();
      final result = OdooCompatibilityValidator.validateForm(
        form,
        target: OdooVersion.v17,
      );
      final str = result.toString();
      expect(str, contains('17.0'));
      expect(str, contains('compatible='));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // CompatibilityIssue
  // ──────────────────────────────────────────────────────────────────────────
  group('CompatibilityIssue', () {
    test('isError is true for error severity', () {
      const issue = CompatibilityIssue(
        severity: CompatSeverity.error,
        code: 'OC003',
        message: 'attrs removed',
      );
      expect(issue.isError, isTrue);
      expect(issue.isWarning, isFalse);
    });

    test('isWarning is true for warning severity', () {
      const issue = CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC006',
        message: 'relational in tree',
      );
      expect(issue.isWarning, isTrue);
      expect(issue.isError, isFalse);
    });

    test('toString includes suggestion when present', () {
      const issue = CompatibilityIssue(
        severity: CompatSeverity.error,
        code: 'OC003',
        message: 'attrs removed',
        suggestion: 'Use inline invisible',
      );
      expect(issue.toString(), contains('Suggestion:'));
      expect(issue.toString(), contains('Use inline invisible'));
    });

    test('toString does not include Suggestion when absent', () {
      const issue = CompatibilityIssue(
        severity: CompatSeverity.info,
        code: 'OC012',
        message: 'OWL chatter',
      );
      expect(issue.toString(), isNot(contains('Suggestion:')));
    });
  });
}
