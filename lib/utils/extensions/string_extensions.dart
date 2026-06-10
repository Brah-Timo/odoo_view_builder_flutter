// lib/utils/extensions/string_extensions.dart

extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Convert to snake_case
  String toSnakeCase() => replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .trim();

  /// Convert to Odoo-compatible field name
  String toOdooFieldName() =>
      toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
          .replaceAll(RegExp(r'^[^a-z]+'), '')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();

  /// Check if this is a valid Odoo model name
  bool get isValidOdooModel =>
      RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(this);

  /// Check if this is a valid Odoo field name
  bool get isValidFieldName =>
      RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(this);

  /// Check if this is a valid XML identifier
  bool get isValidXmlId =>
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*$').hasMatch(this);

  /// Escape XML special characters
  String escapeXml() => replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Truncate with ellipsis
  String truncate(int max) =>
      length > max ? '${substring(0, max - 3)}...' : this;
}
