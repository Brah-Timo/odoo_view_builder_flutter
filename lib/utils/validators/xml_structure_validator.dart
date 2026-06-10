// lib/utils/validators/xml_structure_validator.dart
//
// Validates the structural integrity of Odoo view XML documents.
//
// Checks performed:
//   • Well-formed XML (parseable by the xml package)
//   • Required top-level elements present (<odoo>, <data>, <record>)
//   • Required record fields present (name, model, arch)
//   • arch type="xml" attribute present
//   • View root element present (form | tree | kanban | search | graph | pivot)
//   • Field name attribute present on every <field> element
//   • No duplicate field names at the same level
//   • group/notebook/page nesting depth within Odoo limits
//   • Proper XML encoding declaration

import 'package:xml/xml.dart' as xml;

// ---------------------------------------------------------------------------
// XmlStructureIssue
// ---------------------------------------------------------------------------

/// Severity of a structure validation finding.
enum XmlIssueSeverity { error, warning, info }

/// A single finding from [XmlStructureValidator].
class XmlStructureIssue {
  final XmlIssueSeverity severity;
  final String code;
  final String message;
  final String? path; // XPath-like location hint

  const XmlStructureIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.path,
  });

  bool get isError => severity == XmlIssueSeverity.error;

  @override
  String toString() {
    final loc = path != null ? ' @$path' : '';
    return '[${severity.name.toUpperCase()}:$code]$loc $message';
  }
}

// ---------------------------------------------------------------------------
// XmlStructureValidationResult
// ---------------------------------------------------------------------------

/// Result returned by [XmlStructureValidator.validate].
class XmlStructureValidationResult {
  final List<XmlStructureIssue> issues;

  const XmlStructureValidationResult({required this.issues});

  bool get isValid => issues.every((i) => !i.isError);

  List<XmlStructureIssue> get errors =>
      issues.where((i) => i.isError).toList();
  List<XmlStructureIssue> get warnings =>
      issues.where((i) => i.severity == XmlIssueSeverity.warning).toList();
  List<XmlStructureIssue> get infos =>
      issues.where((i) => i.severity == XmlIssueSeverity.info).toList();
}

// ---------------------------------------------------------------------------
// XmlStructureValidator
// ---------------------------------------------------------------------------

/// Validates the structural integrity of Odoo view XML.
///
/// Validates raw XML strings — it does not rely on any app model classes,
/// so it can be used for import validation before parsing.
///
/// ```dart
/// final result = XmlStructureValidator.validate(rawXmlString);
/// if (!result.isValid) {
///   for (final e in result.errors) print(e);
/// }
/// ```
class XmlStructureValidator {
  XmlStructureValidator._();

  // ── Constants ────────────────────────────────────────────────────────────

  static const int _maxGroupNesting = 5;
  static const int _maxFieldsPerLevel = 128;

  /// Valid Odoo view root element names.
  static const Set<String> _validViewRoots = {
    'form',
    'tree',
    'list', // Odoo 17+ alias for tree
    'kanban',
    'search',
    'graph',
    'pivot',
    'calendar',
    'gantt',
    'activity',
    'qweb',
  };

  // ── Public API ───────────────────────────────────────────────────────────

  /// Validates [xmlContent] and returns a [XmlStructureValidationResult].
  static XmlStructureValidationResult validate(String xmlContent) {
    final issues = <XmlStructureIssue>[];

    if (xmlContent.trim().isEmpty) {
      issues.add(const XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS001',
        message: 'XML content is empty.',
      ));
      return XmlStructureValidationResult(issues: issues);
    }

    // ── 1. Parse ────────────────────────────────────────────────────────────
    late xml.XmlDocument doc;
    try {
      doc = xml.XmlDocument.parse(xmlContent);
    } on xml.XmlParserException catch (e) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS002',
        message: 'XML is not well-formed: ${e.message}',
      ));
      return XmlStructureValidationResult(issues: issues);
    } catch (e) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS002',
        message: 'XML parse error: $e',
      ));
      return XmlStructureValidationResult(issues: issues);
    }

    // ── 2. Encoding declaration ─────────────────────────────────────────────
    final declaration = doc.declaration;
    if (declaration == null) {
      issues.add(const XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS003',
        message: 'Missing XML declaration. '
            'Add <?xml version="1.0" encoding="utf-8"?> at the top.',
      ));
    }

    // ── 3. Root element ─────────────────────────────────────────────────────
    final root = doc.rootElement;
    if (root.name.local != 'odoo') {
      // Also accept <openerp> from very old Odoo versions.
      if (root.name.local != 'openerp') {
        issues.add(XmlStructureIssue(
          severity: XmlIssueSeverity.error,
          code: 'XS004',
          message:
              'Root element must be <odoo> (found <${root.name.local}>).',
          path: '/',
        ));
        return XmlStructureValidationResult(issues: issues);
      } else {
        issues.add(const XmlStructureIssue(
          severity: XmlIssueSeverity.warning,
          code: 'XS004W',
          message:
              '<openerp> root is deprecated since Odoo 10. Use <odoo> instead.',
          path: '/',
        ));
      }
    }

    // ── 4. <data> element ───────────────────────────────────────────────────
    final dataElements = root.findElements('data').toList();
    if (dataElements.isEmpty) {
      // Some files omit <data> and put <record> directly under <odoo>; warn.
      final directRecords = root.findElements('record').toList();
      if (directRecords.isEmpty) {
        issues.add(const XmlStructureIssue(
          severity: XmlIssueSeverity.error,
          code: 'XS005',
          message: 'No <data> or <record> elements found under <odoo>.',
          path: '/odoo',
        ));
        return XmlStructureValidationResult(issues: issues);
      } else {
        issues.add(const XmlStructureIssue(
          severity: XmlIssueSeverity.warning,
          code: 'XS005W',
          message: '<record> placed directly under <odoo> without <data>. '
              'Wrap records in a <data> element for best practice.',
          path: '/odoo',
        ));
      }
    }

    // ── 5. <record> elements ────────────────────────────────────────────────
    final allRecords = [
      ...root.findElements('record'),
      ...dataElements.expand((d) => d.findElements('record')),
    ];

    if (allRecords.isEmpty) {
      issues.add(const XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS006',
        message: 'No <record> elements found.',
        path: '/odoo/data',
      ));
      return XmlStructureValidationResult(issues: issues);
    }

    for (final record in allRecords) {
      _validateRecord(record, issues);
    }

    return XmlStructureValidationResult(issues: issues);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static void _validateRecord(
    xml.XmlElement record,
    List<XmlStructureIssue> issues,
  ) {
    final recordId = record.getAttribute('id') ?? '(no id)';
    final path = '/odoo/data/record[@id="$recordId"]';

    // record[@model]
    final model = record.getAttribute('model');
    if (model == null || model.trim().isEmpty) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS007',
        message: '<record> is missing the required "model" attribute.',
        path: path,
      ));
    }

    // record[@id]
    if (record.getAttribute('id') == null) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS008',
        message: '<record> is missing the "id" attribute '
            '(external ID). Records without IDs cannot be updated by Odoo.',
        path: path,
      ));
    }

    // Only validate ir.ui.view records in detail
    if (model != 'ir.ui.view') return;

    final fields = record.findElements('field').toList();

    // field[name='name']
    final nameField = _findField(fields, 'name');
    if (nameField == null || nameField.innerText.trim().isEmpty) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS009',
        message: 'ir.ui.view record "$recordId" is missing '
            '<field name="name">.',
        path: path,
      ));
    }

    // field[name='model']
    final modelField = _findField(fields, 'model');
    if (modelField == null || modelField.innerText.trim().isEmpty) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS010',
        message: 'ir.ui.view record "$recordId" is missing '
            '<field name="model">.',
        path: path,
      ));
    }

    // field[name='arch']
    final archField = _findField(fields, 'arch');
    if (archField == null) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS011',
        message: 'ir.ui.view record "$recordId" is missing '
            '<field name="arch" type="xml">.',
        path: path,
      ));
      return;
    }

    // arch must have type="xml"
    final archType = archField.getAttribute('type');
    if (archType != 'xml') {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS012',
        message: '<field name="arch"> should have type="xml" '
            '(found: ${archType ?? 'none'}).',
        path: '$path/field[@name="arch"]',
      ));
    }

    // Find the view root inside arch
    final viewRoots = archField.children
        .whereType<xml.XmlElement>()
        .toList();

    if (viewRoots.isEmpty) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS013',
        message: 'arch field in record "$recordId" contains no view element.',
        path: '$path/field[@name="arch"]',
      ));
      return;
    }

    if (viewRoots.length > 1) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS014',
        message: 'arch in record "$recordId" has ${viewRoots.length} '
            'root elements; only the first will be used by Odoo.',
        path: '$path/field[@name="arch"]',
      ));
    }

    final viewRoot = viewRoots.first;
    final viewRootName = viewRoot.name.local;

    if (!_validViewRoots.contains(viewRootName)) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.error,
        code: 'XS015',
        message:
            'Unknown view root element <$viewRootName> in record "$recordId". '
            'Valid roots: ${_validViewRoots.join(', ')}.',
        path: '$path/field[@name="arch"]/$viewRootName',
      ));
    }

    // Validate fields within the view
    _validateViewFields(viewRoot, issues, recordId);
    _validateGroupNesting(viewRoot, issues, recordId, depth: 0);
  }

  static void _validateViewFields(
    xml.XmlElement viewRoot,
    List<XmlStructureIssue> issues,
    String recordId,
  ) {
    final allFieldElements = viewRoot
        .descendants
        .whereType<xml.XmlElement>()
        .where((e) => e.name.local == 'field')
        .toList();

    // Check every field has a name attribute
    for (final fieldEl in allFieldElements) {
      final name = fieldEl.getAttribute('name');
      if (name == null || name.trim().isEmpty) {
        issues.add(XmlStructureIssue(
          severity: XmlIssueSeverity.error,
          code: 'XS016',
          message:
              'A <field> element in record "$recordId" is missing the '
              '"name" attribute.',
        ));
      }
    }

    // Check for duplicate field names at top level
    final topLevelFields = viewRoot
        .children
        .whereType<xml.XmlElement>()
        .where((e) => e.name.local == 'field')
        .map((e) => e.getAttribute('name'))
        .whereType<String>()
        .toList();

    final seen = <String>{};
    for (final fname in topLevelFields) {
      if (!seen.add(fname)) {
        issues.add(XmlStructureIssue(
          severity: XmlIssueSeverity.warning,
          code: 'XS017',
          message:
              'Duplicate field name "$fname" at the top level of record '
              '"$recordId". Odoo will only render the first occurrence.',
        ));
      }
    }

    // Field count sanity check
    if (allFieldElements.length > _maxFieldsPerLevel) {
      issues.add(XmlStructureIssue(
        severity: XmlIssueSeverity.warning,
        code: 'XS018',
        message:
            'Record "$recordId" contains ${allFieldElements.length} fields. '
            'Consider splitting into multiple views or using notebooks '
            'for better performance.',
      ));
    }
  }

  static void _validateGroupNesting(
    xml.XmlElement element,
    List<XmlStructureIssue> issues,
    String recordId, {
    required int depth,
  }) {
    for (final child in element.children.whereType<xml.XmlElement>()) {
      if (child.name.local == 'group' || child.name.local == 'page') {
        final newDepth = depth + 1;
        if (newDepth > _maxGroupNesting) {
          issues.add(XmlStructureIssue(
            severity: XmlIssueSeverity.warning,
            code: 'XS019',
            message:
                'Nesting depth $newDepth for <${child.name.local}> in '
                'record "$recordId" exceeds the recommended maximum of '
                '$_maxGroupNesting. Deep nesting can cause layout issues.',
          ));
        }
        _validateGroupNesting(child, issues, recordId, depth: newDepth);
      }
    }
  }

  // ── Utility ──────────────────────────────────────────────────────────────

  static xml.XmlElement? _findField(
    List<xml.XmlElement> fields,
    String name,
  ) {
    try {
      return fields.firstWhere((e) => e.getAttribute('name') == name);
    } catch (_) {
      return null;
    }
  }

  // ── Convenience ──────────────────────────────────────────────────────────

  /// Quick boolean check.
  static bool isValid(String xmlContent) =>
      validate(xmlContent).isValid;

  /// Returns only error messages as a list of strings.
  static List<String> errorMessages(String xmlContent) =>
      validate(xmlContent).errors.map((e) => e.message).toList();
}
