// lib/presentation/widgets/editor/field_properties_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../data/models/odoo_field.dart';
import '../../providers/editor_state_provider.dart';
import '../../providers/field_provider.dart';

/// Right panel showing and editing the currently selected field's properties
class FieldPropertiesPanel extends ConsumerStatefulWidget {
  final OdooField field;
  const FieldPropertiesPanel({super.key, required this.field});

  @override
  ConsumerState<FieldPropertiesPanel> createState() =>
      _FieldPropertiesPanelState();
}

class _FieldPropertiesPanelState
    extends ConsumerState<FieldPropertiesPanel> {
  late TextEditingController _nameCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _placeholderCtrl;
  late TextEditingController _domainCtrl;
  late TextEditingController _attrsCtrl;
  late TextEditingController _helpCtrl;
  late TextEditingController _groupsCtrl;
  late TextEditingController _comodelCtrl;
  late TextEditingController _colspanCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.field);
  }

  void _initControllers(OdooField f) {
    _nameCtrl = TextEditingController(text: f.name);
    _labelCtrl = TextEditingController(text: f.label ?? '');
    _placeholderCtrl = TextEditingController(text: f.placeholder ?? '');
    _domainCtrl = TextEditingController(text: f.domain ?? '');
    _attrsCtrl = TextEditingController(text: f.attrs ?? '');
    _helpCtrl = TextEditingController(text: f.help ?? '');
    _groupsCtrl = TextEditingController(text: f.groups ?? '');
    _comodelCtrl = TextEditingController(text: f.comodel ?? '');
    _colspanCtrl = TextEditingController(text: f.colspan?.toString() ?? '');
  }

  @override
  void didUpdateWidget(FieldPropertiesPanel old) {
    super.didUpdateWidget(old);
    if (old.field.id != widget.field.id) {
      _disposeControllers();
      _initControllers(widget.field);
    }
  }

  void _disposeControllers() {
    _nameCtrl.dispose();
    _labelCtrl.dispose();
    _placeholderCtrl.dispose();
    _domainCtrl.dispose();
    _attrsCtrl.dispose();
    _helpCtrl.dispose();
    _groupsCtrl.dispose();
    _comodelCtrl.dispose();
    _colspanCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _update(OdooField updated) {
    // Update in the correct location (top-level or inside a group)
    final notifier = ref.read(currentViewProvider.notifier);
    final view = ref.read(currentViewProvider);
    if (view == null) return;

    // Check if field is in top-level
    final inTopLevel = view.topLevelFields.any((f) => f.id == updated.id);
    if (inTopLevel) {
      notifier.updateTopLevelField(updated);
      return;
    }

    // Find which group contains this field
    for (final group in view.groups) {
      if (group.fields.any((f) => f.id == updated.id)) {
        notifier.updateFieldInGroup(group.id, updated);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final widgetOptions = ref.watch(widgetOptionsProvider(field.fieldType));

    return Container(
      color: AppTheme.propertiesBackground,
      child: Column(
        children: [
          // Header
          _PanelHeader(
            title: 'Field Properties',
            subtitle: field.fieldType.value,
            onClose: () => ref
                .read(canvasSelectionProvider.notifier)
                .state = NoSelection(),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Identity ───────────────────────────────────────────
                  _Section(
                    title: 'Identity',
                    children: [
                      _PropTextField(
                        label: 'Field Name *',
                        controller: _nameCtrl,
                        hint: 'e.g. partner_id',
                        onChanged: (v) => _update(field.copyWith(name: v)),
                      ),
                      _PropTextField(
                        label: 'Label (string)',
                        controller: _labelCtrl,
                        hint: 'Display label',
                        onChanged: (v) => _update(
                            field.copyWith(label: v.isEmpty ? null : v)),
                      ),
                      _PropTextField(
                        label: 'Placeholder',
                        controller: _placeholderCtrl,
                        hint: 'Placeholder text',
                        onChanged: (v) => _update(
                            field.copyWith(
                                placeholder: v.isEmpty ? null : v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Type ───────────────────────────────────────────────
                  _Section(
                    title: 'Type & Widget',
                    children: [
                      _DropdownProp<OdooFieldType>(
                        label: 'Field Type',
                        value: field.fieldType,
                        items: OdooFieldType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    '${t.value} — ${t.label}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) _update(field.copyWith(fieldType: v));
                        },
                      ),
                      _DropdownProp<String>(
                        label: 'Widget',
                        value: field.widget,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('(default)')),
                          ...widgetOptions.map((w) => DropdownMenuItem(
                                value: w.name,
                                child: Text(w.name,
                                    style: const TextStyle(
                                        fontFamily: 'monospace', fontSize: 12)),
                              )),
                        ],
                        onChanged: (v) => _update(field.copyWith(widget: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Behaviour ──────────────────────────────────────────
                  _Section(
                    title: 'Behaviour',
                    children: [
                      _CheckboxProp(
                        label: 'Required',
                        value: field.required,
                        onChanged: (v) =>
                            _update(field.copyWith(required: v)),
                      ),
                      _CheckboxProp(
                        label: 'Readonly',
                        value: field.readonly,
                        onChanged: (v) =>
                            _update(field.copyWith(readonly: v)),
                      ),
                      _CheckboxProp(
                        label: 'Invisible',
                        value: field.invisible,
                        onChanged: (v) =>
                            _update(field.copyWith(invisible: v)),
                      ),
                      _CheckboxProp(
                        label: 'No Label (nolabel)',
                        value: field.nolabel,
                        onChanged: (v) =>
                            _update(field.copyWith(nolabel: v)),
                      ),
                      _CheckboxProp(
                        label: 'Optional (hide column)',
                        value: field.optional,
                        onChanged: (v) =>
                            _update(field.copyWith(optional: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Layout ─────────────────────────────────────────────
                  _Section(
                    title: 'Layout',
                    children: [
                      _DropdownProp<int?>(
                        label: 'Colspan',
                        value: field.colspan,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('(default)')),
                          ...AppConstants.colspanOptions.map((n) =>
                              DropdownMenuItem(
                                  value: n, child: Text('$n'))),
                        ],
                        onChanged: (v) => _update(field.copyWith(colspan: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Advanced ───────────────────────────────────────────
                  _ExpandableSection(
                    title: 'Advanced',
                    children: [
                      _PropTextField(
                        label: 'Domain',
                        controller: _domainCtrl,
                        hint: "[('active', '=', True)]",
                        onChanged: (v) => _update(
                            field.copyWith(domain: v.isEmpty ? null : v)),
                      ),
                      _PropTextField(
                        label: 'attrs',
                        controller: _attrsCtrl,
                        hint: "{'invisible': [('state','=','done')]}",
                        onChanged: (v) => _update(
                            field.copyWith(attrs: v.isEmpty ? null : v)),
                      ),
                      _PropTextField(
                        label: 'groups',
                        controller: _groupsCtrl,
                        hint: 'base.group_user',
                        onChanged: (v) => _update(
                            field.copyWith(groups: v.isEmpty ? null : v)),
                      ),
                      _PropTextField(
                        label: 'Comodel (for relational)',
                        controller: _comodelCtrl,
                        hint: 'res.partner',
                        onChanged: (v) => _update(
                            field.copyWith(comodel: v.isEmpty ? null : v)),
                      ),
                      _PropTextField(
                        label: 'Help / Tooltip',
                        controller: _helpCtrl,
                        hint: 'Tooltip text shown on hover',
                        onChanged: (v) => _update(
                            field.copyWith(help: v.isEmpty ? null : v)),
                      ),
                    ],
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

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _PanelHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  const _PanelHeader({
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: AppTheme.fieldTypeBadge),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sectionTitle),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final List<Widget> children;
  const _ExpandableSection({required this.title, required this.children});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(widget.title, style: AppTheme.sectionTitle),
              const SizedBox(width: 4),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 10),
          ...widget.children,
        ],
      ],
    );
  }
}

class _PropTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  const _PropTextField({
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

class _CheckboxProp extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckboxProp({
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

class _DropdownProp<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownProp({
    required this.label,
    this.value,
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
