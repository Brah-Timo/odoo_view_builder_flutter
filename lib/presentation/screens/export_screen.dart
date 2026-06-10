// lib/presentation/screens/export_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../data/models/odoo_form.dart';
import '../../services/xml/xml_validator.dart';
import '../../services/export/export_manager.dart';
import '../providers/xml_generator_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final OdooView? view;
  const ExportScreen({super.key, this.view});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _minified = false;
  bool _archOnly = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _getXml() {
    if (_archOnly) {
      final repo = ref.read(xmlRepositoryProvider);
      return repo.generateArch(widget.view!);
    }
    final xml = widget.view!.generateXml();
    if (_minified) {
      final repo = ref.read(xmlRepositoryProvider);
      return repo.minify(xml);
    }
    return xml;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.view == null) {
      return const Scaffold(body: Center(child: Text('No view to export.')));
    }
    final report = XmlValidator.validateView(widget.view!);
    final xml = _getXml();

    return Scaffold(
      appBar: AppBar(
        title: Text('Export — ${widget.view!.name}'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Preview'),
            Tab(text: 'Validation'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Options bar ───────────────────────────────────────────────────
          _buildOptionsBar(),

          // ── Validation banner ─────────────────────────────────────────────
          if (!report.isValid) _buildValidationBanner(report),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                // Preview tab
                _XmlCodeView(xml: xml),

                // Validation tab
                _buildValidationTab(report),
              ],
            ),
          ),

          // ── Export actions bar ────────────────────────────────────────────
          _buildActionsBar(xml),
        ],
      ),
    );
  }

  // ─── Options Bar ─────────────────────────────────────────────────────────

  Widget _buildOptionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Text(
            'Options:',
            style: AppTheme.fieldLabel,
          ),
          const SizedBox(width: 12),
          _OptionChip(
            label: 'Arch Only',
            selected: _archOnly,
            onTap: () => setState(() => _archOnly = !_archOnly),
          ),
          const SizedBox(width: 8),
          _OptionChip(
            label: 'Minified',
            selected: _minified,
            onTap: () => setState(() => _minified = !_minified),
          ),
          const Spacer(),
          Text(
            '${widget.view!.allFields.length} fields  •  ${_getXml().length} chars',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─── Validation Banner ────────────────────────────────────────────────────

  Widget _buildValidationBanner(ValidationReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.warningColor.withOpacity(0.15),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppTheme.warningColor, size: 18),
          const SizedBox(width: 8),
          Text(
            '${report.errorCount} error(s), ${report.warningCount} warning(s) found',
            style: const TextStyle(
              color: AppTheme.warningColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _tabs.animateTo(1),
            child: const Text('See details'),
          ),
        ],
      ),
    );
  }

  // ─── Validation Tab ───────────────────────────────────────────────────────

  Widget _buildValidationTab(ValidationReport report) {
    if (report.issues.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                color: AppTheme.successColor, size: 48),
            SizedBox(height: 16),
            Text(
              'No issues found',
              style: TextStyle(
                  fontSize: 16, color: AppTheme.successColor),
            ),
            SizedBox(height: 8),
            Text('Your view is valid and ready to export.',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: report.issues.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final issue = report.issues[index];
        final color = switch (issue.severity) {
          ValidationSeverity.error => AppTheme.errorColor,
          ValidationSeverity.warning => AppTheme.warningColor,
          ValidationSeverity.info => AppTheme.infoColor,
        };
        final icon = switch (issue.severity) {
          ValidationSeverity.error => Icons.error_outline,
          ValidationSeverity.warning => Icons.warning_amber_outlined,
          ValidationSeverity.info => Icons.info_outline,
        };

        return ListTile(
          leading: Icon(icon, color: color, size: 20),
          title: Text(issue.message, style: const TextStyle(fontSize: 13)),
          subtitle: issue.path != null
              ? Text(issue.path!,
                  style: const TextStyle(
                      fontSize: 11, fontFamily: 'monospace'))
              : null,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              issue.code,
              style: AppTheme.fieldTypeBadge.copyWith(color: color),
            ),
          ),
          dense: true,
        );
      },
    );
  }

  // ─── Actions Bar ─────────────────────────────────────────────────────────

  Widget _buildActionsBar(String xml) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // Copy to clipboard
          ElevatedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: xml));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('XML copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy'),
          ),
          const SizedBox(width: 12),
          // Download as file
          ElevatedButton.icon(
            onPressed: () async {
              await ExportManager.downloadXml(
                content: xml,
                fileName: '${widget.view!.id}.xml',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('File downloaded'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
            ),
          ),
          const SizedBox(width: 12),
          // Share
          OutlinedButton.icon(
            onPressed: () async {
              await ExportManager.shareXml(
                content: xml,
                fileName: '${widget.view!.id}.xml',
              );
            },
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}

// ─── XML Code View ────────────────────────────────────────────────────────────

class _XmlCodeView extends StatelessWidget {
  final String xml;
  const _XmlCodeView({required this.xml});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          xml,
          style: AppTheme.xmlCode.copyWith(color: const Color(0xFFCDD6F4)),
        ),
      ),
    );
  }
}

// ─── Option Chip ─────────────────────────────────────────────────────────────

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
    );
  }
}
