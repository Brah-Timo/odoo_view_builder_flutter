// lib/services/export/download_service_web.dart
//
// Web implementation — uses universal_html to trigger a browser download.

import 'dart:convert';
import 'dart:typed_data';

import 'package:universal_html/html.dart' as html;

/// Triggers a browser file download via a temporary anchor element.
void triggerBrowserDownload({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  final base64Data = base64Encode(bytes);
  final dataUrl = 'data:$mimeType;base64,$base64Data';

  final anchor = html.AnchorElement(href: dataUrl)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
