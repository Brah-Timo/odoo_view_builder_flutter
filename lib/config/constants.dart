// lib/config/constants.dart

/// Global application constants
class AppConstants {
  AppConstants._();

  // ─── App Info ────────────────────────────────────────────────────────────────
  static const String appName = 'Odoo View Builder';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appTagline = 'Build Odoo Views Without Writing XML';

  // ─── Supported Odoo Versions ─────────────────────────────────────────────────
  static const List<String> supportedOdooVersions = [
    '14.0',
    '15.0',
    '16.0',
    '17.0',
  ];

  // ─── Default Values ──────────────────────────────────────────────────────────
  static const String defaultModel = 'res.partner';
  static const String defaultViewId = 'view_custom_form_001';
  static const String defaultModuleName = 'custom_module';
  static const int defaultColspan = 1;

  // ─── Field Types ─────────────────────────────────────────────────────────────
  static const List<String> basicFieldTypes = [
    'char',
    'integer',
    'float',
    'boolean',
    'date',
    'datetime',
    'text',
    'html',
    'binary',
  ];

  static const List<String> relationFieldTypes = [
    'many2one',
    'many2many',
    'one2many',
    'selection',
    'reference',
  ];

  static const List<String> allFieldTypes = [
    ...basicFieldTypes,
    ...relationFieldTypes,
  ];

  // ─── Widget Types per Field Type ─────────────────────────────────────────────
  static const Map<String, List<String>> fieldWidgets = {
    'char': ['text', 'email', 'url', 'phone', 'char', 'password'],
    'integer': ['integer', 'progressbar', 'handle'],
    'float': ['float', 'monetary', 'progressbar', 'percentage'],
    'boolean': ['boolean', 'toggle_button'],
    'date': ['date', 'date_range'],
    'datetime': ['datetime'],
    'selection': ['selection', 'radio', 'priority'],
    'many2one': ['many2one', 'many2one_tags', 'statusbar', 'selection'],
    'many2many': ['many2many_tags', 'many2many', 'many2many_checkboxes'],
    'one2many': ['one2many', 'many2many_list'],
    'text': ['text'],
    'html': ['html', 'text'],
    'binary': ['binary', 'image', 'pdf_viewer'],
  };

  // ─── Group ColSpan Options ────────────────────────────────────────────────────
  static const List<int> colspanOptions = [1, 2, 3, 4, 5, 6];

  // ─── Validation ──────────────────────────────────────────────────────────────
  static const int maxNestedGroupDepth = 3;
  static const int maxFieldsPerView = 200;
  static const int maxFieldNameLength = 64;

  // ─── Canvas Grid ─────────────────────────────────────────────────────────────
  static const int defaultFormColumns = 2;
  static const double canvasPadding = 24.0;
  static const double fieldItemHeight = 56.0;
  static const double groupHeaderHeight = 40.0;

  // ─── Panel Dimensions ────────────────────────────────────────────────────────
  static const double palettePanelWidth = 260.0;
  static const double propertiesPanelWidth = 300.0;
  static const double xmlPreviewPanelWidth = 420.0;
  static const double appBarHeight = 60.0;

  // ─── Animation Durations ─────────────────────────────────────────────────────
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // ─── Local DB ────────────────────────────────────────────────────────────────
  static const String dbName = 'odoo_view_builder.db';
  static const int dbVersion = 1;
  static const String tableViews = 'views';
  static const String tableFields = 'fields';
  static const String tableGroups = 'groups';

  // ─── SharedPreferences Keys ──────────────────────────────────────────────────
  static const String prefThemeMode = 'theme_mode';
  static const String prefLastOpenedView = 'last_opened_view';
  static const String prefOdooVersion = 'odoo_version';
  static const String prefIndentSize = 'indent_size';
  static const String prefShowLineNumbers = 'show_line_numbers';
  static const String prefAutoSave = 'auto_save';
  static const String prefDefaultModel = 'default_model';
  static const String prefDefaultModule = 'default_module';

  // ─── Odoo Reserved Names ─────────────────────────────────────────────────────
  static const List<String> reservedFieldNames = [
    'id',
    'create_uid',
    'create_date',
    'write_uid',
    'write_date',
    '__last_update',
    'display_name',
  ];

  // ─── XML Generation ──────────────────────────────────────────────────────────
  static const int xmlIndentSize = 4;
  static const String xmlEncoding = 'utf-8';
  static const String xmlVersion = '1.0';

  // ─── Export ──────────────────────────────────────────────────────────────────
  static const String exportFileName = 'views.xml';
  static const String exportMimeType = 'application/xml';

  // ─── Common Odoo Models ──────────────────────────────────────────────────────
  static const List<String> commonOdooModels = [
    'res.partner',
    'res.users',
    'sale.order',
    'sale.order.line',
    'purchase.order',
    'purchase.order.line',
    'account.move',
    'account.move.line',
    'stock.picking',
    'stock.move',
    'mrp.production',
    'project.task',
    'project.project',
    'crm.lead',
    'hr.employee',
    'product.template',
    'product.product',
  ];
}
