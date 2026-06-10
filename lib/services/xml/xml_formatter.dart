// lib/services/xml/xml_formatter.dart

import 'package:xml/xml.dart' as xml;

/// Formats and transforms XML strings for display and export
class XmlFormatter {
  XmlFormatter._();

  // ─── Pretty Print ─────────────────────────────────────────────────────────────

  /// Returns a well-indented, human-readable XML string
  static String prettyPrint(String rawXml, {int indentSize = 4}) {
    try {
      final doc = xml.XmlDocument.parse(rawXml);
      return _serializeNode(doc, 0, indentSize).trim();
    } catch (e) {
      // If parsing fails, return original
      return rawXml;
    }
  }

  static String _serializeNode(xml.XmlNode node, int depth, int indent) {
    final buf = StringBuffer();
    final pad = ' ' * (depth * indent);

    if (node is xml.XmlDocument) {
      for (final child in node.children) {
        buf.write(_serializeNode(child, depth, indent));
      }
    } else if (node is xml.XmlProcessing) {
      buf.writeln('$pad<?${node.target} ${node.value}?>');
    } else if (node is xml.XmlComment) {
      buf.writeln('$pad<!--${node.value}-->');
    } else if (node is xml.XmlElement) {
      final attrs = _formatAttributes(node.attributes);
      final tag = node.localName;

      if (node.children.isEmpty) {
        buf.writeln('$pad<$tag$attrs/>');
      } else {
        final textChildren = node.children.whereType<xml.XmlText>().toList();
        final elementChildren =
            node.children.whereType<xml.XmlElement>().toList();

        if (elementChildren.isEmpty && textChildren.isNotEmpty) {
          // Inline text content
          final text = textChildren.map((t) => t.value.trim()).join('');
          if (text.isEmpty) {
            buf.writeln('$pad<$tag$attrs/>');
          } else {
            buf.writeln('$pad<$tag$attrs>$text</$tag>');
          }
        } else {
          buf.writeln('$pad<$tag$attrs>');
          for (final child in node.children) {
            if (child is xml.XmlText && child.value.trim().isEmpty) continue;
            buf.write(_serializeNode(child, depth + 1, indent));
          }
          buf.writeln('$pad</$tag>');
        }
      }
    } else if (node is xml.XmlText) {
      final text = node.value.trim();
      if (text.isNotEmpty) buf.writeln('$pad$text');
    } else if (node is xml.XmlCDATA) {
      buf.writeln('$pad<![CDATA[${node.value}]]>');
    }

    return buf.toString();
  }

  static String _formatAttributes(Iterable<xml.XmlAttribute> attrs) {
    if (attrs.isEmpty) return '';
    final parts = attrs.map((a) => '${a.name}="${a.value}"').join(' ');
    return ' $parts';
  }

  // ─── Minify ───────────────────────────────────────────────────────────────────

  /// Returns a compact, single-line XML string
  static String minify(String xmlContent) {
    try {
      return xmlContent
          .replaceAll(RegExp(r'\n\s*'), '')
          .replaceAll(RegExp(r'>\s+<'), '><')
          .trim();
    } catch (_) {
      return xmlContent;
    }
  }

  // ─── Strip Comments ──────────────────────────────────────────────────────────

  static String stripComments(String xmlContent) {
    return xmlContent.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
  }

  // ─── Syntax Highlight Spans ──────────────────────────────────────────────────

  /// Tokenizes XML for syntax highlighting.
  /// Returns a list of [XmlToken] objects.
  static List<XmlToken> tokenize(String xmlContent) {
    final tokens = <XmlToken>[];
    final pattern = RegExp(
      r'(<!--.*?-->)|'           // comment
      r'(<\?[^?]*\?>)|'         // processing instruction
      r'(</[a-zA-Z:_][^\s>]*>)|' // closing tag
      r'(<[a-zA-Z:_][^\s>/]*)'  // opening tag start
      r'|(/>)|'                  // self-close
      r'|(>)|'                   // close bracket
      r'(\s[a-zA-Z:_][^\s=]*)=' // attribute name
      r'("([^"]*)")|'            // attribute value
      r"('([^']*)')|"            // attribute value single-quote
      r'([^<]+)',                // text content
      dotAll: true,
    );

    for (final m in pattern.allMatches(xmlContent)) {
      if (m.group(1) != null) {
        tokens.add(XmlToken(XmlTokenType.comment, m.group(1)!));
      } else if (m.group(2) != null) {
        tokens.add(XmlToken(XmlTokenType.processing, m.group(2)!));
      } else if (m.group(3) != null) {
        tokens.add(XmlToken(XmlTokenType.closingTag, m.group(3)!));
      } else if (m.group(4) != null) {
        tokens.add(XmlToken(XmlTokenType.openingTag, m.group(4)!));
      } else if (m.group(5) != null) {
        tokens.add(XmlToken(XmlTokenType.selfClose, '/>'));
      } else if (m.group(6) != null) {
        tokens.add(XmlToken(XmlTokenType.bracket, '>'));
      } else if (m.group(7) != null) {
        tokens.add(XmlToken(XmlTokenType.attributeName, m.group(7)!));
        if (m.group(8) != null) {
          tokens.add(XmlToken(XmlTokenType.attributeValue, m.group(8)!));
        } else if (m.group(10) != null) {
          tokens.add(XmlToken(XmlTokenType.attributeValue, m.group(10)!));
        }
      } else if (m.group(12) != null) {
        tokens.add(XmlToken(XmlTokenType.text, m.group(12)!));
      }
    }

    return tokens;
  }
}

// ─── Token Types ─────────────────────────────────────────────────────────────

enum XmlTokenType {
  openingTag,
  closingTag,
  selfClose,
  bracket,
  attributeName,
  attributeValue,
  text,
  comment,
  processing,
  cdata,
}

class XmlToken {
  final XmlTokenType type;
  final String value;

  const XmlToken(this.type, this.value);

  @override
  String toString() => 'XmlToken(${type.name}, "$value")';
}
