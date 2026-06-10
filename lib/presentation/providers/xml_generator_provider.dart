// lib/presentation/providers/xml_generator_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/xml_generator_repository.dart';
import '../../services/xml/xml_validator.dart';
import 'editor_state_provider.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final xmlRepositoryProvider = Provider<XmlGeneratorRepository>((ref) {
  return const XmlGeneratorRepository();
});

// ─── Live XML Output ─────────────────────────────────────────────────────────

/// The generated XML for the current view in the editor.
/// Automatically recomputes when the view changes.
final liveXmlProvider = Provider<String>((ref) {
  final view = ref.watch(currentViewProvider);
  if (view == null) return '<!-- No view selected -->';
  return view.generateXml();
});

/// The arch-only XML (without <odoo><data><record> wrapper)
final archXmlProvider = Provider<String>((ref) {
  final view = ref.watch(currentViewProvider);
  if (view == null) return '<!-- No view selected -->';
  final repo = ref.read(xmlRepositoryProvider);
  return repo.generateArch(view);
});

// ─── Validation ──────────────────────────────────────────────────────────────

/// Validation report for the current view
final validationReportProvider = Provider<ValidationReport?>((ref) {
  final view = ref.watch(currentViewProvider);
  if (view == null) return null;
  final repo = ref.read(xmlRepositoryProvider);
  return repo.validateView(view);
});

final isViewValidProvider = Provider<bool>((ref) {
  final report = ref.watch(validationReportProvider);
  return report?.isValid ?? false;
});
