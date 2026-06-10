// lib/services/analytics/analytics_service.dart
//
// Production analytics service.
//
// Architecture
// ────────────
// Firebase Analytics is the primary backend when the user configures Firebase
// (flutterfire configure). When Firebase is not configured the service falls
// back to a lightweight local event log stored in memory (useful for testing
// and for environments where Firebase is not desired).
//
// To enable Firebase:
//   1. Run `flutterfire configure` in the project root.
//   2. Uncomment the firebase_* lines in pubspec.yaml.
//   3. Uncomment the firebase imports and implementation sections below.
//   4. Call `await AnalyticsService.init(useFirebase: true)` in main.dart.

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

// ── Conditional Firebase import ──────────────────────────────────────────
// Uncomment when firebase_analytics is added to pubspec.yaml:
//
// import 'package:firebase_analytics/firebase_analytics.dart';

// ---------------------------------------------------------------------------
// Event constants
// ---------------------------------------------------------------------------

/// Predefined analytics event names — keep in sync with your analytics schema.
abstract class AnalyticsEvents {
  // App lifecycle
  static const String appOpened = 'app_opened';
  static const String appBackgrounded = 'app_backgrounded';

  // View management
  static const String viewCreated = 'view_created';
  static const String viewOpened = 'view_opened';
  static const String viewDeleted = 'view_deleted';
  static const String viewDuplicated = 'view_duplicated';

  // Editing
  static const String fieldAdded = 'field_added';
  static const String fieldRemoved = 'field_removed';
  static const String fieldReordered = 'field_reordered';
  static const String fieldPropertiesChanged = 'field_properties_changed';
  static const String groupAdded = 'group_added';
  static const String groupRemoved = 'group_removed';

  // Export
  static const String exportXml = 'export_xml';
  static const String exportCopied = 'export_copied';
  static const String exportShared = 'export_shared';
  static const String exportDownloaded = 'export_downloaded';

  // Import
  static const String importXml = 'import_xml';
  static const String importFailed = 'import_failed';

  // Templates
  static const String templateApplied = 'template_applied';

  // Odoo API
  static const String odooConnected = 'odoo_connected';
  static const String odooFieldsFetched = 'odoo_fields_fetched';
  static const String odooConnectionFailed = 'odoo_connection_failed';

  // Errors / Warnings
  static const String validationError = 'validation_error';
  static const String xmlError = 'xml_error';
}

// ---------------------------------------------------------------------------
// AnalyticsEvent
// ---------------------------------------------------------------------------

/// A single captured analytics event.
class AnalyticsEvent {
  final String name;
  final Map<String, Object> parameters;
  final DateTime timestamp;

  const AnalyticsEvent({
    required this.name,
    required this.parameters,
    required this.timestamp,
  });

  @override
  String toString() => 'AnalyticsEvent($name, $parameters)';
}

// ---------------------------------------------------------------------------
// AnalyticsService
// ---------------------------------------------------------------------------

/// Singleton analytics service.
///
/// Usage:
/// ```dart
/// await AnalyticsService.init();
/// AnalyticsService.instance.logEvent(AnalyticsEvents.viewCreated,
///     parameters: {'view_type': 'form', 'model': 'res.partner'});
/// ```
class AnalyticsService {
  AnalyticsService._();

  static AnalyticsService? _instance;

  /// Initialized singleton.
  static AnalyticsService get instance {
    assert(_instance != null,
        'AnalyticsService.init() must be called before accessing instance.');
    return _instance!;
  }

  // ── Internal state ────────────────────────────────────────────────────

  final Logger _log = Logger('AnalyticsService');

  bool _useFirebase = false;
  bool _enabled = true;

  // In-memory event queue (capped at 500 entries for safety).
  final Queue<AnalyticsEvent> _localEvents = Queue();
  static const int _maxLocalEvents = 500;

  // ── Firebase backend (uncomment to enable) ─────────────────────────────
  // FirebaseAnalytics? _firebase;

  // ── Initialization ─────────────────────────────────────────────────────

  /// Initialize the service.
  ///
  /// [useFirebase] — set to `true` and ensure `firebase_core` / `firebase_analytics`
  /// are in `pubspec.yaml` and Firebase is configured via `flutterfire configure`.
  static Future<void> init({bool useFirebase = false}) async {
    if (_instance != null) return;

    final service = AnalyticsService._();
    service._useFirebase = useFirebase;

    if (useFirebase) {
      // ── Firebase initialization ──────────────────────────────────────
      // Uncomment when firebase_analytics is available:
      //
      // await Firebase.initializeApp(
      //   options: DefaultFirebaseOptions.currentPlatform,
      // );
      // service._firebase = FirebaseAnalytics.instance;
      // service._log.info('Firebase Analytics initialized.');
      //
      service._log.warning(
          'useFirebase=true but Firebase packages are not yet activated. '
          'Falling back to local event log.');
      service._useFirebase = false;
    }

    _instance = service;
    service._log.info(
        'AnalyticsService initialized (backend: ${service._useFirebase ? 'Firebase' : 'local'})');
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Whether analytics collection is active.
  bool get isEnabled => _enabled;

  /// Enable or disable analytics globally (respects user consent).
  void setEnabled(bool value) {
    _enabled = value;
    _log.info('Analytics ${value ? 'enabled' : 'disabled'}');

    // _firebase?.setAnalyticsCollectionEnabled(value);
  }

  /// Log a named analytics event with optional [parameters].
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_enabled) return;

    final params = parameters ?? const {};
    final event = AnalyticsEvent(
      name: name,
      parameters: params,
      timestamp: DateTime.now(),
    );

    // Always log locally
    _storeLocally(event);

    // Also forward to Firebase when enabled
    if (_useFirebase) {
      await _logToFirebase(name, params);
    }

    if (kDebugMode) {
      _log.fine('Event: $name  params: $params');
    }
  }

  /// Set a persistent user property (e.g. subscription tier).
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_enabled) return;
    _log.fine('UserProperty: $name = $value');

    // await _firebase?.setUserProperty(name: name, value: value);
  }

  /// Set the analytics user ID (call after login, clear on logout).
  Future<void> setUserId(String? userId) async {
    if (!_enabled) return;
    _log.fine('UserId: $userId');

    // await _firebase?.setUserId(id: userId);
  }

  /// Returns a read-only list of locally recorded events.
  List<AnalyticsEvent> get localEvents => List.unmodifiable(_localEvents);

  /// Clears the local in-memory event log.
  void clearLocalEvents() => _localEvents.clear();

  // ── Convenience wrappers ──────────────────────────────────────────────

  Future<void> logViewCreated(String viewType, String model) =>
      logEvent(AnalyticsEvents.viewCreated,
          parameters: {'view_type': viewType, 'model': model});

  Future<void> logExport(String method, String viewType) =>
      logEvent(AnalyticsEvents.exportXml,
          parameters: {'method': method, 'view_type': viewType});

  Future<void> logFieldAdded(String fieldType) =>
      logEvent(AnalyticsEvents.fieldAdded,
          parameters: {'field_type': fieldType});

  Future<void> logTemplateApplied(String templateId) =>
      logEvent(AnalyticsEvents.templateApplied,
          parameters: {'template_id': templateId});

  Future<void> logValidationError(String context, int errorCount) =>
      logEvent(AnalyticsEvents.validationError,
          parameters: {'context': context, 'error_count': errorCount});

  // ── Private helpers ───────────────────────────────────────────────────

  void _storeLocally(AnalyticsEvent event) {
    if (_localEvents.length >= _maxLocalEvents) {
      _localEvents.removeFirst();
    }
    _localEvents.addLast(event);
  }

  Future<void> _logToFirebase(
      String name, Map<String, Object> params) async {
    try {
      // await _firebase?.logEvent(name: name, parameters: params);
    } catch (e) {
      _log.warning('Firebase logEvent failed: $e');
    }
  }
}
