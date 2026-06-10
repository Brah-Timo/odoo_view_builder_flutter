// lib/services/export/file_handler.dart
//
// Platform-aware file I/O handler.
// Abstracts differences between mobile, desktop, and web file systems.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Result types
// ---------------------------------------------------------------------------

/// The outcome of a file write operation.
class FileWriteResult {
  final bool success;
  final String? absolutePath;
  final String? error;

  const FileWriteResult._({
    required this.success,
    this.absolutePath,
    this.error,
  });

  factory FileWriteResult.ok(String path) =>
      FileWriteResult._(success: true, absolutePath: path);

  factory FileWriteResult.fail(String error) =>
      FileWriteResult._(success: false, error: error);

  @override
  String toString() =>
      success ? 'FileWriteResult.ok($absolutePath)' : 'FileWriteResult.fail($error)';
}

/// The outcome of a file read operation.
class FileReadResult {
  final bool success;
  final String? content;
  final String? error;

  const FileReadResult._({
    required this.success,
    this.content,
    this.error,
  });

  factory FileReadResult.ok(String content) =>
      FileReadResult._(success: true, content: content);

  factory FileReadResult.fail(String error) =>
      FileReadResult._(success: false, error: error);
}

// ---------------------------------------------------------------------------
// FileHandler
// ---------------------------------------------------------------------------

/// Cross-platform file I/O.
///
/// On **mobile** (Android / iOS) files are written to
/// `getApplicationDocumentsDirectory()`.
///
/// On **desktop** (Windows / macOS / Linux) files are written to the user's
/// Downloads folder (`getDownloadsDirectory()`), falling back to Documents.
///
/// On **web** there is no file system; callers should use [DownloadService]
/// instead. All write methods return a descriptive error on web.
class FileHandler {
  FileHandler._();

  // ── Public API ─────────────────────────────────────────────────────────

  /// Write [content] as UTF-8 text to [fileName] in the platform output dir.
  ///
  /// [subDirectory] is an optional relative sub-path (e.g. `'odoo/views'`).
  static Future<FileWriteResult> writeTextFile({
    required String fileName,
    required String content,
    String? subDirectory,
  }) async {
    if (kIsWeb) {
      return FileWriteResult.fail(
          'Direct file write is not supported on web. Use DownloadService.');
    }

    try {
      final dir = await _resolveOutputDirectory(subDirectory);
      final filePath = p.join(dir, fileName);
      final file = File(filePath);
      await file.writeAsString(content, flush: true);
      return FileWriteResult.ok(file.path);
    } on FileSystemException catch (e) {
      return FileWriteResult.fail('FileSystemException: ${e.message}');
    } catch (e) {
      return FileWriteResult.fail('Unexpected error: $e');
    }
  }

  /// Write raw bytes to [fileName] in the platform output directory.
  static Future<FileWriteResult> writeBytesFile({
    required String fileName,
    required Uint8List bytes,
    String? subDirectory,
  }) async {
    if (kIsWeb) {
      return FileWriteResult.fail(
          'Direct file write is not supported on web. Use DownloadService.');
    }

    try {
      final dir = await _resolveOutputDirectory(subDirectory);
      final filePath = p.join(dir, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      return FileWriteResult.ok(file.path);
    } on FileSystemException catch (e) {
      return FileWriteResult.fail('FileSystemException: ${e.message}');
    } catch (e) {
      return FileWriteResult.fail('Unexpected error: $e');
    }
  }

  /// Read a text file from [absolutePath].
  static Future<FileReadResult> readTextFile(String absolutePath) async {
    if (kIsWeb) {
      return FileReadResult.fail('File read is not supported on web.');
    }

    try {
      final file = File(absolutePath);
      if (!await file.exists()) {
        return FileReadResult.fail('File not found: $absolutePath');
      }
      final content = await file.readAsString();
      return FileReadResult.ok(content);
    } on FileSystemException catch (e) {
      return FileReadResult.fail('FileSystemException: ${e.message}');
    } catch (e) {
      return FileReadResult.fail('Unexpected error: $e');
    }
  }

  /// Delete a file at [absolutePath]. Returns `true` on success.
  static Future<bool> deleteFile(String absolutePath) async {
    if (kIsWeb) return false;

    try {
      final file = File(absolutePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check whether a file exists at [absolutePath].
  static Future<bool> fileExists(String absolutePath) async {
    if (kIsWeb) return false;
    return File(absolutePath).exists();
  }

  /// List XML files in the default output directory.
  static Future<List<String>> listXmlFiles({String? subDirectory}) async {
    if (kIsWeb) return [];

    try {
      final dir = await _resolveOutputDirectory(subDirectory);
      final directory = Directory(dir);
      if (!await directory.exists()) return [];

      final entities = await directory.list().toList();
      return entities
          .whereType<File>()
          .where((f) => f.path.endsWith('.xml'))
          .map((f) => f.path)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns the absolute path to the output directory (creates it if needed).
  static Future<String> getOutputDirectoryPath({String? subDirectory}) async {
    return _resolveOutputDirectory(subDirectory);
  }

  // ── Private Helpers ────────────────────────────────────────────────────

  static Future<String> _resolveOutputDirectory(String? subDirectory) async {
    late String base;

    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      base = dir.path;
    } else {
      // Desktop: prefer Downloads
      final downloads = await getDownloadsDirectory();
      if (downloads != null) {
        base = downloads.path;
      } else {
        final docs = await getApplicationDocumentsDirectory();
        base = docs.path;
      }
    }

    final fullPath = subDirectory != null ? p.join(base, subDirectory) : base;
    final directory = Directory(fullPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return fullPath;
  }
}
