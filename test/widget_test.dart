// test/widget_test.dart
//
// Root widget smoke test for OdooViewBuilderApp.
//
// This test verifies that the application bootstraps correctly:
//   • OdooViewBuilderApp renders inside a ProviderScope without throwing
//   • The MaterialApp is created with the correct title
//   • The HomeScreen (initial route) loads and contains expected UI elements
//
// NOTE: These tests do NOT test business logic — only that the widget tree
// can be instantiated without errors.  Integration tests that require a full
// Odoo connection are outside the scope of unit/widget tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:odoo_view_builder_flutter/app.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // OdooViewBuilderApp smoke tests
  // ──────────────────────────────────────────────────────────────────────────
  group('OdooViewBuilderApp', () {
    testWidgets('builds without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OdooViewBuilderApp(),
        ),
      );
      // First frame only — don't settle async tasks
      await tester.pump();
    });

    testWidgets('creates a MaterialApp widget', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OdooViewBuilderApp(),
        ),
      );
      await tester.pump();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('MaterialApp has correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OdooViewBuilderApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, equals('Odoo View Builder'));
    });

    testWidgets('debug banner is disabled', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OdooViewBuilderApp(),
        ),
      );
      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('initial route renders a Scaffold', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: OdooViewBuilderApp(),
        ),
      );
      // Use pump() to advance one frame — pumpAndSettle times out because
      // SharedPreferences providers use async _load() that never completes in
      // the test environment without a mock.
      await tester.pump();
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // AppRoutes constants
  // ──────────────────────────────────────────────────────────────────────────
  group('AppRoutes', () {
    test('home is "/"', () {
      expect(AppRoutes.home, equals('/'));
    });

    test('editor is "/editor"', () {
      expect(AppRoutes.editor, equals('/editor'));
    });

    test('export is "/export"', () {
      expect(AppRoutes.export, equals('/export'));
    });

    test('settings is "/settings"', () {
      expect(AppRoutes.settings, equals('/settings'));
    });

    test('templateLibrary is "/templates"', () {
      expect(AppRoutes.templateLibrary, equals('/templates'));
    });
  });
}
