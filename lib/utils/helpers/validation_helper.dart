// lib/utils/helpers/validation_helper.dart
//
// Reusable input-validation utilities used throughout the app.
//
// All validators return a nullable String:
//   • null  → input is valid
//   • String → human-readable error message

import '../../data/models/odoo_field.dart';
import '../../data/models/odoo_form.dart';

// ---------------------------------------------------------------------------
// ValidationResult
// ---------------------------------------------------------------------------

/// Container returned by multi-rule validators.
class ValidationResult {
  /// `true` when there are no errors.
  final bool isValid;

  /// All error messages collected during validation.
  final List<String> errors;

  /// Advisory messages that do not block the action.
  final List<String> warnings;

  ValidationResult({
    required this.errors,
    required this.warnings,
  }) : isValid = errors.isEmpty;

  /// Constructs a passing result with optional warnings.
  factory ValidationResult.pass({List<String>? warnings}) =>
      ValidationResult(errors: const [], warnings: warnings ?? const []);

  /// Constructs a failing result.
  factory ValidationResult.fail(
    List<String> errors, {
    List<String>? warnings,
  }) =>
      ValidationResult(errors: errors, warnings: warnings ?? const []);

  @override
  String toString() => isValid
      ? 'ValidationResult.pass(warnings=${warnings.length})'
      : 'ValidationResult.fail(errors=$errors)';
}

// ---------------------------------------------------------------------------
// ValidationHelper
// ---------------------------------------------------------------------------

/// Static validation utilities.
///
/// Usage in a [TextFormField]:
/// ```dart
/// validator: (v) => ValidationHelper.requiredNonEmpty(v, label: 'Model name'),
/// ```
abstract class ValidationHelper {
  ValidationHelper._();

  // ── String / text validators ─────────────────────────────────────────────

  /// Fails if [value] is null or blank.
  static String? requiredNonEmpty(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    return null;
  }

  /// Fails if [value] exceeds [max] characters.
  static String? maxLength(String? value, int max, {String label = 'Field'}) {
    if (value != null && value.length > max) {
      return '$label must be at most $max characters (currently ${value.length}).';
    }
    return null;
  }

  /// Fails if [value] has fewer than [min] characters.
  static String? minLength(String? value, int min, {String label = 'Field'}) {
    if (value == null || value.length < min) {
      return '$label must be at least $min characters.';
    }
    return null;
  }

  /// Fails if [value] does not match [pattern].
  static String? matchesRegex(
    String? value,
    RegExp pattern, {
    required String errorMessage,
  }) {
    if (value != null && !pattern.hasMatch(value)) {
      return errorMessage;
    }
    return null;
  }

  // ── Odoo model / field name validators ──────────────────────────────────

  /// Valid Odoo model name pattern: `module.object` (e.g. `res.partner`).
  static final _modelNamePattern =
      RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$');

  /// Fails if [value] is not a valid Odoo model technical name.
  ///
  /// Valid: `res.partner`, `sale.order.line`
  /// Invalid: `ResPartner`, `res partner`, `_private`
  static String? odooModelName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Model name is required.';
    }
    if (!_modelNamePattern.hasMatch(value.trim())) {
      return 'Model name must be lowercase with dots, e.g. "sale.order".';
    }
    return null;
  }

  /// Valid Odoo field name: starts with a letter or underscore, followed
  /// by letters, digits, or underscores. Max 64 chars.
  static final _fieldNamePattern = RegExp(r'^[a-z_][a-z0-9_]{0,63}$');

  /// Fails if [value] is not a valid Odoo field technical name.
  static String? odooFieldName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field name is required.';
    }
    final name = value.trim();
    if (!_fieldNamePattern.hasMatch(name)) {
      return 'Field name must be lowercase letters/digits/underscores, '
          'start with a letter or underscore, max 64 chars.';
    }
    if (_reservedFieldNames.contains(name)) {
      return '"$name" is a reserved Odoo field name and cannot be used.';
    }
    return null;
  }

  /// Odoo internal field names that must not be used by developers.
  static const Set<String> _reservedFieldNames = {
    'id',
    'create_uid',
    'create_date',
    'write_uid',
    'write_date',
    'display_name',
    '__last_update',
    'active',
    'name',        // not strictly reserved but commonly warned about
  };

  /// Valid XML external ID: `[module.]identifier` with only
  /// letters, digits, underscores, dots.
  static final _externalIdPattern =
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*(\.[a-zA-Z_][a-zA-Z0-9_]*)?$');

  /// Fails if [value] is not a valid Odoo external ID.
  static String? externalId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'External ID is required.';
    }
    if (!_externalIdPattern.hasMatch(value.trim())) {
      return 'External ID must be letters/digits/underscores, '
          'optionally prefixed with "module.", e.g. "my_module.view_partner_form".';
    }
    return null;
  }

  // ── Numeric validators ───────────────────────────────────────────────────

  /// Fails if [value] cannot be parsed as an integer.
  static String? integer(String? value, {String label = 'Value'}) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (int.tryParse(value.trim()) == null) {
      return '$label must be a whole number.';
    }
    return null;
  }

  /// Fails if [value] cannot be parsed as a positive integer.
  static String? positiveInteger(String? value, {String label = 'Value'}) {
    final base = integer(value, label: label);
    if (base != null) return base;
    if (value != null && value.trim().isNotEmpty) {
      final n = int.parse(value.trim());
      if (n <= 0) return '$label must be greater than zero.';
    }
    return null;
  }

  /// Fails if [value] is not in the inclusive range [min]–[max].
  static String? integerRange(
    String? value, {
    required int min,
    required int max,
    String label = 'Value',
  }) {
    final base = integer(value, label: label);
    if (base != null) return base;
    if (value != null && value.trim().isNotEmpty) {
      final n = int.parse(value.trim());
      if (n < min || n > max) return '$label must be between $min and $max.';
    }
    return null;
  }

  // ── URL / connection validators ──────────────────────────────────────────

  static final _urlPattern =
      RegExp(r'^https?://[^\s/$.?#].[^\s]*$', caseSensitive: false);

  /// Fails if [value] is not a valid HTTP/HTTPS URL.
  static String? httpUrl(String? value, {String label = 'URL'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required.';
    }
    if (!_urlPattern.hasMatch(value.trim())) {
      return '$label must be a valid HTTP/HTTPS URL (e.g. https://odoo.example.com).';
    }
    return null;
  }

  /// Fails if [value] is not a valid HTTP/HTTPS Odoo base URL.
  ///
  /// Strips trailing slashes and validates scheme + host.
  static String? odooBaseUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Odoo URL is required.';
    }
    final stripped = value.trim().replaceAll(RegExp(r'/+$'), '');
    return httpUrl(stripped, label: 'Odoo URL');
  }

  // ── OdooForm / OdooField validators ─────────────────────────────────────

  /// Validates an entire [OdooField] and returns a [ValidationResult].
  static ValidationResult validateField(OdooField field) {
    final errors = <String>[];
    final warnings = <String>[];

    // Field name
    final nameError = odooFieldName(field.name);
    if (nameError != null) errors.add(nameError);

    // Colspan
    if (field.colspan != null && (field.colspan! < 1 || field.colspan! > 12)) {
      errors.add('Colspan for "${field.name}" must be between 1 and 12.');
    }

    // Relational fields must have a comodel
    if ((field.fieldType == OdooFieldType.many2one ||
            field.fieldType == OdooFieldType.many2many ||
            field.fieldType == OdooFieldType.one2many) &&
        (field.comodel == null || field.comodel!.trim().isEmpty)) {
      warnings.add(
          '"${field.name}" is a relational field; specify a comodel for proper export.');
    }

    // One2many must have a relation field
    if (field.fieldType == OdooFieldType.one2many &&
        (field.relationField == null || field.relationField!.trim().isEmpty)) {
      warnings.add(
          '"${field.name}" is One2many; add relation_field (inverse_name) for complete XML.');
    }

    return ValidationResult(errors: errors, warnings: warnings);
  }

  /// Validates an [OdooForm] and returns a [ValidationResult].
  static ValidationResult validateForm(OdooForm form) {
    final errors = <String>[];
    final warnings = <String>[];

    // Name
    if (form.name.trim().isEmpty) errors.add('View name is required.');

    // Model
    final modelError = odooModelName(form.model);
    if (modelError != null) errors.add(modelError);

    // External ID
    final idError = externalId(form.id);
    if (idError != null) errors.add(idError);

    // Must have at least one field or group
    if (form.topLevelFields.isEmpty && form.groups.isEmpty && form.pages.isEmpty) {
      warnings.add('The view has no fields. Add at least one field.');
    }

    // Validate each top-level field
    for (final field in form.topLevelFields) {
      final result = validateField(field);
      errors.addAll(result.errors);
      warnings.addAll(result.warnings);
    }

    // Validate fields inside groups
    for (final group in form.groups) {
      for (final field in group.fields) {
        final result = validateField(field);
        errors.addAll(result.errors);
        warnings.addAll(result.warnings);
      }
    }

    // Tree-specific
    if (form.viewType == ViewType.tree && form.topLevelFields.isEmpty) {
      errors.add('Tree view must have at least one column field.');
    }

    return ValidationResult(errors: errors, warnings: warnings);
  }

  // ── Composite helpers ─────────────────────────────────────────────────────

  /// Runs multiple validator functions on [value] and returns the first
  /// non-null error, or `null` if all pass.
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final fn in validators) {
      final result = fn(value);
      if (result != null) return result;
    }
    return null;
  }
}
