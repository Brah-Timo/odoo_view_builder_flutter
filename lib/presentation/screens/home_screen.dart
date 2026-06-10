// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/models/odoo_form.dart';
import '../providers/view_provider.dart';
import '../providers/editor_state_provider.dart';
import '../providers/settings_provider.dart';
import 'editor_screen.dart';
import 'template_library_screen.dart';
import 'settings_screen.dart';
import 'export_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewsAsync = ref.watch(filteredViewsProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'OVB',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Odoo View Builder'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // ── Left side-panel ───────────────────────────────────────────────
          _buildSidePanel(context),

          // ── Main content ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: viewsAsync.when(
                    data: (views) => views.isEmpty
                        ? _buildEmptyState(context)
                        : _buildViewsGrid(views),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewViewDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New View'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ─── Side Panel ───────────────────────────────────────────────────────────

  Widget _buildSidePanel(BuildContext context) {
    return Container(
      width: 220,
      color: AppTheme.paletteBackground,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _sideItem(
            icon: Icons.dashboard_outlined,
            label: 'My Views',
            selected: true,
          ),
          _sideItem(
            icon: Icons.library_books_outlined,
            label: 'Templates',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const TemplateLibraryScreen()),
            ),
          ),
          const Divider(color: Color(0xFF444444), height: 32),
          _sideItem(
            icon: Icons.description_outlined,
            label: 'Form Views',
            onTap: () => _filterByType(ViewType.form),
          ),
          _sideItem(
            icon: Icons.list_outlined,
            label: 'List Views',
            onTap: () => _filterByType(ViewType.tree),
          ),
          _sideItem(
            icon: Icons.view_kanban_outlined,
            label: 'Kanban Views',
            onTap: () => _filterByType(ViewType.kanban),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideItem({
    required IconData icon,
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.3) : null,
          border: selected
              ? const Border(
                  left: BorderSide(color: AppTheme.primaryLight, width: 3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white60,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search views by name or model...',
                prefixIcon: Icon(Icons.search, size: 18),
                suffixIcon: null,
              ),
              onChanged: (query) =>
                  ref.read(viewSearchQueryProvider.notifier).state = query,
            ),
          ),
          const SizedBox(width: 12),
          _StatChip(
            label: 'Total Views',
            future: ref.read(viewRepositoryProvider).count(),
          ),
        ],
      ),
    );
  }

  // ─── Views Grid ───────────────────────────────────────────────────────────

  Widget _buildViewsGrid(List<OdooView> views) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisExtent: 180,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: views.length,
      itemBuilder: (context, index) =>
          _ViewCard(view: views[index], onTap: () => _openEditor(views[index])),
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.code,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No views yet',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first Odoo view or pick a template',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showNewViewDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Create from scratch'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const TemplateLibraryScreen()),
                ),
                icon: const Icon(Icons.library_books_outlined),
                label: const Text('Browse templates'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _filterByType(ViewType type) {
    ref.read(viewSearchQueryProvider.notifier).state = type.value;
    _searchController.text = type.value;
  }

  void _openEditor(OdooView view) {
    ref.read(currentViewProvider.notifier).loadView(view);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const EditorScreen()),
    );
  }

  Future<void> _showNewViewDialog(BuildContext context) async {
    final result = await showDialog<OdooView>(
      context: context,
      builder: (_) => const _NewViewDialog(),
    );
    if (result != null && mounted) {
      await ref.read(savedViewsProvider.notifier).save(result);
      _openEditor(result);
    }
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _ViewCard extends StatelessWidget {
  final OdooView view;
  final VoidCallback onTap;

  const _ViewCard({required this.view, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final typeColor = switch (view.viewType) {
      ViewType.form => AppTheme.primaryColor,
      ViewType.tree => AppTheme.accentColor,
      ViewType.kanban => const Color(0xFFFF7043),
    };

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color header bar
            Container(
              height: 4,
              color: typeColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            view.viewType.label,
                            style: AppTheme.fieldTypeBadge
                                .copyWith(color: typeColor),
                          ),
                        ),
                        const Spacer(),
                        _ViewCardMenu(view: view),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      view.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      view.model,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'FiraCode',
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.list_alt,
                          label: '${view.allFields.length} fields',
                        ),
                        const SizedBox(width: 8),
                        if (view.groups.isNotEmpty)
                          _InfoChip(
                            icon: Icons.group_work_outlined,
                            label: '${view.groups.length} groups',
                          ),
                      ],
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
}

class _ViewCardMenu extends ConsumerWidget {
  final OdooView view;
  const _ViewCardMenu({required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'export', child: Text('Export XML')),
        const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
      onSelected: (action) async {
        switch (action) {
          case 'export':
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ExportScreen(view: view),
              ),
            );
            break;
          case 'duplicate':
            final copy = view.copyWith(
              id: '${view.id}_copy',
              name: '${view.name} (copy)',
            );
            await ref.read(savedViewsProvider.notifier).save(copy);
            break;
          case 'delete':
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete View'),
                content: Text('Delete "${view.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await ref.read(savedViewsProvider.notifier).delete(view.id);
            }
            break;
        }
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Future<int> future;
  const _StatChip({required this.label, required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (_, snap) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${snap.data ?? 0} $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// ─── New View Dialog ─────────────────────────────────────────────────────────

class _NewViewDialog extends ConsumerStatefulWidget {
  const _NewViewDialog();

  @override
  ConsumerState<_NewViewDialog> createState() => _NewViewDialogState();
}

class _NewViewDialogState extends ConsumerState<_NewViewDialog> {
  final _nameCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _moduleCtrl = TextEditingController();
  ViewType _type = ViewType.form;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _moduleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New View'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'View Name *',
                  hintText: 'e.g. Custom Partner Form',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                optionsBuilder: (v) => AppConstants.commonOdooModels
                    .where((m) =>
                        m.contains(v.text.toLowerCase()))
                    .toList(),
                fieldViewBuilder: (ctx, ctrl, node, onSub) {
                  _modelCtrl.addListener(() {});
                  return TextFormField(
                    controller: ctrl,
                    focusNode: node,
                    onEditingComplete: onSub,
                    decoration: const InputDecoration(
                      labelText: 'Odoo Model *',
                      hintText: 'e.g. res.partner',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    onChanged: (val) => _modelCtrl.text = val,
                  );
                },
                onSelected: (option) => _modelCtrl.text = option,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _moduleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Module Name (optional)',
                  hintText: 'e.g. custom_module',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: ViewType.values.map((type) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(type.label),
                        selected: _type == type,
                        onSelected: (_) => setState(() => _type = type),
                        selectedColor:
                            AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _create,
          child: const Text('Create'),
        ),
      ],
    );
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;

    final view = OdooView.create(
      name: _nameCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      viewType: _type,
      docModule: _moduleCtrl.text.trim().isEmpty
          ? null
          : _moduleCtrl.text.trim(),
    );

    Navigator.pop(context, view);
  }
}
