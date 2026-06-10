// lib/data/repositories/xml_generator_repository.dart

import '../models/odoo_form.dart';
import '../../services/xml/xml_generator.dart';
import '../../services/xml/xml_parser.dart';
import '../../services/xml/xml_validator.dart';
import '../../services/xml/xml_formatter.dart';

/// High-level repository combining generator, parser, validator and formatter
class XmlGeneratorRepository {
  const XmlGeneratorRepository();

  // ─── Generate ────────────────────────────────────────────────────────────────

  String generateSingle(OdooView view) =>
      XmlGenerator.generateSingle(view);

  String generateFile(List<OdooView> views, {String? moduleName}) =>
      XmlGenerator.generateFile(views, moduleName: moduleName);

  String generateArch(OdooView view) =>
      XmlGenerator.generateArch(view);

  // ─── Parse ───────────────────────────────────────────────────────────────────

  ParseResult parseXml(String content) =>
      XmlParser.parseViewFile(content);

  List<ParseResult> parseAllViews(String content) =>
      XmlParser.parseAllViews(content);

  // ─── Validate ────────────────────────────────────────────────────────────────

  ValidationReport validateView(OdooView view) =>
      XmlValidator.validateView(view);

  ValidationReport validateXmlString(String xml) =>
      XmlValidator.validateXmlString(xml);

  // ─── Format ──────────────────────────────────────────────────────────────────

  String prettyPrint(String raw, {int indentSize = 4}) =>
      XmlFormatter.prettyPrint(raw, indentSize: indentSize);

  String minify(String xml) => XmlFormatter.minify(xml);
}
