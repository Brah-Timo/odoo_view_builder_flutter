// lib/presentation/widgets/xml/xml_preview_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../providers/xml_generator_provider.dart';
import '../../providers/settings_provider.dart';
import 'xml_highlighter.dart';

class XmlPreviewWidget extends ConsumerStatefulWidget {
  const XmlPreviewWidget({super.key});

  @override
  ConsumerState<XmlPreviewWidget> createState() => _XmlPreviewWidgetState();
}

class _XmlPreviewWidgetState extends ConsumerState<XmlPreviewWidget> {
  bool _archOnly = false;
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final xml = _archOnly
        ? ref.watch(archXmlProvider)
        : ref.watch(liveXmlProvider);
    final showLines = ref.watch(showLineNumbersProvider);

    return Container(
      color: const Color(0xFF1E1E2E),
      child: Column(
        children: [
          _buildHeader(xml),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(12),
              child: XmlHighlighter(
                xml: xml,
                showLineNumbers: showLines,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String xml) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF2D2D3F),
      child: Row(
        children: [
          const Text(
            'XML Preview',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _XmlChip(
            label: 'Full',
            selected: !_archOnly,
            onTap: () => setState(() => _archOnly = false),
          ),
          const SizedBox(width: 4),
          _XmlChip(
            label: 'Arch only',
            selected: _archOnly,
            onTap: () => setState(() => _archOnly = true),
          ),
          const Spacer(),
          Text(
            '${xml.split('\n').length} lines',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
            tooltip: 'Copy XML',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: xml));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _XmlChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _XmlChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? AppTheme.primaryLight
                : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
