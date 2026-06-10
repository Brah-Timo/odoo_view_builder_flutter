// lib/presentation/providers/field_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/odoo_field.dart';
import '../../data/repositories/field_repository.dart';

// ─── Repository ──────────────────────────────────────────────────────────────

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return const FieldRepository();
});

// ─── Palette Fields ──────────────────────────────────────────────────────────

final paletteFieldsProvider = Provider<List<PaletteField>>((ref) {
  return ref.read(fieldRepositoryProvider).getPaletteFields();
});

final paletteFieldsByCategoryProvider =
    Provider<Map<String, List<PaletteField>>>((ref) {
  return ref.read(fieldRepositoryProvider).getPaletteByCategory();
});

// ─── Selected Field Type in Palette ──────────────────────────────────────────

final selectedPaletteFieldProvider =
    StateProvider<PaletteField?>((ref) => null);

// ─── Widget Options ───────────────────────────────────────────────────────────

final widgetOptionsProvider =
    Provider.family<List<WidgetOption>, OdooFieldType>((ref, type) {
  return ref.read(fieldRepositoryProvider).getWidgetOptions(type);
});
