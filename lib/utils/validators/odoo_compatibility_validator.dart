// lib/utils/validators/odoo_compatibility_validator.dart
//
// Validates Odoo view XML or model objects for compatibility with specific
// Odoo versions (14, 15, 16, 17, 18).
//
// Rules are sourced from:
//   • Odoo upgrade notes and changelogs
//   • Odoo framework deprecation warnings
//   • Community migration guides

import '../helpers/field_helper.dart';
import '../../data/models/odoo_field.dart';
import '../../data/models/odoo_form.dart';

// ---------------------------------------------------------------------------
// OdooVersion
// ---------------------------------------------------------------------------

/// Supported Odoo target versions for compatibility checks.
enum OdooVersion {
  v14('14.0', 14),
  v15('15.0', 15),
  v16('16.0', 16),
  v17('17.0', 17),
  v18('18.0', 18);

  const OdooVersion(this.label, this.major);

  final String label;
  final int major;

  static OdooVersion fromString(String s) {
    final major = int.tryParse(s.split('.').first) ?? 17;
    return OdooVersion.values.firstWhere(
      (v) => v.major == major,
      orElse: () => OdooVersion.v17,
    );
  }
}

// ---------------------------------------------------------------------------
// CompatibilityIssue
// ---------------------------------------------------------------------------

enum CompatSeverity { error, warning, info }

/// A single compatibility finding.
class CompatibilityIssue {
  final CompatSeverity severity;
  final String code;
  final String message;
  final String? suggestion;
  final OdooVersion? introducedIn;
  final OdooVersion? removedIn;

  const CompatibilityIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.suggestion,
    this.introducedIn,
    this.removedIn,
  });

  bool get isError => severity == CompatSeverity.error;
  bool get isWarning => severity == CompatSeverity.warning;

  @override
  String toString() {
    final sug = suggestion != null ? ' Suggestion: $suggestion' : '';
    return '[${severity.name.toUpperCase()}:$code] $message$sug';
  }
}

// ---------------------------------------------------------------------------
// CompatibilityValidationResult
// ---------------------------------------------------------------------------

class CompatibilityValidationResult {
  final OdooVersion targetVersion;
  final List<CompatibilityIssue> issues;

  const CompatibilityValidationResult({
    required this.targetVersion,
    required this.issues,
  });

  bool get isCompatible => issues.every((i) => !i.isError);

  List<CompatibilityIssue> get errors =>
      issues.where((i) => i.isError).toList();
  List<CompatibilityIssue> get warnings =>
      issues.where((i) => i.isWarning).toList();
  List<CompatibilityIssue> get infos =>
      issues.where((i) => i.severity == CompatSeverity.info).toList();

  @override
  String toString() =>
      'CompatibilityValidationResult('
      'target=${targetVersion.label}, '
      'compatible=$isCompatible, '
      'issues=${issues.length})';
}

// ---------------------------------------------------------------------------
// OdooCompatibilityValidator
// ---------------------------------------------------------------------------

/// Validates [OdooForm] and [OdooField] objects against a target Odoo version.
///
/// ```dart
/// final result = OdooCompatibilityValidator.validateForm(
///   form,
///   target: OdooVersion.v17,
/// );
/// if (!result.isCompatible) {
///   for (final e in result.errors) print(e);
/// }
/// ```
class OdooCompatibilityValidator {
  OdooCompatibilityValidator._();

  // ── Deprecated attributes by version ─────────────────────────────────────

  /// Attributes deprecated or removed in specific versions.
  static const Map<String, _DeprecationInfo> _deprecatedAttributes = {
    // Odoo 17: `attrs` replaced by inline `invisible`, `readonly`, `required`
    'attrs': _DeprecationInfo(
      removedIn: OdooVersion.v17,
      replacement: 'Use inline `invisible`, `readonly`, `required` attributes '
          'with domain expressions. e.g. invisible="state == \'done\'"',
    ),
    // Odoo 17: `states` replaced by `invisible`
    'states': _DeprecationInfo(
      removedIn: OdooVersion.v17,
      replacement:
          'Replace `states` with `invisible="state not in (\'draft\',\'confirmed\')"` '
          'or `column_invisible` for tree columns.',
    ),
    // Odoo 15: `default_focus` removed
    'default_focus': _DeprecationInfo(
      removedIn: OdooVersion.v15,
      replacement:
          'Focus management is handled by the web client. Remove this attribute.',
    ),
    // Odoo 17: `editable` on form view deprecated
    'editable': _DeprecationInfo(
      removedIn: OdooVersion.v17,
      replacement:
          'Form views are always editable in Odoo 17+. Remove this attribute.',
    ),
    // Odoo 17: `decoration-*` on form fields (only valid in tree)
    'decoration-bf': _DeprecationInfo(
      removedIn: OdooVersion.v17,
      replacement: 'Decoration attributes are only valid in tree/list views.',
    ),
  };

  /// Widgets deprecated or removed in specific versions.
  static const Map<String, _DeprecationInfo> _deprecatedWidgets = {
    // Odoo 14: statusbar moved from field to header attribute
    'statusbar_visible': _DeprecationInfo(
      removedIn: OdooVersion.v14,
      replacement:
          'Use the `statusbar` widget on the Many2one/Selection field itself.',
    ),
    // Odoo 16: CKEditor-based html widget replaced by OWL editor
    'html_frame': _DeprecationInfo(
      removedIn: OdooVersion.v16,
      replacement: 'Use the standard `html` widget which uses the OWL editor.',
    ),
  };

  // ── Public API ──────────────────────────────────────────────────────────

  /// Validates [form] for compatibility with [target].
  static CompatibilityValidationResult validateForm(
    OdooForm form, {
    OdooVersion target = OdooVersion.v17,
  }) {
    final issues = <CompatibilityIssue>[];

    // Validate view-level attributes
    _checkViewLevelCompat(form, target, issues);

    // Validate each top-level field
    for (final field in form.allFields) {
      _checkFieldCompat(field, form.viewType, target, issues);
    }

    // Validate fields inside groups
    for (final group in form.groups) {
      for (final field in group.fields) {
        _checkFieldCompat(field, form.viewType, target, issues);
      }
      // Nested sub-groups
      for (final sub in group.subGroups) {
        for (final field in sub.fields) {
          _checkFieldCompat(field, form.viewType, target, issues);
        }
      }
    }

    // Version-specific form-level checks
    _checkVersionSpecificForm(form, target, issues);

    return CompatibilityValidationResult(
      targetVersion: target,
      issues: issues,
    );
  }

  /// Validates a single [OdooField] for compatibility with [target].
  static CompatibilityValidationResult validateField(
    OdooField field,
    ViewType viewType, {
    OdooVersion target = OdooVersion.v17,
  }) {
    final issues = <CompatibilityIssue>[];
    _checkFieldCompat(field, viewType, target, issues);
    return CompatibilityValidationResult(targetVersion: target, issues: issues);
  }

  // ── Private helpers ─────────────────────────────────────────────────────

  static void _checkViewLevelCompat(
    OdooForm form,
    OdooVersion target,
    List<CompatibilityIssue> issues,
  ) {
    // Tree editable in Odoo 17+ should use list + optional
    if (form.viewType == ViewType.tree &&
        form.editable == true &&
        target.major >= 17) {
      issues.add(const CompatibilityIssue(
        severity: CompatSeverity.info,
        code: 'OC001',
        message:
            'In Odoo 17+, tree views are renamed to "list" views. '
            'The element is still accepted but consider using <list> for new code.',
        suggestion:
            'Use <list editable="top"> or <list editable="bottom"> in Odoo 17+.',
        introducedIn: OdooVersion.v17,
      ));
    }

    // Kanban requires templates in Odoo < 17
    if (form.viewType == ViewType.kanban && target.major < 17) {
      // Check if the generated XML would have templates — we check fields as a proxy
      if (form.allFields.isEmpty && form.groups.isEmpty) {
        issues.add(const CompatibilityIssue(
          severity: CompatSeverity.warning,
          code: 'OC002',
          message:
              'Kanban views in Odoo 14-16 require a <templates> section '
              'with a <t t-name="kanban-box"> template.',
          suggestion:
              'Add at least one field so the XML generator creates the '
              'kanban template structure.',
        ));
      }
    }
  }

  static void _checkFieldCompat(
    OdooField field,
    ViewType viewType,
    OdooVersion target,
    List<CompatibilityIssue> issues,
  ) {
    // ── Deprecated `attrs` ────────────────────────────────────────────────
    if (field.attrs != null &&
        field.attrs!.trim().isNotEmpty &&
        target.major >= 17) {
      final dep = _deprecatedAttributes['attrs']!;
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.error,
        code: 'OC003',
        message:
            'Field "${field.name}" uses `attrs` which was removed in Odoo 17.',
        suggestion: dep.replacement,
        removedIn: dep.removedIn,
      ));
    }

    // ── Deprecated `states` ───────────────────────────────────────────────
    // Check extraAttrs for states
    if (field.extraAttrs.containsKey('states') && target.major >= 17) {
      final dep = _deprecatedAttributes['states']!;
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.error,
        code: 'OC004',
        message:
            'Field "${field.name}" uses `states` which was removed in Odoo 17.',
        suggestion: dep.replacement,
        removedIn: dep.removedIn,
      ));
    }

    // ── Widget compatibility ──────────────────────────────────────────────
    if (field.widget != null) {
      _checkWidgetCompat(field, target, issues);
    }

    // ── Aggregation only on numeric ───────────────────────────────────────
    if ((field.sum != null) && !FieldHelper.supportsAggregation(field.fieldType)) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC005',
        message:
            'Field "${field.name}" (${field.fieldType.value}) has a `sum` '
            'aggregation but only integer/float fields support aggregation in trees.',
        suggestion: 'Remove `sum` from non-numeric fields.',
      ));
    }

    // ── One2many / Many2many in tree ──────────────────────────────────────
    if (viewType == ViewType.tree &&
        (field.fieldType == OdooFieldType.one2many ||
            field.fieldType == OdooFieldType.many2many)) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC006',
        message:
            'Field "${field.name}" (${field.fieldType.value}) is not recommended '
            'as a direct tree column — it renders poorly.',
        suggestion: 'Use many2many_tags widget or omit from tree view.',
      ));
    }

    // ── HTML in tree columns ──────────────────────────────────────────────
    if (viewType == ViewType.tree && field.fieldType == OdooFieldType.html) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC007',
        message:
            'HTML fields in tree views render as plain text; '
            'use the `text` field type instead for tree columns.',
        suggestion: 'Switch to a `text` or `char` field in the tree view.',
      ));
    }

    // ── Relational missing comodel ────────────────────────────────────────
    if (FieldHelper.isRelational(field.fieldType) &&
        (field.comodel == null || field.comodel!.trim().isEmpty)) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC008',
        message:
            'Relational field "${field.name}" (${field.fieldType.value}) '
            'has no comodel specified.',
        suggestion: 'Add comodel_name to the field definition.',
      ));
    }
  }

  static void _checkWidgetCompat(
    OdooField field,
    OdooVersion target,
    List<CompatibilityIssue> issues,
  ) {
    final widget = field.widget!;

    // Check deprecated widgets table
    if (_deprecatedWidgets.containsKey(widget)) {
      final dep = _deprecatedWidgets[widget]!;
      if (dep.removedIn != null && target.major >= dep.removedIn!.major) {
        issues.add(CompatibilityIssue(
          severity: CompatSeverity.error,
          code: 'OC009',
          message:
              'Widget "$widget" on field "${field.name}" was removed in '
              'Odoo ${dep.removedIn!.label}.',
          suggestion: dep.replacement,
          removedIn: dep.removedIn,
        ));
        return;
      }
    }

    // Check widget compatibility with the field type
    final compatible = FieldHelper.compatibleWidgets(field.fieldType);
    if (!compatible.contains(widget)) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC010',
        message:
            'Widget "$widget" may not be compatible with '
            '${field.fieldType.value} field "${field.name}".',
        suggestion:
            'Compatible widgets for ${field.fieldType.value}: '
            '${compatible.join(', ')}.',
      ));
    }

    // Odoo 17+: many2one_avatar_employee replaced by many2one_avatar_user
    if (widget == 'many2one_avatar_employee' && target.major >= 17) {
      issues.add(CompatibilityIssue(
        severity: CompatSeverity.warning,
        code: 'OC011',
        message:
            'Widget "many2one_avatar_employee" is HR-module specific. '
            'Use "many2one_avatar_user" for non-HR models in Odoo 17+.',
        suggestion: 'Change widget to "many2one_avatar_user".',
        introducedIn: OdooVersion.v17,
      ));
    }
  }

  static void _checkVersionSpecificForm(
    OdooForm form,
    OdooVersion target,
    List<CompatibilityIssue> issues,
  ) {
    // Odoo 17: chatter / messageing changes — info only
    if (target.major >= 17 && form.viewType == ViewType.form) {
      issues.add(const CompatibilityIssue(
        severity: CompatSeverity.info,
        code: 'OC012',
        message:
            'Odoo 17+ uses OWL-based chatter. If your form uses the old '
            'Python-rendered chatter widget, test rendering carefully.',
        suggestion:
            'Ensure your module depends on `mail` and uses '
            '<chatter/> or the OWL mail.ChatterContainer component.',
        introducedIn: OdooVersion.v17,
      ));
    }

    // Odoo 14: sheet wrapper still required in forms
    if (target.major == 14 && form.viewType == ViewType.form) {
      issues.add(const CompatibilityIssue(
        severity: CompatSeverity.info,
        code: 'OC013',
        message:
            'Odoo 14 forms should wrap content in a <sheet> element for '
            'correct UI rendering.',
        suggestion: 'Ensure the generated XML includes <sheet> inside <form>.',
      ));
    }
  }
}

// ---------------------------------------------------------------------------
// Internal helper
// ---------------------------------------------------------------------------

class _DeprecationInfo {
  final OdooVersion? removedIn;
  final String replacement;

  const _DeprecationInfo({
    required this.replacement,
    this.removedIn,
  });
}
