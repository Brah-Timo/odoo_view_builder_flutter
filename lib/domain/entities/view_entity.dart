// lib/domain/entities/view_entity.dart

import '../../data/models/odoo_form.dart';

/// Lightweight summary of a saved view (for list screens)
class ViewSummary {
  final String id;
  final String name;
  final String model;
  final ViewType viewType;
  final int fieldCount;
  final int groupCount;
  final DateTime updatedAt;

  const ViewSummary({
    required this.id,
    required this.name,
    required this.model,
    required this.viewType,
    required this.fieldCount,
    required this.groupCount,
    required this.updatedAt,
  });

  factory ViewSummary.fromView(OdooView view) => ViewSummary(
        id: view.id,
        name: view.name,
        model: view.model,
        viewType: view.viewType,
        fieldCount: view.allFields.length,
        groupCount: view.groups.length,
        updatedAt: view.updatedAt,
      );
}
