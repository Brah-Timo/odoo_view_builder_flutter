// lib/domain/usecases/validate_view_usecase.dart

import '../../data/models/odoo_form.dart';
import '../../services/xml/xml_validator.dart';

class ValidateViewUseCase {
  const ValidateViewUseCase();

  ValidationReport execute(OdooView view) =>
      XmlValidator.validateView(view);

  ValidationReport validateXml(String xmlContent) =>
      XmlValidator.validateXmlString(xmlContent);
}
