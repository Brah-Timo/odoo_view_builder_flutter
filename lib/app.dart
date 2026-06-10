// lib/app.dart
//
// Root Flutter application widget.
//
// Responsibilities:
//   • Wraps the widget tree with ProviderScope (Riverpod).
//   • Configures Material 3 theming (light + dark).
//   • Sets up named route table.
//   • Provides global Navigator key for programmatic navigation from services.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/editor_screen.dart';
import 'presentation/screens/export_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/kanban_editor_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/template_library_screen.dart';
import 'presentation/screens/tree_editor_screen.dart';
import 'data/models/odoo_form.dart';

// ---------------------------------------------------------------------------
// Global navigator key
// ---------------------------------------------------------------------------

/// Global [NavigatorKey] — allows services to push routes without a
/// [BuildContext] (e.g. from [CrashReporter] or deep-link handlers).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------

abstract class AppRoutes {
  static const String home = '/';
  static const String editor = '/editor';
  static const String formEditor = '/editor/form';
  static const String treeEditor = '/editor/tree';
  static const String kanbanEditor = '/editor/kanban';
  static const String export = '/export';
  static const String settings = '/settings';
  static const String templateLibrary = '/templates';
}

// ---------------------------------------------------------------------------
// OdooViewBuilderApp
// ---------------------------------------------------------------------------

/// The root application widget.
///
/// Must be a [ConsumerWidget] so it can watch the [themeModeProvider]
/// and rebuild when the user changes the colour scheme preference.
class OdooViewBuilderApp extends ConsumerWidget {
  const OdooViewBuilderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Odoo View Builder',
      debugShowCheckedModeBanner: false,

      // ── Theming ───────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ── Navigator ─────────────────────────────────────────────────────
      navigatorKey: navigatorKey,

      // ── Initial route ─────────────────────────────────────────────────
      initialRoute: AppRoutes.home,

      // ── Named route table ─────────────────────────────────────────────
      routes: {
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.editor: (_) => const EditorScreen(),
        AppRoutes.treeEditor: (_) => const TreeEditorScreen(),
        AppRoutes.kanbanEditor: (_) => const KanbanEditorScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.templateLibrary: (_) => const TemplateLibraryScreen(),
      },

      // ── Dynamic routes with arguments ─────────────────────────────────
      onGenerateRoute: _onGenerateRoute,

      // ── Unknown routes ────────────────────────────────────────────────
      onUnknownRoute: (settings) => MaterialPageRoute<void>(
        builder: (_) => _NotFoundScreen(routeName: settings.name),
      ),

      // ── Global scroll behaviour ───────────────────────────────────────
      scrollBehavior: const _AppScrollBehavior(),
    );
  }

  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.export:
        final form = settings.arguments as OdooView?;
        return MaterialPageRoute<void>(
          builder: (_) => ExportScreen(view: form),
          settings: settings,
        );

      case AppRoutes.formEditor:
      case AppRoutes.editor:
        final form = settings.arguments as OdooView?;
        return MaterialPageRoute<void>(
          builder: (_) => EditorScreen(initialView: form),
          settings: settings,
        );

      default:
        return null;
    }
  }
}

// ---------------------------------------------------------------------------
// _AppScrollBehavior
// ---------------------------------------------------------------------------

/// Enables mouse-drag scrolling on all platforms (needed for desktop / web).
class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// ---------------------------------------------------------------------------
// _NotFoundScreen
// ---------------------------------------------------------------------------

class _NotFoundScreen extends StatelessWidget {
  final String? routeName;
  const _NotFoundScreen({this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '404 — Route not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (routeName != null) ...[
              const SizedBox(height: 8),
              Text(
                routeName!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }
}
