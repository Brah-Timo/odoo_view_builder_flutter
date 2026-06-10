// lib/presentation/widgets/editor/drop_target_zone.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../data/models/odoo_field.dart';
import '../../providers/editor_state_provider.dart';

/// A drop zone that accepts OdooField items dragged from the palette
class DropTargetZone extends ConsumerStatefulWidget {
  final Widget child;
  final String? label;
  final bool isEmpty;
  final ValueChanged<OdooField> onFieldDropped;
  final bool showBorderAlways;

  const DropTargetZone({
    super.key,
    required this.child,
    required this.onFieldDropped,
    this.label,
    this.isEmpty = false,
    this.showBorderAlways = false,
  });

  @override
  ConsumerState<DropTargetZone> createState() => _DropTargetZoneState();
}

class _DropTargetZoneState extends ConsumerState<DropTargetZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final isDragging = ref.watch(isDraggingProvider);

    return DragTarget<OdooField>(
      onWillAcceptWithDetails: (details) {
        setState(() => _isHovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _isHovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _isHovering = false);
        widget.onFieldDropped(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = _isHovering || candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: AppTheme.shortAnimation,
          decoration: BoxDecoration(
            color: isActive
                ? AppTheme.dropZoneActive
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: (isActive || widget.showBorderAlways || widget.isEmpty)
                ? Border.all(
                    color: isActive
                        ? AppTheme.dropZoneBorder
                        : (widget.isEmpty && isDragging)
                            ? AppTheme.primaryColor.withOpacity(0.4)
                            : AppTheme.fieldCardBorder,
                    width: isActive ? 2 : 1,
                  )
                : null,
          ),
          child: widget.isEmpty && isDragging && !isActive
              ? _EmptyDropHint(label: widget.label)
              : widget.child,
        );
      },
    );
  }
}

class _EmptyDropHint extends StatelessWidget {
  final String? label;
  const _EmptyDropHint({this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 28,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            label ?? 'Drop field here',
            style: TextStyle(
              color: AppTheme.primaryColor.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Smaller inline drop zone for inserting between existing fields
class InlineDropZone extends ConsumerStatefulWidget {
  final ValueChanged<OdooField> onFieldDropped;
  const InlineDropZone({super.key, required this.onFieldDropped});

  @override
  ConsumerState<InlineDropZone> createState() => _InlineDropZoneState();
}

class _InlineDropZoneState extends ConsumerState<InlineDropZone> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isDragging = ref.watch(isDraggingProvider);

    if (!isDragging) return const SizedBox(height: 4);

    return DragTarget<OdooField>(
      onWillAcceptWithDetails: (_) {
        setState(() => _hovering = true);
        return true;
      },
      onLeave: (_) => setState(() => _hovering = false),
      onAcceptWithDetails: (details) {
        setState(() => _hovering = false);
        widget.onFieldDropped(details.data);
      },
      builder: (_, candidates, __) {
        return AnimatedContainer(
          duration: AppTheme.shortAnimation,
          height: _hovering ? 40 : 8,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: _hovering
                ? AppTheme.dropZoneActive
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovering
                  ? AppTheme.dropZoneBorder
                  : AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: _hovering
              ? const Center(
                  child: Text(
                    'Drop here',
                    style: TextStyle(
                        color: AppTheme.dropZoneBorder, fontSize: 11),
                  ),
                )
              : null,
        );
      },
    );
  }
}
