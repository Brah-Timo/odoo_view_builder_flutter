// lib/utils/helpers/formatting_helper.dart
//
// Formatting utilities for dates, file sizes, numbers, XML, and strings.
// All methods are pure functions — no state, no I/O.

import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// FormattingHelper
// ---------------------------------------------------------------------------

/// Collection of static formatting helpers used across the application.
abstract class FormattingHelper {
  FormattingHelper._();

  // ── Date & time ──────────────────────────────────────────────────────────

  /// Formats [date] as `dd/MM/yyyy` (UI display).
  ///
  /// Returns `'—'` when [date] is `null`.
  static String formatDate(DateTime? date, {String locale = 'en_US'}) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy', locale).format(date.toLocal());
  }

  /// Formats [date] as `dd/MM/yyyy HH:mm` (UI display).
  ///
  /// Returns `'—'` when [date] is `null`.
  static String formatDateTime(DateTime? date, {String locale = 'en_US'}) {
    if (date == null) return '—';
    return DateFormat('dd/MM/yyyy HH:mm', locale).format(date.toLocal());
  }

  /// Returns a human-friendly relative time description.
  ///
  /// Examples:
  /// - `'just now'`      (<  60 seconds ago)
  /// - `'2 minutes ago'` (< 60 minutes ago)
  /// - `'3 hours ago'`   (< 24 hours ago)
  /// - `'yesterday'`     (1 day ago)
  /// - `'5 days ago'`    (< 30 days ago)
  /// - `'14 Jan 2024'`   (older)
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date.toLocal());

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${h == 1 ? 'hour' : 'hours'} ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 30) {
      final d = diff.inDays;
      return '$d days ago';
    }
    return DateFormat('d MMM yyyy').format(date.toLocal());
  }

  /// Formats [date] as an ISO 8601 string (`2024-01-15T14:30:00`).
  static String toIso8601(DateTime date) => date.toIso8601String();

  // ── File sizes ───────────────────────────────────────────────────────────

  /// Converts raw byte count to a human-readable string.
  ///
  /// Examples: `'512 B'`, `'1.5 KB'`, `'3.2 MB'`, `'1.1 GB'`
  static String formatFileSize(int bytes) {
    if (bytes < 0) return '0 B';
    if (bytes < 1024) return '$bytes B';

    const units = ['KB', 'MB', 'GB', 'TB'];
    double size = bytes / 1024.0;
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final formatted = size < 10
        ? size.toStringAsFixed(2)
        : size < 100
            ? size.toStringAsFixed(1)
            : size.toStringAsFixed(0);

    return '$formatted ${units[unitIndex]}';
  }

  // ── Numbers ──────────────────────────────────────────────────────────────

  /// Formats [value] with thousands separators.
  ///
  /// Example: `1234567` → `'1,234,567'`
  static String formatInteger(int value) {
    return NumberFormat('#,###', 'en_US').format(value);
  }

  /// Formats [value] as a decimal with [decimals] places.
  ///
  /// Example: `formatDecimal(1234.5678, decimals: 2)` → `'1,234.57'`
  static String formatDecimal(double value, {int decimals = 2}) {
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    return NumberFormat(pattern, 'en_US').format(value);
  }

  /// Formats [value] as a percentage string.
  ///
  /// Example: `formatPercent(0.756)` → `'75.6 %'`
  static String formatPercent(double value, {int decimals = 1}) {
    return '${(value * 100).toStringAsFixed(decimals)} %';
  }

  // ── XML / code strings ───────────────────────────────────────────────────

  /// Truncates [xml] to [maxChars] and appends `'…'` if it was longer.
  ///
  /// Useful for showing a snippet of a large XML string in the UI without
  /// causing layout overflows.
  static String truncateXml(String xml, {int maxChars = 300}) {
    if (xml.length <= maxChars) return xml;
    return '${xml.substring(0, maxChars)}…';
  }

  /// Escapes special HTML / XML characters in [text].
  ///
  /// Suitable for embedding arbitrary text inside an XML attribute value.
  ///
  /// Replacements:
  /// - `&` → `&amp;`
  /// - `<` → `&lt;`
  /// - `>` → `&gt;`
  /// - `"` → `&quot;`
  /// - `'` → `&apos;`
  static String escapeXmlEntities(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Unescapes XML entity references in [text].
  static String unescapeXmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'");
  }

  // ── String utilities ─────────────────────────────────────────────────────

  /// Converts a camelCase or PascalCase string to `snake_case`.
  ///
  /// Example: `'MyFieldName'` → `'my_field_name'`
  static String toSnakeCase(String input) {
    final exp = RegExp('(?<=[a-z0-9])([A-Z])');
    return input
        .replaceAllMapped(exp, (m) => '_${m.group(0)!}')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Converts a `snake_case` or `kebab-case` string to `Title Case`.
  ///
  /// Example: `'my_field_name'` → `'My Field Name'`
  static String toTitleCase(String input) {
    return input
        .split(RegExp(r'[_\-\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Converts a string to a valid Odoo technical field name.
  ///
  /// 1. Lowercases the string.
  /// 2. Replaces spaces and dashes with underscores.
  /// 3. Removes characters that are not alphanumeric or underscore.
  /// 4. Ensures it does not start with a digit.
  ///
  /// Example: `'My Field Name!'` → `'my_field_name'`
  static String toOdooFieldName(String input) {
    var result = input
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Strip leading digits
    result = result.replaceAll(RegExp(r'^[0-9]+'), '');

    // Collapse consecutive underscores
    result = result.replaceAll(RegExp(r'_+'), '_');

    // Strip leading/trailing underscores
    result = result.replaceAll(RegExp(r'^_|_$'), '');

    return result.isEmpty ? 'field' : result;
  }

  /// Converts an Odoo model technical name to a short display name.
  ///
  /// Example: `'sale.order.line'` → `'Sale Order Line'`
  static String modelToDisplayName(String model) {
    return model
        .split('.')
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// Pluralises an English word naively (adds `'s'` unless it already ends
  /// with `'s'`).
  static String pluralise(String word, int count) {
    if (count == 1) return word;
    if (word.endsWith('s')) return word;
    return '${word}s';
  }

  /// Truncates [text] to [maxLength] characters and appends [ellipsis].
  static String truncate(
    String text, {
    int maxLength = 60,
    String ellipsis = '…',
  }) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$ellipsis';
  }

  // ── Duration ─────────────────────────────────────────────────────────────

  /// Returns a human-readable duration string.
  ///
  /// Examples: `'5 seconds'`, `'2 minutes'`, `'1 hour 30 minutes'`
  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds} ${pluralise('second', d.inSeconds)}';
    }
    if (d.inMinutes < 60) {
      return '${d.inMinutes} ${pluralise('minute', d.inMinutes)}';
    }
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final hStr = '$h ${pluralise('hour', h)}';
    if (m == 0) return hStr;
    return '$hStr $m ${pluralise('minute', m)}';
  }

  // ── Odoo domain / context ────────────────────────────────────────────────

  /// Formats an Odoo domain list as a compact inline string.
  ///
  /// Example: `[['active', '=', True]]` → `"[['active','=',True]]"`
  static String formatDomain(List<dynamic> domain) {
    if (domain.isEmpty) return '[]';
    final parts = domain.map((clause) {
      if (clause is List && clause.length == 3) {
        final field = clause[0];
        final op = clause[1];
        final val = clause[2];
        final valStr = val is String ? "'$val'" : val.toString();
        return "['$field','$op',$valStr]";
      }
      return clause.toString();
    });
    return '[${parts.join(', ')}]';
  }

  // ── XML filename helpers ─────────────────────────────────────────────────

  /// Generates a timestamped XML export filename.
  ///
  /// Example: `'sale_order_form_2024_01_15_14_30.xml'`
  static String xmlExportFileName(String viewName) {
    final sanitised = toSnakeCase(viewName.isEmpty ? 'view' : viewName);
    final ts = DateFormat('yyyy_MM_dd_HH_mm').format(DateTime.now());
    return '${sanitised}_$ts.xml';
  }

  /// Generates a module-scoped export filename for multi-view exports.
  ///
  /// Example: `'my_module_views_2024_01_15.xml'`
  static String moduleXmlFileName(String moduleName) {
    final sanitised = toSnakeCase(moduleName.isEmpty ? 'module' : moduleName);
    final ts = DateFormat('yyyy_MM_dd').format(DateTime.now());
    return '${sanitised}_views_$ts.xml';
  }
}
