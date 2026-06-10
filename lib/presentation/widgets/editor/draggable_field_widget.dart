// lib/presentation/widgets/editor/draggable_field_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_field.dart';
import '../../../data/repositories/field_repository.dart';
import '../../providers/editor_state_provider.dart';

/// Palette item that can be dragged onto the canvas
class DraggableFieldWidget extends ConsumerWidget {
  final PaletteField paletteField;
  const DraggableFieldWidget({super.key, required this.paletteField});

  static const Map<OdooFieldType, Color> _typeColors = {
    OdooFieldType.char: Color(0xFF2196F3),
    OdooFieldType.text: Color(0xFF03A9F4),
    OdooFieldType.html: Color(0xFF00BCD4),
    OdooFieldType.integer: Color(0xFF4CAF50),
    OdooFieldType.float: Color(0xFF8BC34A),
    OdooFieldType.boolean: Color(0xFFFF9800),
    OdooFieldType.date: Color(0xFF9C27B0),
    OdooFieldType.datetime: Color(0xFF673AB7),
    OdooFieldType.selection: Color(0xFFFF5722),
    OdooFieldType.many2one: Color(0xFFF44336),
    OdooFieldType.many2many: Color(0xFFE91E63),
    OdooFieldType.one2many: Color(0xFF795548),
    OdooFieldType.binary: Color(0xFF607D8B),
    OdooFieldType.reference: Color(0xFF9E9E9E),
  };

  Color get _color =>
      _typeColors[paletteField.type] ?? AppTheme.primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newField = OdooField.blank(paletteField.type);

    return Draggable<OdooField>(
      data: newField,
      onDragStarted: () =>
          ref.read(isDraggingProvider.notifier).state = true,
      onDraggableCanceled: (_, __) =>
          ref.read(isDraggingProvider.notifier).state = false,
      onDragEnd: (_) =>
          ref.read(isDraggingProvider.notifier).state = false,

      // Feedback shown while dragging
      feedback: _DragFeedback(
        label: paletteField.defaultLabel,
        icon: paletteField.icon,
        color: _color,
      ),

      // Appearance when dragging (slightly dimmed)
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _PaletteItem(
          paletteField: paletteField,
          color: _color,
        ),
      ),

      child: _PaletteItem(
        paletteField: paletteField,
        color: _color,
      ),
    );
  }
}

class _PaletteItem extends StatefulWidget {
  final PaletteField paletteField;
  final Color color;
  const _PaletteItem({required this.paletteField, required this.color});

  @override
  State<_PaletteItem> createState() => _PaletteItemState();
}

class _PaletteItemState extends State<_PaletteItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppTheme.shortAnimation,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.color.withOpacity(0.15)
              : AppTheme.paletteSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _hovered ? widget.color : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  widget.paletteField.icon,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.paletteField.defaultLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    widget.paletteField.type.value,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.drag_indicator,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _DragFeedback extends StatelessWidget {
  final String label;
  final String icon;
  final Color color;
  const _DragFeedback({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: color,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
