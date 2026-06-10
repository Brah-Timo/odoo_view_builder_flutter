// lib/services/export/download_service.dart
//
// Handles in-browser XML downloads on the web platform.
// On mobile/desktop it delegates to FileHandler for a native save.
// Uses `universal_html` for the web blob trick.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'file_handler.dart';

// ---------------------------------------------------------------------------
// Web-only import shim
// ---------------------------------------------------------------------------
// We conditionally import the web implementation so the package still
// compiles on non-web targets.
import 'download_service_stub.dart'
    if (dart.library.html) 'download_service_web.dart' as _web;

// ---------------------------------------------------------------------------
// DownloadResult
// ---------------------------------------------------------------------------

class DownloadResult {
  final bool success;
  final String? filePath; // null on web
  final String? error;

  const DownloadResult._({
    required this.success,
    this.filePath,
    this.error,
  });

  factory DownloadResult.ok({String? filePath}) =>
      DownloadResult._(success: true, filePath: filePath);

  factory DownloadResult.fail(String error) =>
      DownloadResult._(success: false, error: error);
}

// ---------------------------------------------------------------------------
// DownloadService
// ---------------------------------------------------------------------------

/// Unified download API that works across all Flutter targets.
///
/// - **Web**: triggers a browser `<a download>` click via `universal_html`.
/// - **Mobile / Desktop**: writes the file to disk via [FileHandler].
class DownloadService {
  DownloadService._();

  // ── Text / XML ──────────────────────────────────────────────────────────

  /// Download [content] (UTF-8) as [fileName].
  static Future<DownloadResult> downloadText({
    required String content,
    required String fileName,
    String mimeType = 'application/xml',
  }) async {
    if (kIsWeb) {
      return _downloadOnWeb(
        bytes: Uint8List.fromList(utf8.encode(content)),
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    final result = await FileHandler.writeTextFile(
      fileName: fileName,
      content: content,
      subDirectory: 'OdooViewBuilder',
    );

    return result.success
        ? DownloadResult.ok(filePath: result.absolutePath)
        : DownloadResult.fail(result.error ?? 'Unknown write error');
  }

  /// Download raw [bytes] as [fileName].
  static Future<DownloadResult> downloadBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
  }) async {
    if (kIsWeb) {
      return _downloadOnWeb(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
    }

    final result = await FileHandler.writeBytesFile(
      fileName: fileName,
      bytes: bytes,
      subDirectory: 'OdooViewBuilder',
    );

    return result.success
        ? DownloadResult.ok(filePath: result.absolutePath)
        : DownloadResult.fail(result.error ?? 'Unknown write error');
  }

  // ── Private ─────────────────────────────────────────────────────────────

  static DownloadResult _downloadOnWeb({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    try {
      _web.triggerBrowserDownload(
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
      );
      return DownloadResult.ok();
    } catch (e) {
      return DownloadResult.fail('Web download failed: $e');
    }
  }
}
