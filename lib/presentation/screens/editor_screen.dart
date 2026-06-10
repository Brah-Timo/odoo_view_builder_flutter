// lib/presentation/screens/editor_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../data/models/odoo_form.dart';

import '../providers/editor_state_provider.dart';
import '../providers/view_provider.dart';
import '../providers/xml_generator_provider.dart';
import '../widgets/editor/field_palette.dart';
import '../widgets/editor/canvas_area.dart';
import '../widgets/editor/field_properties_panel.dart';
import '../widgets/editor/group_properties_panel.dart';
import '../widgets/xml/xml_preview_widget.dart';
import 'export_screen.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final OdooView? initialView;
  const EditorScreen({super.key, this.initialView});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(currentViewProvider);
    final showXml = ref.watch(showXmlPreviewProvider);
    final showProperties = ref.watch(showPropertiesPanelProvider);
    final showPalette = ref.watch(showPalettePanelProvider);
    final selection = ref.watch(canvasSelectionProvider);
    final isValid = ref.watch(isViewValidProvider);
    final canUndo = ref.watch(currentViewProvider.notifier).canUndo;
    final canRedo = ref.watch(currentViewProvider.notifier).canRedo;

    if (view == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editor')),
        body: const Center(child: Text('No view loaded')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(view, isValid),
      body: Row(
        children: [
          // ── 1. Palette Panel ──────────────────────────────────────────────
          if (showPalette)
            SizedBox(
              width: AppConstants.palettePanelWidth,
              child: FieldPalette(viewType: view.viewType),
            ),

          // ── 2. Canvas ────────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildViewTypeTabs(view),
                Expanded(
                  child: CanvasArea(view: view),
                ),
              ],
            ),
          ),

          // ── 3. Properties / XML Panel ─────────────────────────────────────
          if (showProperties || showXml)
            SizedBox(
              width: showXml
                  ? AppConstants.xmlPreviewPanelWidth
                  : AppConstants.propertiesPanelWidth,
              child: _buildRightPanel(selection, showXml),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(view, canUndo, canRedo),
    );
  }

  // ─── App Bar ─────────────────────────────────────────────────────────────

  AppBar _buildAppBar(OdooView view, bool isValid) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _confirmLeave(),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              view.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              view.model,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
          if (!isValid) ...[
            const SizedBox(width: 8),
            const Tooltip(
              message: 'Validation errors found',
              child: Icon(Icons.warning_amber, color: Colors.amber, size: 18),
            ),
          ],
        ],
      ),
      actions: [
        // Toggle panels
        IconButton(
          icon: const Icon(Icons.view_sidebar_outlined),
          tooltip: 'Toggle field palette',
          onPressed: () => ref
              .read(showPalettePanelProvider.notifier)
              .update((s) => !s),
        ),
        IconButton(
          icon: const Icon(Icons.code),
          tooltip: 'Toggle XML preview',
          onPressed: () => ref
              .read(showXmlPreviewProvider.notifier)
              .update((s) => !s),
        ),
        const SizedBox(width: 8),
        // Save
        TextButton.icon(
          onPressed: () => _save(),
          icon: const Icon(Icons.save_outlined, color: Colors.white),
          label: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
        // Export
        TextButton.icon(
          onPressed: () => _export(),
          icon: const Icon(Icons.download_outlined, color: Colors.white),
          label: const Text('Export', style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ─── View Type Tabs ────────────────────────────────────────────────────────

  Widget _buildViewTypeTabs(OdooView view) {
    return Container(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Text(
              'View Type:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            ...ViewType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.label, style: const TextStyle(fontSize: 12)),
                    selected: view.viewType == type,
                    onSelected: (_) {
                      ref
                          .read(currentViewProvider.notifier)
                          .updateMeta(viewType: type);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  // ─── Right Panel ──────────────────────────────────────────────────────────

  Widget _buildRightPanel(CanvasSelection selection, bool showXml) {
    if (showXml) {
      return const XmlPreviewWidget();
    }

    return switch (selection) {
      FieldSelection s => FieldPropertiesPanel(field: s.field),
      GroupSelection s => GroupPropertiesPanel(group: s.group),
      _ => _buildViewPropertiesPanel(),
    };
  }

  Widget _buildViewPropertiesPanel() {
    final view = ref.watch(currentViewProvider);
    if (view == null) return const SizedBox.shrink();

    return Container(
      color: AppTheme.propertiesBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('View Properties', style: AppTheme.sectionTitle),
            const SizedBox(height: 16),
            _PropField(
              label: 'View ID',
              value: view.id,
              onChanged: (v) => ref
                  .read(currentViewProvider.notifier)
                  .updateMeta(id: v),
            ),
            const SizedBox(height: 10),
            _PropField(
              label: 'View Name',
              value: view.name,
              onChanged: (v) => ref
                  .read(currentViewProvider.notifier)
                  .updateMeta(name: v),
            ),
            const SizedBox(height: 10),
            _PropField(
              label: 'Model',
              value: view.model,
              onChanged: (v) => ref
                  .read(currentViewProvider.notifier)
                  .updateMeta(model: v),
            ),
            const SizedBox(height: 10),
            _PropField(
              label: 'Module',
              value: view.docModule ?? '',
              onChanged: (v) => ref
                  .read(currentViewProvider.notifier)
                  .updateMeta(docModule: v.isEmpty ? null : v),
            ),
            const SizedBox(height: 10),
            _PropField(
              label: 'Inherit ID',
              value: view.inheritId ?? '',
              onChanged: (v) => ref
                  .read(currentViewProvider.notifier)
                  .updateMeta(inheritId: v.isEmpty ? null : v),
            ),
            const SizedBox(height: 10),
            _PropField(
              label: 'Priority',
              value: view.priority.toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null) {
                  ref
                      .read(currentViewProvider.notifier)
                      .updateMeta(priority: n);
                }
              },
            ),
            if (view.viewType == ViewType.tree) ...[
              const SizedBox(height: 16),
              Text('Tree Options', style: AppTheme.sectionTitle),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Editable (top)', style: TextStyle(fontSize: 13)),
                value: view.editable,
                onChanged: (v) => ref
                    .read(currentViewProvider.notifier)
                    .updateMeta(),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              _PropField(
                label: 'Default Order',
                value: view.defaultOrder ?? '',
                onChanged: (v) => ref
                    .read(currentViewProvider.notifier)
                    .updateMeta(defaultOrder: v.isEmpty ? null : v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar(OdooView view, bool canUndo, bool canRedo) {
    final report = ref.watch(validationReportProvider);

    return Container(
      height: 36,
      color: AppTheme.primaryDark,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.undo, size: 16),
            color: canUndo ? Colors.white : Colors.white30,
            tooltip: 'Undo',
            onPressed: canUndo
                ? () => ref.read(currentViewProvider.notifier).undo()
                : null,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.redo, size: 16),
            color: canRedo ? Colors.white : Colors.white30,
            tooltip: 'Redo',
            onPressed: canRedo
                ? () => ref.read(currentViewProvider.notifier).redo()
                : null,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 16),
          Text(
            '${view.allFields.length} fields  •  ${view.groups.length} groups',
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const Spacer(),
          if (report != null) ...[
            if (report.errorCount > 0)
              _StatusBadge(
                label: '${report.errorCount} error(s)',
                color: AppTheme.errorColor,
              ),
            if (report.warningCount > 0) ...[
              const SizedBox(width: 8),
              _StatusBadge(
                label: '${report.warningCount} warning(s)',
                color: AppTheme.warningColor,
              ),
            ],
            if (report.isValid)
              const _StatusBadge(label: '✓ Valid', color: AppTheme.successColor),
          ],
          const SizedBox(width: 8),
          Text(
            'Last saved: just now',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final view = ref.read(currentViewProvider);
    if (view == null) return;
    await ref.read(savedViewsProvider.notifier).save(view);
    ref.read(hasUnsavedChangesProvider.notifier).state = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('View saved successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _export() {
    final view = ref.read(currentViewProvider);
    if (view == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => ExportScreen(view: view)),
    );
  }

  Future<void> _confirmLeave() async {
    final hasChanges = ref.read(hasUnsavedChangesProvider);
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have unsaved changes. Do you want to save before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Discard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == 'save') {
      await _save();
      if (mounted) Navigator.pop(context);
    } else if (result == 'discard') {
      if (mounted) Navigator.pop(context);
    }
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _PropField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  const _PropField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.keyboardType,
  });

  @override
  State<_PropField> createState() => _PropFieldState();
}

class _PropFieldState extends State<_PropField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_PropField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTheme.fieldLabel),
        const SizedBox(height: 4),
        TextField(
          controller: _ctrl,
          keyboardType: widget.keyboardType,
          onSubmitted: widget.onChanged,
          onEditingComplete: () => widget.onChanged(_ctrl.text),
          decoration: const InputDecoration(),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
