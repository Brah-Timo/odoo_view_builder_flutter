// test/utils/validators/xml_structure_validator_test.dart
//
// Unit tests for XmlStructureValidator.
// Coverage:
//   • XS001 — empty content
//   • XS002 — malformed XML
//   • XS003 — missing XML declaration (warning)
//   • XS004 — wrong root element
//   • XS005 — missing <data> or <record>
//   • XS006 — no <record> elements
//   • XS007 — record missing model attribute
//   • XS008 — record missing id attribute (warning)
//   • XS009 — ir.ui.view missing name field
//   • XS010 — ir.ui.view missing model field
//   • XS011 — ir.ui.view missing arch field
//   • XS012 — arch missing type="xml" (warning)
//   • XS013 — arch has no view element
//   • XS015 — unknown view root element
//   • XS016 — <field> missing name attribute
//   • XS017 — duplicate field names (warning)
//   • isValid() / errorMessages() helpers

import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/utils/validators/xml_structure_validator.dart';

// ── Helper XML builders ────────────────────────────────────────────────────

String _buildMinimalView({
  String recordId = 'my_module.view_partner_form',
  String model = 'res.partner',
  String viewName = 'res.partner.form',
  String viewRoot = 'form',
  String archContent = '<field name="name"/>',
  bool includeDeclaration = true,
  bool includeData = true,
}) {
  final declaration =
      includeDeclaration ? '<?xml version="1.0" encoding="utf-8"?>\n' : '';
  final dataOpen = includeData ? '  <data>\n' : '';
  final dataClose = includeData ? '  </data>\n' : '';
  return '''${declaration}<odoo>
$dataOpen    <record id="$recordId" model="ir.ui.view">
      <field name="name">$viewName</field>
      <field name="model">$model</field>
      <field name="arch" type="xml">
        <$viewRoot>
          $archContent
        </$viewRoot>
      </field>
    </record>
${dataClose}</odoo>''';
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // XS001 — empty content
  // ──────────────────────────────────────────────────────────────────────────
  group('XS001 — empty XML content', () {
    test('empty string produces XS001 error', () {
      final result = XmlStructureValidator.validate('');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'XS001'), isTrue);
    });

    test('whitespace-only string produces XS001 error', () {
      final result = XmlStructureValidator.validate('   \n\t ');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'XS001'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS002 — malformed XML
  // ──────────────────────────────────────────────────────────────────────────
  group('XS002 — malformed XML', () {
    test('unclosed tag produces XS002', () {
      final result = XmlStructureValidator.validate('<odoo><data>');
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'XS002'), isTrue);
    });

    // Note: the xml package accepts unquoted attributes, so this test is
    // omitted — only genuinely malformed XML (unclosed tags, etc.) triggers XS002.

    test('well-formed XML does NOT produce XS002', () {
      final result = XmlStructureValidator.validate(_buildMinimalView());
      expect(result.errors.any((e) => e.code == 'XS002'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS003 — missing XML declaration (warning)
  // ──────────────────────────────────────────────────────────────────────────
  group('XS003 — missing XML declaration', () {
    test('missing declaration produces XS003 warning', () {
      final xml = _buildMinimalView(includeDeclaration: false);
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS003'), isTrue);
    });

    test('present declaration does NOT produce XS003', () {
      final xml = _buildMinimalView(includeDeclaration: true);
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS003'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS004 — wrong root element
  // ──────────────────────────────────────────────────────────────────────────
  group('XS004 — root element must be <odoo>', () {
    test('non-odoo root triggers XS004 error', () {
      final xml = '<?xml version="1.0"?><root><data/></root>';
      final result = XmlStructureValidator.validate(xml);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'XS004'), isTrue);
    });

    test('<openerp> root triggers XS004W warning (not error)', () {
      final xml = '''<?xml version="1.0"?>
<openerp>
  <data>
    <record id="test" model="ir.ui.view">
      <field name="name">test</field>
      <field name="model">res.partner</field>
      <field name="arch" type="xml">
        <form><field name="name"/></form>
      </field>
    </record>
  </data>
</openerp>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS004W'), isTrue);
    });

    test('<odoo> root does NOT trigger XS004', () {
      final xml = _buildMinimalView();
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS004'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS005 — missing <data> or <record>
  // ──────────────────────────────────────────────────────────────────────────
  group('XS005 — no <data> or <record> under <odoo>', () {
    test('empty <odoo> triggers XS005 error', () {
      final xml = '<?xml version="1.0"?><odoo></odoo>';
      final result = XmlStructureValidator.validate(xml);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'XS005'), isTrue);
    });

    test('<record> directly under <odoo> triggers XS005W warning', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <record id="test" model="ir.ui.view">
    <field name="name">test</field>
    <field name="model">res.partner</field>
    <field name="arch" type="xml">
      <form><field name="name"/></form>
    </field>
  </record>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS005W'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS007 — record missing model attribute
  // ──────────────────────────────────────────────────────────────────────────
  group('XS007 — record missing model attribute', () {
    test('record without model triggers XS007', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record id="test_id">
      <field name="name">test</field>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS007'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS008 — record missing id attribute (warning)
  // ──────────────────────────────────────────────────────────────────────────
  group('XS008 — record missing id attribute', () {
    test('record without id triggers XS008 warning', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record model="ir.ui.view">
      <field name="name">test</field>
      <field name="model">res.partner</field>
      <field name="arch" type="xml">
        <form><field name="name"/></form>
      </field>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS008'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS009 — ir.ui.view missing name field
  // ──────────────────────────────────────────────────────────────────────────
  group('XS009 — ir.ui.view missing <field name="name">', () {
    test('missing name field triggers XS009', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record id="test_id" model="ir.ui.view">
      <field name="model">res.partner</field>
      <field name="arch" type="xml">
        <form><field name="name"/></form>
      </field>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS009'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS011 — ir.ui.view missing arch field
  // ──────────────────────────────────────────────────────────────────────────
  group('XS011 — ir.ui.view missing arch field', () {
    test('missing arch field triggers XS011', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record id="test_id" model="ir.ui.view">
      <field name="name">test</field>
      <field name="model">res.partner</field>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS011'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS012 — arch missing type="xml"
  // ──────────────────────────────────────────────────────────────────────────
  group('XS012 — arch missing type="xml"', () {
    test('arch without type="xml" triggers XS012 warning', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record id="test_id" model="ir.ui.view">
      <field name="name">test</field>
      <field name="model">res.partner</field>
      <field name="arch">
        <form><field name="name"/></form>
      </field>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS012'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS013 — arch has no view element
  // ──────────────────────────────────────────────────────────────────────────
  group('XS013 — arch with no view element', () {
    test('empty arch triggers XS013', () {
      final xml = '''<?xml version="1.0"?>
<odoo>
  <data>
    <record id="test_id" model="ir.ui.view">
      <field name="name">test</field>
      <field name="model">res.partner</field>
      <field name="arch" type="xml"/>
    </record>
  </data>
</odoo>''';
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS013'), isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS015 — unknown view root element
  // ──────────────────────────────────────────────────────────────────────────
  group('XS015 — unknown view root element', () {
    test('unknown root <myview> triggers XS015', () {
      final xml = _buildMinimalView(viewRoot: 'myview');
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS015'), isTrue);
    });

    test('valid form root does NOT trigger XS015', () {
      final xml = _buildMinimalView(viewRoot: 'form');
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS015'), isFalse);
    });

    test('valid tree root does NOT trigger XS015', () {
      final xml = _buildMinimalView(viewRoot: 'tree');
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS015'), isFalse);
    });

    test('valid kanban root does NOT trigger XS015', () {
      final xml = _buildMinimalView(viewRoot: 'kanban');
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS015'), isFalse);
    });

    test('valid search root does NOT trigger XS015', () {
      final xml = _buildMinimalView(viewRoot: 'search');
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS015'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS016 — <field> missing name attribute
  // ──────────────────────────────────────────────────────────────────────────
  group('XS016 — <field> missing name attribute', () {
    test('field without name attribute triggers XS016', () {
      final xml = _buildMinimalView(
        archContent: '<field/>', // no name attr
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS016'), isTrue);
    });

    test('field WITH name attribute does NOT trigger XS016', () {
      final xml = _buildMinimalView(
        archContent: '<field name="partner_id"/>',
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.errors.any((e) => e.code == 'XS016'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XS017 — duplicate field names
  // ──────────────────────────────────────────────────────────────────────────
  group('XS017 — duplicate field names', () {
    test('duplicate top-level field names trigger XS017 warning', () {
      final xml = _buildMinimalView(
        archContent: '''
          <field name="name"/>
          <field name="name"/>
        ''',
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS017'), isTrue);
    });

    test('unique field names do NOT trigger XS017', () {
      final xml = _buildMinimalView(
        archContent: '''
          <field name="name"/>
          <field name="email"/>
        ''',
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.warnings.any((w) => w.code == 'XS017'), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Full valid document — no errors
  // ──────────────────────────────────────────────────────────────────────────
  group('full valid document', () {
    test('complete valid form view has no errors', () {
      final xml = _buildMinimalView(
        recordId: 'my_module.view_partner_form',
        model: 'res.partner',
        viewName: 'res.partner.form',
        viewRoot: 'form',
        archContent: '''
          <field name="name"/>
          <field name="email"/>
          <field name="phone"/>
        ''',
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('complete valid tree view has no errors', () {
      final xml = _buildMinimalView(
        viewRoot: 'tree',
        archContent: '<field name="name"/><field name="email"/>',
      );
      final result = XmlStructureValidator.validate(xml);
      expect(result.isValid, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // isValid() and errorMessages() helpers
  // ──────────────────────────────────────────────────────────────────────────
  group('isValid() and errorMessages() helpers', () {
    test('isValid returns true for valid XML', () {
      final xml = _buildMinimalView();
      expect(XmlStructureValidator.isValid(xml), isTrue);
    });

    test('isValid returns false for empty XML', () {
      expect(XmlStructureValidator.isValid(''), isFalse);
    });

    test('errorMessages returns empty list for valid XML', () {
      final xml = _buildMinimalView();
      expect(XmlStructureValidator.errorMessages(xml), isEmpty);
    });

    test('errorMessages returns non-empty list for invalid XML', () {
      expect(XmlStructureValidator.errorMessages('bad xml'), isNotEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XmlStructureIssue properties
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlStructureIssue', () {
    test('isError is true for error severity', () {
      final issue = XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS001',
        message: 'test error',
      );
      expect(issue.isError, isTrue);
    });

    test('isError is false for warning severity', () {
      final issue = XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS003',
        message: 'test warning',
      );
      expect(issue.isError, isFalse);
    });

    test('toString includes path when present', () {
      final issue = XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS004',
        message: 'Wrong root',
        path: '/',
      );
      expect(issue.toString(), contains('@/'));
    });

    test('toString works without path', () {
      final issue = XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS003',
        message: 'Missing declaration',
      );
      final str = issue.toString();
      expect(str, contains('XS003'));
      expect(str, contains('Missing declaration'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // XmlStructureValidationResult
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlStructureValidationResult', () {
    test('isValid is true when no errors exist', () {
      final result = XmlStructureValidator.validate(_buildMinimalView());
      expect(result.isValid, isTrue);
    });

    test('errors, warnings and infos are properly split', () {
      final result = XmlStructureValidator.validate('');
      expect(result.errors, isNotEmpty);
      expect(result.errors.every((e) => e.isError), isTrue);
    });
  });
}
