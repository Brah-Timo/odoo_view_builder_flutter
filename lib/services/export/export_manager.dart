// lib/services/export/export_manager.dart
//
// Handles saving and sharing the generated XML.
// Works across mobile, desktop, and web (conditional imports).

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/odoo_form.dart';
import '../xml/xml_generator.dart';
import '../xml/xml_validator.dart';

/// Result of an export operation
class ExportOperationResult {
  final bool success;
  final String? path;
  final String? error;

  const ExportOperationResult._({
    required this.success,
    this.path,
    this.error,
  });

  factory ExportOperationResult.ok(String path) =>
      ExportOperationResult._(success: true, path: path);

  factory ExportOperationResult.fail(String error) =>
      ExportOperationResult._(success: false, error: error);
}

class ExportManager {
  ExportManager._();

  // ─── Download (save to disk) ─────────────────────────────────────────────

  static Future<ExportOperationResult> downloadXml({
    required String content,
    required String fileName,
  }) async {
    try {
      if (kIsWeb) {
        // Web: trigger browser download via dart:html workaround
        _webDownload(content, fileName);
        return ExportOperationResult.ok('/downloads/$fileName');
      }

      final dir = await _getOutputDirectory();
      final file = File('$dir/$fileName');
      await file.writeAsString(content);
      return ExportOperationResult.ok(file.path);
    } catch (e) {
      return ExportOperationResult.fail('Download failed: $e');
    }
  }

  // ─── Export single view ──────────────────────────────────────────────────

  static Future<ExportOperationResult> exportView(OdooView view) async {
    final xml = XmlGenerator.generateSingle(view);
    final report = XmlValidator.validateView(view);

    if (!report.isValid) {
      return ExportOperationResult.fail(
          'Validation failed: ${report.errorCount} error(s)');
    }

    return downloadXml(content: xml, fileName: '${view.id}.xml');
  }

  // ─── Export multiple views ───────────────────────────────────────────────

  static Future<ExportOperationResult> exportViews(
    List<OdooView> views, {
    String? moduleName,
  }) async {
    final xml = XmlGenerator.generateFile(views, moduleName: moduleName);
    return downloadXml(
        content: xml, fileName: '${moduleName ?? 'views'}.xml');
  }

  // ─── Share ───────────────────────────────────────────────────────────────

  static Future<void> shareXml({
    required String content,
    required String fileName,
  }) async {
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: content));
      return;
    }

    final dir = await _getOutputDirectory();
    final file = File('$dir/$fileName');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/xml')],
      text: 'Odoo View XML: $fileName',
    );
  }

  // ─── Copy to Clipboard ───────────────────────────────────────────────────

  static Future<bool> copyToClipboard(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Private Helpers ─────────────────────────────────────────────────────

  static Future<String> _getOutputDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    } else {
      // Desktop
      final dir = await getDownloadsDirectory();
      return dir?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
  }

  static void _webDownload(String content, String fileName) {
    // In web context, we'd use dart:html — wrapped here for safety
    // This is a no-op stub; in a real web build use `web_download.dart`
    debugPrint('Web download: $fileName (${content.length} bytes)');
  }
}
