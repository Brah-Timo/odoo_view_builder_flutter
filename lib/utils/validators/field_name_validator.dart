// lib/utils/validators/field_name_validator.dart
//
// Validates Odoo field technical names against the official naming rules
// documented in the Odoo developer guide and ORM source code.

// ---------------------------------------------------------------------------
// FieldNameValidationIssue
// ---------------------------------------------------------------------------

/// Severity of a validation finding.
enum IssueSeverity { error, warning }

/// A single finding produced by [FieldNameValidator].
class FieldNameValidationIssue {
  final IssueSeverity severity;
  final String code;
  final String message;

  const FieldNameValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
  });

  bool get isError => severity == IssueSeverity.error;
  bool get isWarning => severity == IssueSeverity.warning;

  @override
  String toString() => '[${severity.name.toUpperCase()}:$code] $message';
}

// ---------------------------------------------------------------------------
// FieldNameValidationResult
// ---------------------------------------------------------------------------

/// Result returned by [FieldNameValidator.validate].
class FieldNameValidationResult {
  final String input;
  final List<FieldNameValidationIssue> issues;

  const FieldNameValidationResult({
    required this.input,
    required this.issues,
  });

  /// `true` when there are no error-level issues.
  bool get isValid => issues.every((i) => i.isWarning);

  List<FieldNameValidationIssue> get errors =>
      issues.where((i) => i.isError).toList();

  List<FieldNameValidationIssue> get warnings =>
      issues.where((i) => i.isWarning).toList();

  @override
  String toString() =>
      'FieldNameValidationResult(valid=$isValid, issues=${issues.length})';
}

// ---------------------------------------------------------------------------
// FieldNameValidator
// ---------------------------------------------------------------------------

/// Validates Odoo field technical names (`name` attribute in `<field>`).
///
/// Rules enforced:
///
/// 1. **Not empty** — the name cannot be blank.
/// 2. **Allowed characters** — only `[a-z0-9_]` are permitted.
/// 3. **Start character** — must start with a letter or underscore, not a digit.
/// 4. **Max length** — PostgreSQL column limit is 63 bytes; Odoo reserves a few
///    chars for suffixes, so the practical max is 63 characters.
/// 5. **Reserved names** — Odoo ORM injects certain field names automatically;
///    custom fields should not shadow them without good reason (warning only).
/// 6. **Naming convention** — custom / studio fields should be prefixed with
///    `x_` (warning only for names that look custom but lack the prefix).
/// 7. **Double underscores** — `__dunder__` names are used by Python
///    internally; using them as field names is a bad practice (warning).
/// 8. **SQL keyword clash** — a handful of PostgreSQL / Odoo reserved words
///    produce a warning.
///
/// Usage:
/// ```dart
/// final result = FieldNameValidator.validate('x_my_field');
/// if (!result.isValid) {
///   for (final e in result.errors) print(e.message);
/// }
/// ```
class FieldNameValidator {
  FieldNameValidator._();

  // ── Regex patterns ──────────────────────────────────────────────────────

  static final _allowedChars = RegExp(r'^[a-z_][a-z0-9_]*$');
  static final _startsWithDigit = RegExp(r'^[0-9]');
  static final _doubleUnderscore =
      RegExp(r'^__.*__$'); // dunder pattern

  // ── Constants ──────────────────────────────────────────────────────────

  static const int _maxLength = 63;

  /// Field names automatically injected by the Odoo ORM.
  /// Developers should not define custom fields with these names.
  static const Set<String> _reservedOrmFields = {
    'id',
    'create_uid',
    'create_date',
    'write_uid',
    'write_date',
    'display_name',
    '__last_update',
  };

  /// Commonly used Odoo base-module field names.
  /// Not forbidden, but overlapping can cause confusion (warning).
  static const Set<String> _commonOdooFields = {
    'name',
    'active',
    'sequence',
    'state',
    'company_id',
    'currency_id',
    'user_id',
    'partner_id',
    'date',
    'note',
    'description',
    'reference',
    'color',
    'priority',
    'tag_ids',
  };

  /// PostgreSQL / SQL reserved words that may cause issues.
  static const Set<String> _sqlReserved = {
    'select',
    'insert',
    'update',
    'delete',
    'from',
    'where',
    'table',
    'index',
    'view',
    'order',
    'group',
    'having',
    'limit',
    'offset',
    'join',
    'left',
    'right',
    'inner',
    'outer',
    'on',
    'as',
    'null',
    'true',
    'false',
    'not',
    'and',
    'or',
    'in',
    'is',
    'like',
    'between',
    'exists',
    'case',
    'when',
    'then',
    'else',
    'end',
  };

  // ── Public API ──────────────────────────────────────────────────────────

  /// Validates [fieldName] and returns a [FieldNameValidationResult].
  static FieldNameValidationResult validate(String fieldName) {
    final issues = <FieldNameValidationIssue>[];

    // 1. Empty check
    if (fieldName.trim().isEmpty) {
      issues.add(const FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN001',
        message: 'Field name must not be empty.',
      ));
      return FieldNameValidationResult(input: fieldName, issues: issues);
    }

    final name = fieldName.trim();

    // 2. Starts with digit
    if (_startsWithDigit.hasMatch(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN002',
        message: 'Field name "$name" must not start with a digit.',
      ));
    }

    // 3. Allowed characters
    if (!_allowedChars.hasMatch(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN003',
        message:
            'Field name "$name" contains invalid characters. '
            'Only lowercase letters, digits, and underscores are allowed.',
      ));
    }

    // 4. Max length
    if (name.length > _maxLength) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN004',
        message:
            'Field name "$name" is ${name.length} characters; '
            'maximum allowed is $_maxLength.',
      ));
    }

    // 5. Reserved ORM field
    if (_reservedOrmFields.contains(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.error,
        code: 'FN005',
        message:
            '"$name" is a reserved Odoo ORM field. '
            'Use a different name for your custom field.',
      ));
    }

    // 6. Dunder pattern
    if (_doubleUnderscore.hasMatch(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.warning,
        code: 'FN006',
        message:
            '"$name" uses a dunder (double-underscore) pattern reserved '
            'for Python internals. Choose a different name.',
      ));
    }

    // 7. SQL keyword clash
    if (_sqlReserved.contains(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.warning,
        code: 'FN007',
        message:
            '"$name" is a SQL reserved word. '
            'This may cause query issues in some Odoo / PostgreSQL versions.',
      ));
    }

    // 8. Common Odoo field names (info-level warning)
    if (_commonOdooFields.contains(name)) {
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.warning,
        code: 'FN008',
        message:
            '"$name" is a well-known Odoo field name. '
            'If this is a custom field, consider prefixing it with "x_".',
      ));
    }

    // 9. No x_ prefix for non-standard fields
    if (!name.startsWith('x_') &&
        !_reservedOrmFields.contains(name) &&
        !_commonOdooFields.contains(name) &&
        !name.startsWith('_')) {
      // Heuristic: if the name doesn't look like a well-known Odoo field,
      // it's likely a custom addition and should carry the x_ prefix.
      // We issue a soft warning to be informative without blocking.
      issues.add(FieldNameValidationIssue(
        severity: IssueSeverity.warning,
        code: 'FN009',
        message:
            'Custom field names should start with "x_" to avoid conflicts '
            'with future Odoo field additions (e.g. "x_$name").',
      ));
    }

    return FieldNameValidationResult(input: fieldName, issues: issues);
  }

  // ── Convenience helpers ─────────────────────────────────────────────────

  /// Quick boolean check — returns `true` if [fieldName] has no errors.
  static bool isValid(String fieldName) => validate(fieldName).isValid;

  /// Returns the first error message for [fieldName], or `null` if valid.
  ///
  /// Suitable as a [TextFormField] `validator` callback:
  /// ```dart
  /// validator: FieldNameValidator.firstError,
  /// ```
  static String? firstError(String? fieldName) {
    if (fieldName == null) return 'Field name is required.';
    final result = validate(fieldName);
    return result.errors.isEmpty ? null : result.errors.first.message;
  }

  /// Attempts to auto-correct [input] into a valid Odoo field name.
  ///
  /// The returned string is **not guaranteed** to be perfectly meaningful —
  /// human review is still needed.
  static String autoFix(String input) {
    var fixed = input.trim().toLowerCase();

    // Replace spaces and dashes with underscores
    fixed = fixed.replaceAll(RegExp(r'[\s\-]+'), '_');

    // Remove disallowed characters
    fixed = fixed.replaceAll(RegExp(r'[^a-z0-9_]'), '');

    // Strip leading digits
    fixed = fixed.replaceAll(RegExp(r'^[0-9]+'), '');

    // Collapse consecutive underscores
    fixed = fixed.replaceAll(RegExp(r'_+'), '_');

    // Strip leading/trailing underscores
    fixed = fixed.replaceAll(RegExp(r'^_+|_+$'), '');

    // Ensure non-empty
    if (fixed.isEmpty) fixed = 'x_field';

    // Enforce max length
    if (fixed.length > _maxLength) fixed = fixed.substring(0, _maxLength);

    // Ensure x_ prefix if needed
    if (!fixed.startsWith('x_') && !_commonOdooFields.contains(fixed)) {
      fixed = 'x_$fixed';
      if (fixed.length > _maxLength) {
        fixed = fixed.substring(0, _maxLength);
      }
    }

    return fixed;
  }
}
