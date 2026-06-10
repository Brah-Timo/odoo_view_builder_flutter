// lib/config/app_config.dart

/// App-level configuration (feature flags, environment settings)
class AppConfig {
  AppConfig._();

  // ─── Feature Flags ────────────────────────────────────────────────────────────
  static const bool enableKanbanEditor = true;
  static const bool enableXmlImport = true;
  static const bool enableTemplateLibrary = true;
  static const bool enableOdooConnection = false; // future feature
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;

  // ─── Limits (Free Tier) ──────────────────────────────────────────────────────
  static const int maxViewsFreeTier = 5;
  static const int maxFieldsPerView = 50;
  static const int maxGroupsPerView = 20;
  static const int maxNestedGroupDepth = 3;

  // ─── Auto-save ───────────────────────────────────────────────────────────────
  static const Duration autoSaveInterval = Duration(seconds: 30);
  static const bool autoSaveEnabled = true;

  // ─── XML Generator ───────────────────────────────────────────────────────────
  static const bool prettyPrintXml = true;
  static const int xmlIndentSpaces = 4;
  static const bool addXmlComments = true;
  static const bool validateOnExport = true;

  // ─── UI Behaviour ────────────────────────────────────────────────────────────
  static const bool showFieldTypeIcons = true;
  static const bool enableDragHapticFeedback = true;
  static const bool showXmlPreviewByDefault = true;
  static const bool confirmDeleteField = true;
  static const bool confirmDeleteGroup = true;

  // ─── Undo / Redo ─────────────────────────────────────────────────────────────
  static const int maxUndoHistory = 50;
  static const bool enableUndoRedo = true;
}
