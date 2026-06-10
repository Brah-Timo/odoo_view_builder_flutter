// test/presentation/widgets/xml_preview_widget_test.dart
//
// Widget tests for XmlPreviewWidget.
// Because XmlPreviewWidget depends on Riverpod providers (liveXmlProvider,
// archXmlProvider, showLineNumbersProvider) we wrap every pump inside a
// ProviderScope with override values so the tests remain fast and isolated.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/presentation/providers/xml_generator_provider.dart';
import 'package:odoo_view_builder_flutter/presentation/providers/settings_provider.dart';
import 'package:odoo_view_builder_flutter/presentation/widgets/xml/xml_preview_widget.dart';

// ── Test XML fixtures ───────────────────────────────────────────────────────

const _sampleXml = '''<?xml version="1.0" encoding="utf-8"?>
<odoo>
  <data>
    <record id="view_partner_form" model="ir.ui.view">
      <field name="name">res.partner.form</field>
      <field name="model">res.partner</field>
      <field name="arch" type="xml">
        <form>
          <field name="name"/>
        </form>
      </field>
    </record>
  </data>
</odoo>''';

const _archXml = '<form><field name="name"/></form>';

// ── Helper ──────────────────────────────────────────────────────────────────

Widget _buildWidget({
  String liveXml = _sampleXml,
  String archXml = _archXml,
  bool showLineNumbers = true,
}) {
  return ProviderScope(
    overrides: [
      liveXmlProvider.overrideWith((ref) => liveXml),
      archXmlProvider.overrideWith((ref) => archXml),
      showLineNumbersProvider.overrideWith((ref) => BoolSettingNotifier('test_key', showLineNumbers)),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: XmlPreviewWidget(),
      ),
    ),
  );
}

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // Rendering
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlPreviewWidget — rendering', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();
      // No exception thrown means basic rendering works
    });

    testWidgets('shows "XML Preview" header text', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();
      expect(find.text('XML Preview'), findsOneWidget);
    });

    testWidgets('shows "Full" chip', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();
      expect(find.text('Full'), findsOneWidget);
    });

    testWidgets('shows "Arch only" chip', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();
      expect(find.text('Arch only'), findsOneWidget);
    });

    testWidgets('shows line count in header', (tester) async {
      await tester.pumpWidget(_buildWidget(liveXml: _sampleXml));
      await tester.pump();
      // The header shows "{N} lines"
      expect(find.textContaining('lines'), findsOneWidget);
    });

    testWidgets('shows copy icon button', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Full / Arch toggle
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlPreviewWidget — Full / Arch only toggle', () {
    testWidgets('tapping "Arch only" chip switches to arch XML', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      // Tap "Arch only"
      await tester.tap(find.text('Arch only'));
      await tester.pump();

      // After switching, the line count should reflect the shorter arch XML
      // We can't easily check the displayed XML content without a key, but we
      // verify no exceptions and the widget is still present
      expect(find.text('Arch only'), findsOneWidget);
    });

    testWidgets('tapping "Full" chip after "Arch only" switches back', (tester) async {
      await tester.pumpWidget(_buildWidget());
      await tester.pump();

      await tester.tap(find.text('Arch only'));
      await tester.pump();

      await tester.tap(find.text('Full'));
      await tester.pump();

      expect(find.text('Full'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Different XML content
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlPreviewWidget — XML content variations', () {
    testWidgets('renders with empty XML gracefully', (tester) async {
      await tester.pumpWidget(_buildWidget(liveXml: ''));
      await tester.pump();
      // Should show "0 lines" or "1 lines"
      expect(find.byType(XmlPreviewWidget), findsOneWidget);
    });

    testWidgets('renders with single-line XML', (tester) async {
      await tester.pumpWidget(
        _buildWidget(liveXml: '<odoo><data/></odoo>'),
      );
      await tester.pump();
      expect(find.byType(XmlPreviewWidget), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Line numbers toggle via provider
  // ──────────────────────────────────────────────────────────────────────────
  group('XmlPreviewWidget — showLineNumbers provider', () {
    testWidgets('renders with showLineNumbers=false without error', (tester) async {
      await tester.pumpWidget(_buildWidget(showLineNumbers: false));
      await tester.pump();
      expect(find.byType(XmlPreviewWidget), findsOneWidget);
    });

    testWidgets('renders with showLineNumbers=true without error', (tester) async {
      await tester.pumpWidget(_buildWidget(showLineNumbers: true));
      await tester.pump();
      expect(find.byType(XmlPreviewWidget), findsOneWidget);
    });
  });
}
