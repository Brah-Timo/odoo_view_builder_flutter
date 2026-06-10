// lib/services/xml/xml_validator.dart

import 'package:xml/xml.dart' as xml;
import '../../data/models/odoo_form.dart';
import '../../data/models/odoo_field.dart';
import '../../data/models/odoo_group.dart';
import '../../config/constants.dart';

/// Severity level for a validation issue
enum ValidationSeverity { error, warning, info }

/// A single validation issue
class ValidationIssue {
  final ValidationSeverity severity;
  final String code;
  final String message;
  final String? path;

  const ValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.path,
  });

  bool get isError => severity == ValidationSeverity.error;
  bool get isWarning => severity == ValidationSeverity.warning;

  @override
  String toString() => '[${severity.name.toUpperCase()}] $message${path != null ? ' (at $path)' : ''}';
}

/// Result of a validation run
class ValidationReport {
  final List<ValidationIssue> issues;

  const ValidationReport(this.issues);

  bool get isValid => issues.every((i) => !i.isError);
  List<ValidationIssue> get errors =>
      issues.where((i) => i.isError).toList();
  List<ValidationIssue> get warnings =>
      issues.where((i) => i.isWarning).toList();

  int get errorCount => errors.length;
  int get warningCount => warnings.length;
}

/// Validates OdooView models and generated XML content
class XmlValidator {
  XmlValidator._();

  // ─── Model Validation ────────────────────────────────────────────────────────

  static ValidationReport validateView(OdooView view) {
    final issues = <ValidationIssue>[];

    // View ID
    if (view.id.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'EMPTY_ID',
        message: 'View ID cannot be empty.',
      ));
    } else if (!_isValidXmlId(view.id)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'INVALID_ID',
        message: 'View ID "${view.id}" contains invalid characters. Use only a-z, 0-9, _.',
      ));
    }

    // Model name
    if (view.model.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'EMPTY_MODEL',
        message: 'Model name cannot be empty (e.g. res.partner).',
      ));
    } else if (!_isValidModelName(view.model)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'UNUSUAL_MODEL',
        message: 'Model name "${view.model}" looks unusual. Expected format: module.name',
      ));
    }

    // View name
    if (view.name.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'EMPTY_NAME',
        message: 'View name is empty — a descriptive name is recommended.',
      ));
    }

    // Empty view
    if (view.isEmpty) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'EMPTY_VIEW',
        message: 'The ${view.viewType.label} has no fields or groups.',
      ));
    }

    // Field-level validation
    for (final field in view.allFields) {
      issues.addAll(_validateField(field, context: view.viewType.value));
    }

    // Group depth
    for (final group in view.groups) {
      issues.addAll(_validateGroupDepth(group, depth: 1));
    }

    // Duplicate field names
    final fieldNames = view.allFields.map((f) => f.name).toList();
    final duplicates = fieldNames
        .where((name) => fieldNames.where((n) => n == name).length > 1)
        .toSet();
    for (final dup in duplicates) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'DUPLICATE_FIELD',
        message: 'Field "$dup" appears more than once in this view.',
      ));
    }

    return ValidationReport(issues);
  }

  // ─── Field Validation ────────────────────────────────────────────────────────

  static List<ValidationIssue> _validateField(
    OdooField field, {
    required String context,
  }) {
    final issues = <ValidationIssue>[];

    // Empty name
    if (field.name.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'FIELD_EMPTY_NAME',
        message: 'A field has an empty name.',
      ));
      return issues;
    }

    // Reserved names
    if (AppConstants.reservedFieldNames.contains(field.name)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.info,
        code: 'FIELD_RESERVED_NAME',
        message: '"${field.name}" is a system field — this is allowed but unusual.',
        path: 'field:${field.name}',
      ));
    }

    // Invalid name characters
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(field.name)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'FIELD_INVALID_NAME',
        message: 'Field name "${field.name}" must start with a letter and contain only a-z, 0-9, _.',
        path: 'field:${field.name}',
      ));
    }

    // Colspan range
    if (field.colspan != null && (field.colspan! < 1 || field.colspan! > 6)) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'FIELD_COLSPAN_RANGE',
        message: 'Field "${field.name}" has colspan ${field.colspan}. Valid range is 1-6.',
        path: 'field:${field.name}',
      ));
    }

    // Readonly + required combination
    if (field.readonly && field.required) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'FIELD_READONLY_REQUIRED',
        message: 'Field "${field.name}" is both readonly and required — required has no effect on readonly fields.',
        path: 'field:${field.name}',
      ));
    }

    // Widget compatibility
    if (field.widget != null && field.widget!.isNotEmpty) {
      final compatibleWidgets =
          AppConstants.fieldWidgets[field.fieldType.value] ?? [];
      if (compatibleWidgets.isNotEmpty &&
          !compatibleWidgets.contains(field.widget)) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'FIELD_WIDGET_MISMATCH',
          message: 'Widget "${field.widget}" may not be compatible with field type "${field.fieldType.value}" for "${field.name}".',
          path: 'field:${field.name}',
        ));
      }
    }

    // Relational fields: suggest comodel
    if ([OdooFieldType.many2one, OdooFieldType.many2many, OdooFieldType.one2many]
        .contains(field.fieldType)) {
      if (field.comodel == null || field.comodel!.isEmpty) {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.info,
          code: 'FIELD_MISSING_COMODEL',
          message: 'Relational field "${field.name}" has no comodel set (optional in views, required in model definition).',
          path: 'field:${field.name}',
        ));
      }
    }

    return issues;
  }

  // ─── Group Validation ────────────────────────────────────────────────────────

  static List<ValidationIssue> _validateGroupDepth(
    OdooGroup group, {
    required int depth,
  }) {
    final issues = <ValidationIssue>[];

    if (depth > AppConstants.maxNestedGroupDepth) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.warning,
        code: 'GROUP_TOO_DEEP',
        message: 'Group "${group.label ?? group.id}" is nested at depth $depth. Odoo recommends max 3 levels.',
        path: 'group:${group.id}',
      ));
    }

    for (final sub in group.subGroups) {
      issues.addAll(_validateGroupDepth(sub, depth: depth + 1));
    }

    return issues;
  }

  // ─── XML String Validation ───────────────────────────────────────────────────

  static ValidationReport validateXmlString(String xmlContent) {
    final issues = <ValidationIssue>[];

    if (xmlContent.trim().isEmpty) {
      issues.add(const ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'XML_EMPTY',
        message: 'XML content is empty.',
      ));
      return ValidationReport(issues);
    }

    try {
      xml.XmlDocument.parse(xmlContent);
    } on xml.XmlParserException catch (e) {
      issues.add(ValidationIssue(
        severity: ValidationSeverity.error,
        code: 'XML_PARSE_ERROR',
        message: 'XML parse error: ${e.message}',
        path: 'line:${e.position}',
      ));
      return ValidationReport(issues);
    }

    // Check for odoo root element
    try {
      final doc = xml.XmlDocument.parse(xmlContent);
      final root = doc.rootElement;

      if (root.localName != 'odoo') {
        issues.add(ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'XML_ROOT_NOT_ODOO',
          message: 'Root element is <${root.localName}>, expected <odoo>.',
        ));
      }

      // Check for at least one record
      if (doc.findAllElements('record').isEmpty) {
        issues.add(const ValidationIssue(
          severity: ValidationSeverity.warning,
          code: 'XML_NO_RECORDS',
          message: 'No <record> elements found — is this a valid Odoo views file?',
        ));
      }
    } catch (_) {}

    return ValidationReport(issues);
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  static bool _isValidXmlId(String id) =>
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_.]*$').hasMatch(id);

  static bool _isValidModelName(String model) =>
      RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(model);
}
