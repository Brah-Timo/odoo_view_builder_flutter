// lib/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final odooVersion = ref.watch(odooVersionProvider);
    final showLineNumbers = ref.watch(showLineNumbersProvider);
    final autoSave = ref.watch(autoSaveProvider);
    final indentSize = ref.watch(xmlIndentSizeProvider);
    final defaultModel = ref.watch(defaultModelProvider);
    final defaultModule = ref.watch(defaultModuleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // ── Appearance ────────────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          _SettingCard(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(themeMode.name.capitalize()),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ButtonSegment(
                        value: ThemeMode.system, label: Text('System')),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(s.first),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Odoo ──────────────────────────────────────────────────────────
          _SectionHeader(title: 'Odoo Settings'),
          _SettingCard(
            children: [
              ListTile(
                title: const Text('Target Odoo Version'),
                subtitle: Text('Generating XML for Odoo $odooVersion'),
                trailing: DropdownButton<String>(
                  value: odooVersion,
                  underline: const SizedBox(),
                  items: AppConstants.supportedOdooVersions
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(odooVersionProvider.notifier).setVersion(v);
                    }
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Model', style: AppTheme.fieldLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          TextEditingController(text: defaultModel),
                      decoration: const InputDecoration(
                        hintText: 'e.g. res.partner',
                      ),
                      onSubmitted: (v) =>
                          ref.read(defaultModelProvider.notifier).set(v),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Default Module', style: AppTheme.fieldLabel),
                    const SizedBox(height: 8),
                    TextField(
                      controller:
                          TextEditingController(text: defaultModule),
                      decoration: const InputDecoration(
                        hintText: 'e.g. custom_module',
                      ),
                      onSubmitted: (v) =>
                          ref.read(defaultModuleProvider.notifier).set(v),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── XML ───────────────────────────────────────────────────────────
          _SectionHeader(title: 'XML Output'),
          _SettingCard(
            children: [
              SwitchListTile(
                title: const Text('Show Line Numbers'),
                subtitle: const Text('Show line numbers in XML preview'),
                value: showLineNumbers,
                onChanged: (v) =>
                    ref.read(showLineNumbersProvider.notifier).set(v),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Indent Size'),
                subtitle: Text('$indentSize spaces'),
                trailing: DropdownButton<int>(
                  value: indentSize,
                  underline: const SizedBox(),
                  items: [2, 4, 8]
                      .map((i) => DropdownMenuItem(
                            value: i,
                            child: Text('$i spaces'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(xmlIndentSizeProvider.notifier).set(v);
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Auto-save ─────────────────────────────────────────────────────
          _SectionHeader(title: 'Editor'),
          _SettingCard(
            children: [
              SwitchListTile(
                title: const Text('Auto-save'),
                subtitle: const Text('Automatically save changes every 30s'),
                value: autoSave,
                onChanged: (v) =>
                    ref.read(autoSaveProvider.notifier).set(v),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          _SettingCard(
            children: [
              ListTile(
                title: const Text('App Version'),
                trailing: Text(
                  AppConstants.appVersion,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Supported Odoo Versions'),
                trailing: Text(
                  AppConstants.supportedOdooVersions.join(', '),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                title: Text('Documentation'),
                trailing: Icon(Icons.open_in_new_outlined, size: 16),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: AppTheme.sectionTitle,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(children: children),
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
