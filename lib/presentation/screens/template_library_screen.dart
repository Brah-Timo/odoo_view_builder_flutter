// lib/presentation/screens/template_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/odoo_form.dart';
import '../../data/models/view_template.dart';
import '../providers/view_provider.dart';
import '../providers/editor_state_provider.dart';
import 'editor_screen.dart';

class TemplateLibraryScreen extends ConsumerStatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  ConsumerState<TemplateLibraryScreen> createState() =>
      _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState
    extends ConsumerState<TemplateLibraryScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = BuiltInTemplates.all.map((t) => t.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<ViewTemplate> get _filteredTemplates {
    if (_selectedCategory == 'All') return BuiltInTemplates.all;
    return BuiltInTemplates.all
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Template Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Category sidebar ──────────────────────────────────────────────
          Container(
            width: 180,
            color: AppTheme.paletteBackground,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'CATEGORIES',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                ..._categories.map((cat) => InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        color: _selectedCategory == cat
                            ? AppTheme.primaryColor.withOpacity(0.3)
                            : null,
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: _selectedCategory == cat
                                ? Colors.white
                                : Colors.white60,
                            fontSize: 13,
                            fontWeight: _selectedCategory == cat
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
          ),

          // ── Templates grid ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '${_filteredTemplates.length} template(s)',
                    style: AppTheme.sectionTitle,
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 320,
                      mainAxisExtent: 220,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredTemplates.length,
                    itemBuilder: (_, index) =>
                        _TemplateCard(template: _filteredTemplates[index]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Template Card ────────────────────────────────────────────────────────────

class _TemplateCard extends ConsumerWidget {
  final ViewTemplate template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = switch (template.viewType) {
      ViewType.form => AppTheme.primaryColor,
      ViewType.tree => AppTheme.accentColor,
      ViewType.kanban => const Color(0xFFFF7043),
    };

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _useTemplate(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 4, color: typeColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          template.iconEmoji ?? '📄',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            template.viewType.label,
                            style: AppTheme.fieldTypeBadge
                                .copyWith(color: typeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      template.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.model,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      template.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _useTemplate(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: typeColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Use Template'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useTemplate(BuildContext context, WidgetRef ref) async {
    final view = template.build();
    await ref.read(savedViewsProvider.notifier).save(view);
    ref.read(currentViewProvider.notifier).loadView(view);

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
        (route) => route.isFirst,
      );
    }
  }
}
