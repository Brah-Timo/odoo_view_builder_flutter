// lib/presentation/widgets/editor/group_properties_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../data/models/odoo_group.dart';
import '../../providers/editor_state_provider.dart';

class GroupPropertiesPanel extends ConsumerStatefulWidget {
  final OdooGroup group;
  const GroupPropertiesPanel({super.key, required this.group});

  @override
  ConsumerState<GroupPropertiesPanel> createState() =>
      _GroupPropertiesPanelState();
}

class _GroupPropertiesPanelState
    extends ConsumerState<GroupPropertiesPanel> {
  late TextEditingController _labelCtrl;
  late TextEditingController _groupsCtrl;
  late TextEditingController _attrsCtrl;
  late TextEditingController _expandBtnCtrl;

  @override
  void initState() {
    super.initState();
    _init(widget.group);
  }

  void _init(OdooGroup g) {
    _labelCtrl = TextEditingController(text: g.label ?? '');
    _groupsCtrl = TextEditingController(text: g.groups ?? '');
    _attrsCtrl = TextEditingController(text: g.attrs ?? '');
    _expandBtnCtrl =
        TextEditingController(text: g.expandButtonLabel ?? '');
  }

  @override
  void didUpdateWidget(GroupPropertiesPanel old) {
    super.didUpdateWidget(old);
    if (old.group.id != widget.group.id) {
      _labelCtrl.dispose();
      _groupsCtrl.dispose();
      _attrsCtrl.dispose();
      _expandBtnCtrl.dispose();
      _init(widget.group);
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _groupsCtrl.dispose();
    _attrsCtrl.dispose();
    _expandBtnCtrl.dispose();
    super.dispose();
  }

  void _update(OdooGroup updated) {
    ref.read(currentViewProvider.notifier).updateGroup(updated);
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;

    return Container(
      color: AppTheme.propertiesBackground,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Group Properties',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('group', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => ref
                      .read(canvasSelectionProvider.notifier)
                      .state = NoSelection(),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label
                  _PropField(
                    label: 'Group Title (string)',
                    controller: _labelCtrl,
                    hint: 'e.g. General Information',
                    onChanged: (v) =>
                        _update(group.copyWith(label: v.isEmpty ? null : v)),
                  ),

                  const SizedBox(height: 16),
                  Text('Layout', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),

                  // Colspan
                  _DropdownField<int?>(
                    label: 'Colspan',
                    value: group.colspan,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('(default)')),
                      ...AppConstants.colspanOptions.map((n) =>
                          DropdownMenuItem(value: n, child: Text('$n'))),
                    ],
                    onChanged: (v) => _update(group.copyWith(colspan: v)),
                  ),

                  // Col (columns inside group)
                  _DropdownField<int?>(
                    label: 'Columns inside (col)',
                    value: group.col,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('(default)')),
                      ...AppConstants.colspanOptions.map((n) =>
                          DropdownMenuItem(value: n, child: Text('$n'))),
                    ],
                    onChanged: (v) => _update(group.copyWith(col: v)),
                  ),

                  const SizedBox(height: 16),
                  Text('Options', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),

                  _CheckboxField(
                    label: 'Fill Break (fill_brk)',
                    value: group.fillBrk,
                    onChanged: (v) => _update(group.copyWith(fillBrk: v)),
                  ),
                  _CheckboxField(
                    label: 'Expandable (expand)',
                    value: group.expand,
                    onChanged: (v) => _update(group.copyWith(expand: v)),
                  ),
                  _CheckboxField(
                    label: 'Invisible',
                    value: group.invisible,
                    onChanged: (v) => _update(group.copyWith(invisible: v)),
                  ),

                  if (group.expand) ...[
                    const SizedBox(height: 10),
                    _PropField(
                      label: 'Expand Button Label',
                      controller: _expandBtnCtrl,
                      hint: 'See more...',
                      onChanged: (v) => _update(
                          group.copyWith(
                              expandButtonLabel: v.isEmpty ? null : v)),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text('Access & Conditions', style: AppTheme.sectionTitle),
                  const SizedBox(height: 10),

                  _PropField(
                    label: 'groups',
                    controller: _groupsCtrl,
                    hint: 'base.group_system',
                    onChanged: (v) =>
                        _update(group.copyWith(groups: v.isEmpty ? null : v)),
                  ),
                  _PropField(
                    label: 'attrs',
                    controller: _attrsCtrl,
                    hint: "{'invisible': [...]}",
                    onChanged: (v) =>
                        _update(group.copyWith(attrs: v.isEmpty ? null : v)),
                  ),

                  const SizedBox(height: 16),
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Group Summary',
                            style: AppTheme.sectionTitle),
                        const SizedBox(height: 8),
                        _SummaryRow('Fields', '${group.fields.length}'),
                        _SummaryRow('Sub-groups', '${group.subGroups.length}'),
                        _SummaryRow(
                            'Total fields', '${group.totalFieldCount}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _PropField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  const _PropField({
    required this.label,
    required this.controller,
    this.hint,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.fieldLabel),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(hintText: hint),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CheckboxField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckboxField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.fieldLabel),
          const SizedBox(height: 4),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(),
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: AppTheme.fieldLabel),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}
