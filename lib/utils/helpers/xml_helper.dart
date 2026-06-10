// lib/utils/helpers/xml_helper.dart

class XmlHelper {
  XmlHelper._();

  static String escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String indent(int level, {int size = 4}) => ' ' * (level * size);

  static bool isWellFormed(String xml) {
    int opens = 0;
    final tagPattern = RegExp(r'<(/?)([a-zA-Z][^>\s/]*)');
    for (final m in tagPattern.allMatches(xml)) {
      if (m.group(1) == '/') {
        opens--;
      } else if (!xml.substring(m.start).startsWith('<?') &&
          !xml.substring(m.start).startsWith('<!')) {
        opens++;
      }
    }
    return opens == 0;
  }
}
