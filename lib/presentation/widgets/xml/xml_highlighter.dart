// lib/presentation/widgets/xml/xml_highlighter.dart

import 'package:flutter/material.dart';

/// Renders syntax-highlighted XML with optional line numbers
class XmlHighlighter extends StatelessWidget {
  final String xml;
  final bool showLineNumbers;

  const XmlHighlighter({
    super.key,
    required this.xml,
    this.showLineNumbers = true,
  });

  @override
  Widget build(BuildContext context) {
    final lines = xml.split('\n');

    if (!showLineNumbers) {
      return _buildCode(lines);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line numbers column
        _buildLineNumbers(lines.length),
        const SizedBox(width: 12),
        // Code column
        Expanded(child: _buildCode(lines)),
      ],
    );
  }

  Widget _buildLineNumbers(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(
        count,
        (index) => Text(
          '${index + 1}',
          style: const TextStyle(
            color: Color(0xFF6272A4),
            fontSize: 12,
            fontFamily: 'FiraCode',
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCode(List<String> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _HighlightedLine(line: line)).toList(),
    );
  }
}

// ─── Single highlighted line ──────────────────────────────────────────────────

class _HighlightedLine extends StatelessWidget {
  final String line;
  const _HighlightedLine({required this.line});

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      _buildTextSpan(line),
      style: const TextStyle(
        fontFamily: 'FiraCode',
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  TextSpan _buildTextSpan(String line) {
    final spans = <TextSpan>[];

    // Simple regex-based coloring (no heavy external lib needed)
    final pattern = RegExp(
      r'(<!--.*?-->)'                          // comment
      r'|(<\?[^?]*\?>)'                        // processing instruction
      r'|</([a-zA-Z:_][^\s>/]*)\s*>'          // closing tag name
      r'|<([a-zA-Z:_][^\s>/]*)'               // opening tag name
      r'|(/?>)'                                // > or />
      r'|(\s[a-zA-Z:_][a-zA-Z0-9_.\-:]*)'    // attribute name
      r'|("([^"]*)")'                          // attribute value
      r"|('([^']*)')"                          // attribute value single-quote
      r'|(&[a-zA-Z#][a-zA-Z0-9]*;)'           // entity
      "[^<>&\"']+",                              // plain text
    );

    for (final m in pattern.allMatches(line)) {
      if (m.group(1) != null) {
        // Comment
        spans.add(TextSpan(
          text: m.group(1),
          style: const TextStyle(color: Color(0xFF6272A4), fontStyle: FontStyle.italic),
        ));
      } else if (m.group(2) != null) {
        // Processing instruction
        spans.add(TextSpan(
          text: m.group(2),
          style: const TextStyle(color: Color(0xFFCDB58C)),
        ));
      } else if (m.group(3) != null) {
        // Closing tag
        spans.addAll([
          const TextSpan(
              text: '</', style: TextStyle(color: Color(0xFF89DCEB))),
          TextSpan(
              text: m.group(3),
              style: const TextStyle(color: Color(0xFFC792EA))),
          const TextSpan(
              text: '>', style: TextStyle(color: Color(0xFF89DCEB))),
        ]);
      } else if (m.group(4) != null) {
        // Opening tag name
        spans.addAll([
          const TextSpan(
              text: '<', style: TextStyle(color: Color(0xFF89DCEB))),
          TextSpan(
              text: m.group(4),
              style: const TextStyle(color: Color(0xFFC792EA))),
        ]);
      } else if (m.group(5) != null) {
        // > or />
        spans.add(TextSpan(
          text: m.group(5),
          style: const TextStyle(color: Color(0xFF89DCEB)),
        ));
      } else if (m.group(6) != null) {
        // Attribute name
        spans.add(TextSpan(
          text: m.group(6),
          style: const TextStyle(color: Color(0xFF82AAFF)),
        ));
      } else if (m.group(7) != null) {
        // Attribute value (double-quoted)
        spans.add(TextSpan(
          text: m.group(7),
          style: const TextStyle(color: Color(0xFFF3BE7E)),
        ));
      } else if (m.group(10) != null) {
        // Attribute value (single-quoted)
        spans.add(TextSpan(
          text: m.group(10),
          style: const TextStyle(color: Color(0xFFF3BE7E)),
        ));
      } else if (m.group(13) != null) {
        // XML entity
        spans.add(TextSpan(
          text: m.group(13),
          style: const TextStyle(color: Color(0xFFA6E22E)),
        ));
      } else if (m.group(14) != null) {
        // Plain text
        spans.add(TextSpan(
          text: m.group(14),
          style: const TextStyle(color: Color(0xFFCDD6F4)),
        ));
      }
    }

    return TextSpan(children: spans);
  }
}
