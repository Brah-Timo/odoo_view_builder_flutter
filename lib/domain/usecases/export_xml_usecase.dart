// lib/domain/usecases/export_xml_usecase.dart

import '../../data/models/odoo_form.dart';
import '../../services/xml/xml_generator.dart';
import '../../services/xml/xml_validator.dart';

enum ExportFormat { singleView, multipleViews, archOnly }

class ExportXmlUseCase {
  const ExportXmlUseCase();

  /// Generates an XML string ready for export.
  /// Validates the view first and returns errors if any.
  ExportResult execute(
    List<OdooView> views, {
    ExportFormat format = ExportFormat.singleView,
    String? moduleName,
    bool validateFirst = true,
  }) {
    if (views.isEmpty) {
      return ExportResult.failure('No views to export.');
    }

    if (validateFirst) {
      for (final view in views) {
        final report = XmlValidator.validateView(view);
        if (!report.isValid) {
          return ExportResult.validationFailure(view, report);
        }
      }
    }

    final xml = switch (format) {
      ExportFormat.singleView =>
        XmlGenerator.generateSingle(views.first),
      ExportFormat.multipleViews =>
        XmlGenerator.generateFile(views, moduleName: moduleName),
      ExportFormat.archOnly =>
        XmlGenerator.generateArch(views.first),
    };

    return ExportResult.success(xml, views);
  }
}

class ExportResult {
  final String? xml;
  final List<OdooView> views;
  final String? errorMessage;
  final ValidationReport? validationReport;
  final bool isSuccess;

  const ExportResult._({
    this.xml,
    this.views = const [],
    this.errorMessage,
    this.validationReport,
    required this.isSuccess,
  });

  factory ExportResult.success(String xml, List<OdooView> views) =>
      ExportResult._(xml: xml, views: views, isSuccess: true);

  factory ExportResult.failure(String message) =>
      ExportResult._(errorMessage: message, isSuccess: false);

  factory ExportResult.validationFailure(
    OdooView view,
    ValidationReport report,
  ) =>
      ExportResult._(
        views: [view],
        validationReport: report,
        errorMessage:
            'Validation failed: ${report.errorCount} error(s)',
        isSuccess: false,
      );
}
