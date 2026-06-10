// lib/domain/usecases/import_xml_usecase.dart

import '../../data/models/odoo_form.dart';
import '../../data/repositories/view_repository.dart';
import '../../services/xml/xml_parser.dart';

class ImportXmlUseCase {
  final ViewRepository _repository;

  const ImportXmlUseCase(this._repository);

  Future<ImportResult> execute(String xmlContent, {bool saveAll = true}) async {
    final results = XmlParser.parseAllViews(xmlContent);
    final imported = <OdooView>[];
    final errors = <String>[];

    for (final result in results) {
      if (result.isSuccess && result.view != null) {
        if (saveAll) await _repository.save(result.view!);
        imported.add(result.view!);
      } else if (result.error != null) {
        errors.add(result.error!);
      }
    }

    return ImportResult(
      importedViews: imported,
      errors: errors,
    );
  }
}

class ImportResult {
  final List<OdooView> importedViews;
  final List<String> errors;

  const ImportResult({required this.importedViews, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  bool get hasImports => importedViews.isNotEmpty;
  int get count => importedViews.length;
}
