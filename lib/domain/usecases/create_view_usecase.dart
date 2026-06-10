// lib/domain/usecases/create_view_usecase.dart

import '../../data/models/odoo_form.dart';
import '../../data/repositories/view_repository.dart';
import '../../services/xml/xml_validator.dart';

/// Creates and persists a new OdooView
class CreateViewUseCase {
  final ViewRepository _repository;

  const CreateViewUseCase(this._repository);

  /// Creates the view, validates it, and saves it.
  /// Returns [ValidationReport] with any issues found.
  Future<CreateViewResult> execute({
    required String name,
    required String model,
    required ViewType viewType,
    String? docModule,
  }) async {
    // Build a blank view
    final view = OdooView.create(
      name: name.trim(),
      model: model.trim(),
      viewType: viewType,
      docModule: docModule?.trim(),
    );

    // Validate before saving
    final report = XmlValidator.validateView(view);
    if (!report.isValid) {
      return CreateViewResult.failure(report);
    }

    await _repository.save(view);
    return CreateViewResult.success(view, report);
  }
}

class CreateViewResult {
  final OdooView? view;
  final ValidationReport report;
  final bool isSuccess;

  const CreateViewResult._({
    this.view,
    required this.report,
    required this.isSuccess,
  });

  factory CreateViewResult.success(OdooView view, ValidationReport report) =>
      CreateViewResult._(view: view, report: report, isSuccess: true);

  factory CreateViewResult.failure(ValidationReport report) =>
      CreateViewResult._(report: report, isSuccess: false);
}
