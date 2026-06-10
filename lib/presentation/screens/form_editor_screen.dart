// lib/presentation/screens/form_editor_screen.dart
//
// Dedicated full-screen Form view editor with notebook page management.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/odoo_form.dart';
import '../../config/constants.dart';
import '../providers/editor_state_provider.dart';
import '../widgets/editor/canvas_area.dart';

class FormEditorScreen extends ConsumerWidget {
  const FormEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(currentViewProvider);
    if (view == null) return const SizedBox.shrink();

    return DefaultTabController(
      length: view.pages.length + 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(view.name),
          bottom: view.pages.isNotEmpty ? _buildPageTabBar(view, ref) : null,
          actions: [
            if (view.pages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add Page',
                onPressed: () => _addPage(context, ref),
              ),
          ],
        ),
        body: view.pages.isNotEmpty
            ? TabBarView(
                children: [
                  // First tab: root fields + groups
                  CanvasArea(view: view),
                  // Other tabs: pages
                  ...view.pages.map(
                    (page) => _PageContent(view: view, page: page),
                  ),
                ],
              )
            : CanvasArea(view: view),
      ),
    );
  }

  PreferredSize _buildPageTabBar(OdooView view, WidgetRef ref) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: TabBar(
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        indicatorColor: Colors.white,
        tabs: [
          const Tab(text: 'Root'),
          ...view.pages.map((p) => Tab(text: p.label)),
        ],
      ),
    );
  }

  Future<void> _addPage(BuildContext context, WidgetRef ref) async {
    final label = await showDialog<String>(
      context: context,
      builder: (_) => _AddPageDialog(),
    );
    if (label != null) {
      ref.read(currentViewProvider.notifier).addPage(
            NotebookPage.create(label),
          );
    }
  }
}

class _PageContent extends StatelessWidget {
  final OdooView view;
  final NotebookPage page;
  const _PageContent({required this.view, required this.page});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.canvasBackground,
      padding: const EdgeInsets.all(AppConstants.canvasPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Page: ${page.label}',
            style: AppTheme.sectionTitle,
          ),
          const SizedBox(height: 12),
          Text(
            '${page.fields.length} field(s)  •  ${page.groups.length} group(s)',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AddPageDialog extends StatefulWidget {
  @override
  State<_AddPageDialog> createState() => _AddPageDialogState();
}

class _AddPageDialogState extends State<_AddPageDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Notebook Page'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Page Label',
          hintText: 'e.g. Details, Notes, Advanced',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_ctrl.text.trim().isNotEmpty) {
              Navigator.pop(context, _ctrl.text.trim());
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

