// lib/presentation/widgets/editor/field_palette.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_form.dart';
import '../../../data/repositories/field_repository.dart';
import '../../providers/field_provider.dart';
import 'draggable_field_widget.dart';

class FieldPalette extends ConsumerStatefulWidget {
  final ViewType viewType;
  const FieldPalette({super.key, required this.viewType});

  @override
  ConsumerState<FieldPalette> createState() => _FieldPaletteState();
}

class _FieldPaletteState extends ConsumerState<FieldPalette> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paletteByCategory = ref.watch(paletteFieldsByCategoryProvider);

    final filtered = _query.isEmpty
        ? paletteByCategory
        : {
            for (final entry in paletteByCategory.entries)
              entry.key: entry.value
                  .where((f) =>
                      f.type.value.contains(_query.toLowerCase()) ||
                      f.defaultLabel.toLowerCase().contains(_query.toLowerCase()))
                  .toList()
          }
          ..removeWhere((key, value) => value.isEmpty);

    return Container(
      color: AppTheme.paletteBackground,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search fields...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white38, size: 16),
                filled: true,
                fillColor: const Color(0xFF3D3D3D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),

          // Groups help tip
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: Colors.white54),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Drag fields onto the canvas or into groups',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // Field list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: filtered.entries.map((entry) {
                return _PaletteCategory(
                  category: entry.key,
                  fields: entry.value,
                );
              }).toList(),
            ),
          ),

          // Add Group button
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.group_add, size: 14, color: Colors.white70),
              label: const Text(
                'Add Group',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                minimumSize: const Size(double.infinity, 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteCategory extends StatefulWidget {
  final String category;
  final List<PaletteField> fields;
  const _PaletteCategory({required this.category, required this.fields});

  @override
  State<_PaletteCategory> createState() => _PaletteCategoryState();
}

class _PaletteCategoryState extends State<_PaletteCategory> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.category.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.fields.map(
            (field) => DraggableFieldWidget(paletteField: field),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}
