// lib/services/analytics/crash_reporter.dart
//
// Production crash and error reporting service.
//
// Architecture
// ────────────
// Firebase Crashlytics is the recommended production backend.
// When Crashlytics is not configured the service captures errors in an
// in-memory ring buffer and writes them to a local log file (non-web).
//
// To enable Crashlytics:
//   1. Run `flutterfire configure` in the project root.
//   2. Uncomment the firebase_* lines in pubspec.yaml.
//   3. Uncomment the Crashlytics import and implementation below.
//   4. Call `await CrashReporter.init(useCrashlytics: true)` in main.dart.

import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

// ── Conditional Crashlytics import ──────────────────────────────────────
// Uncomment when firebase_crashlytics is added to pubspec.yaml:
//
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// ---------------------------------------------------------------------------
// CrashSeverity
// ---------------------------------------------------------------------------

/// Severity levels for recorded errors and non-fatal issues.
enum CrashSeverity {
  /// Informational — useful context, not an actual error.
  info,

  /// Warning — degraded behaviour but the app continues.
  warning,

  /// Error — a recoverable failure that should be investigated.
  error,

  /// Fatal — unrecoverable; crash or data-loss scenario.
  fatal,
}

// ---------------------------------------------------------------------------
// CrashReport
// ---------------------------------------------------------------------------

/// A single captured crash / error record.
class CrashReport {
  final String id;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final CrashSeverity severity;
  final Map<String, String> context;
  final DateTime timestamp;

  const CrashReport({
    required this.id,
    required this.message,
    required this.severity,
    required this.context,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('[$severity] $message  @${timestamp.toIso8601String()}')
      ..writeln('Context: $context');
    if (error != null) buf.writeln('Error: $error');
    if (stackTrace != null) buf.writeln('StackTrace:\n$stackTrace');
    return buf.toString();
  }

  /// Single-line compact representation for log files.
  String toLogLine() {
    final errPart = error != null ? ' | error=${error.runtimeType}' : '';
    return '${timestamp.toIso8601String()} [${severity.name.toUpperCase()}] '
        '$message$errPart context=$context';
  }
}

// ---------------------------------------------------------------------------
// CrashReporter
// ---------------------------------------------------------------------------

/// Singleton error / crash reporting service.
///
/// **Usage — in `main.dart`:**
/// ```dart
/// await CrashReporter.init();
///
/// // Capture Flutter framework errors
/// FlutterError.onError = CrashReporter.instance.onFlutterError;
///
/// // Capture uncaught Dart async errors
/// PlatformDispatcher.instance.onError = (error, stack) {
///   CrashReporter.instance.recordFatal(error, stack);
///   return true;
/// };
/// ```
///
/// **Usage — throughout the app:**
/// ```dart
/// try {
///   ...
/// } catch (e, st) {
///   CrashReporter.instance.recordError(
///     e, st,
///     context: {'screen': 'ExportScreen', 'action': 'exportXml'},
///   );
/// }
/// ```
class CrashReporter {
  CrashReporter._();

  static CrashReporter? _instance;

  /// Initialized singleton.
  static CrashReporter get instance {
    assert(_instance != null,
        'CrashReporter.init() must be called before accessing instance.');
    return _instance!;
  }

  // ── Internal state ─────────────────────────────────────────────────────

  final Logger _log = Logger('CrashReporter');

  bool _useCrashlytics = false;
  bool _enabled = true;
  int _reportCounter = 0;

  // Ring buffer — keeps the last 200 reports in memory.
  final Queue<CrashReport> _reports = Queue();
  static const int _maxReports = 200;

  // Local log file path (non-web, non-Crashlytics).
  String? _logFilePath;

  // ── Crashlytics backend (uncomment to enable) ──────────────────────────
  // FirebaseCrashlytics? _crashlytics;

  // ── Initialization ──────────────────────────────────────────────────────

  /// Initialize the service.
  ///
  /// [useCrashlytics] — enable when `firebase_crashlytics` is configured.
  /// [enableLocalLog] — persist reports to a local file (non-web only).
  static Future<void> init({
    bool useCrashlytics = false,
    bool enableLocalLog = true,
  }) async {
    if (_instance != null) return;

    final reporter = CrashReporter._();
    reporter._useCrashlytics = useCrashlytics;

    if (useCrashlytics) {
      // ── Crashlytics bootstrap ──────────────────────────────────────────
      // Uncomment when firebase_crashlytics is available:
      //
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      // reporter._crashlytics = FirebaseCrashlytics.instance;
      // await reporter._crashlytics!
      //     .setCrashlyticsCollectionEnabled(!kDebugMode);
      // reporter._log.info('Crashlytics initialized.');
      //
      reporter._log.warning(
          'useCrashlytics=true but firebase_crashlytics is not yet activated. '
          'Falling back to local log.');
      reporter._useCrashlytics = false;
    }

    if (enableLocalLog && !kIsWeb) {
      reporter._logFilePath = await _resolveLogFilePath();
      reporter._log.info('Crash log file: ${reporter._logFilePath}');
    }

    _instance = reporter;
    reporter._log.info(
        'CrashReporter initialized '
        '(backend: ${reporter._useCrashlytics ? 'Crashlytics' : 'local'}).');
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Whether crash reporting is active.
  bool get isEnabled => _enabled;

  /// Enable or disable crash reporting (respects user consent).
  void setEnabled(bool value) {
    _enabled = value;
    _log.info('CrashReporter ${value ? 'enabled' : 'disabled'}.');
    // _crashlytics?.setCrashlyticsCollectionEnabled(value);
  }

  // ── Error recording ─────────────────────────────────────────────────────

  /// Record a non-fatal [error] with an optional [stackTrace].
  ///
  /// [message] — human-readable description.
  /// [context] — arbitrary key/value metadata (screen, action, etc.).
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? message,
    Map<String, String>? context,
    CrashSeverity severity = CrashSeverity.error,
  }) async {
    if (!_enabled) return;

    final report = _buildReport(
      message: message ?? error.toString(),
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      context: context ?? {},
    );

    await _dispatch(report);
  }

  /// Record a fatal error (e.g. unhandled exception).
  Future<void> recordFatal(
    Object error,
    StackTrace stackTrace, {
    Map<String, String>? context,
  }) async {
    await recordError(
      error,
      stackTrace,
      message: 'FATAL: ${error.runtimeType}',
      severity: CrashSeverity.fatal,
      context: context,
    );
  }

  /// Record a plain message (no exception object).
  Future<void> recordMessage(
    String message, {
    CrashSeverity severity = CrashSeverity.warning,
    Map<String, String>? context,
  }) async {
    if (!_enabled) return;

    final report = _buildReport(
      message: message,
      severity: severity,
      context: context ?? {},
    );

    await _dispatch(report);
  }

  /// Handler compatible with `FlutterError.onError`.
  ///
  /// ```dart
  /// FlutterError.onError = CrashReporter.instance.onFlutterError;
  /// ```
  Future<void> onFlutterError(FlutterErrorDetails details) async {
    await recordError(
      details.exception,
      details.stack ?? StackTrace.empty,
      message: details.exceptionAsString(),
      severity: details.silent ? CrashSeverity.warning : CrashSeverity.fatal,
      context: {
        'library': details.library ?? 'unknown',
        'context': details.context?.toDescription() ?? '',
      },
    );
  }

  // ── Key-value metadata ──────────────────────────────────────────────────

  /// Attach a persistent custom key/value pair to all future reports.
  Future<void> setCustomKey(String key, Object value) async {
    _log.fine('CustomKey: $key = $value');
    // await _crashlytics?.setCustomKey(key, value);
  }

  /// Identify the current user (e.g. after login).
  Future<void> setUserId(String userId) async {
    _log.fine('UserId: $userId');
    // await _crashlytics?.setUserIdentifier(userId);
  }

  // ── Diagnostics ─────────────────────────────────────────────────────────

  /// Returns a read-only snapshot of in-memory reports.
  List<CrashReport> get reports => List.unmodifiable(_reports);

  /// Total number of reports captured since init.
  int get reportCount => _reportCounter;

  /// Clears the in-memory report buffer.
  void clearReports() => _reports.clear();

  /// Reads the on-disk log file content (non-web only).
  /// Returns `null` if no log file exists.
  Future<String?> readLogFile() async {
    if (kIsWeb || _logFilePath == null) return null;
    try {
      final file = File(_logFilePath!);
      if (!await file.exists()) return null;
      return file.readAsString();
    } catch (e) {
      _log.warning('Could not read log file: $e');
      return null;
    }
  }

  /// Deletes the on-disk log file.
  Future<bool> clearLogFile() async {
    if (kIsWeb || _logFilePath == null) return false;
    try {
      final file = File(_logFilePath!);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  CrashReport _buildReport({
    required String message,
    required CrashSeverity severity,
    required Map<String, String> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _reportCounter++;
    return CrashReport(
      id: 'cr_$_reportCounter',
      message: message,
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      context: context,
      timestamp: DateTime.now().toUtc(),
    );
  }

  Future<void> _dispatch(CrashReport report) async {
    // 1. In-memory buffer
    if (_reports.length >= _maxReports) _reports.removeFirst();
    _reports.addLast(report);

    // 2. Console (debug builds)
    if (kDebugMode) {
      _log.warning(report.toLogLine());
      if (report.stackTrace != null) {
        _log.fine(report.stackTrace.toString());
      }
    }

    // 3. Local log file
    if (_logFilePath != null) {
      await _appendToLogFile(report);
    }

    // 4. Crashlytics backend
    if (_useCrashlytics) {
      await _sendToCrashlytics(report);
    }
  }

  Future<void> _appendToLogFile(CrashReport report) async {
    if (_logFilePath == null) return;
    try {
      final file = File(_logFilePath!);
      await file.writeAsString(
        '${report.toLogLine()}\n',
        mode: FileMode.append,
        flush: true,
      );

      // Rotate the log file when it exceeds 2 MB.
      final size = await file.length();
      if (size > 2 * 1024 * 1024) {
        await _rotateLogFile(file);
      }
    } catch (e) {
      _log.warning('Could not append to log file: $e');
    }
  }

  /// Rename the current log file to `.bak` and start fresh.
  Future<void> _rotateLogFile(File current) async {
    try {
      final backupPath = '${current.path}.bak';
      final backup = File(backupPath);
      if (await backup.exists()) await backup.delete();
      await current.rename(backupPath);
      _log.info('Log file rotated to $backupPath');
    } catch (e) {
      _log.warning('Log rotation failed: $e');
    }
  }

  Future<void> _sendToCrashlytics(CrashReport report) async {
    try {
      if (report.error != null && report.stackTrace != null) {
        // await _crashlytics?.recordError(
        //   report.error!,
        //   report.stackTrace,
        //   reason: report.message,
        //   fatal: report.severity == CrashSeverity.fatal,
        // );
      } else {
        // await _crashlytics?.log(report.toLogLine());
      }
    } catch (e) {
      _log.warning('Crashlytics dispatch failed: $e');
    }
  }

  static Future<String> _resolveLogFilePath() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${dir.path}/OdooViewBuilder/logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      return '${logDir.path}/crash_report.log';
    } catch (_) {
      // Fallback to temp directory.
      return '${Directory.systemTemp.path}/odoo_view_builder_crash.log';
    }
  }
}
