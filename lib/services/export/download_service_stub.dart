// lib/services/export/download_service_stub.dart
//
// Non-web stub so the project compiles on mobile/desktop.

import 'dart:typed_data';

/// Stub — never called on non-web targets.
void triggerBrowserDownload({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  throw UnsupportedError(
      'triggerBrowserDownload is only available on the web platform.');
}
