// lib/services/odoo/odoo_validation_rules.dart
//
// Odoo version-specific validation rules for views.

class OdooValidationRules {
  final String odooVersion;

  const OdooValidationRules(this.odooVersion);

  /// Checks if a feature is supported in the target Odoo version
  bool supportsFeature(String feature) {
    final major = int.tryParse(odooVersion.split('.').first) ?? 16;

    return switch (feature) {
      'optional_columns' => major >= 13,
      'decorations' => major >= 12,
      'statusbar' => major >= 10,
      'many2many_tags' => major >= 10,
      'notebook' => major >= 8,
      'chatter' => major >= 9,
      'activity' => major >= 11,
      _ => true,
    };
  }

  List<String> getDeprecatedAttributes(String version) {
    return switch (version) {
      '14.0' => ['editable', 'default_focus'],
      '15.0' => [],
      '16.0' => [],
      '17.0' => ['attrs', 'states'],
      _ => [],
    };
  }
}
