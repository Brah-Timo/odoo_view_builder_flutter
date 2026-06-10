// lib/presentation/widgets/kanban/kanban_field_mapper.dart

import '../../../data/models/odoo_field.dart';
import '../../../data/models/odoo_kanban_view.dart';

/// Maps a list of OdooField into a KanbanCardTemplate
class KanbanFieldMapper {
  KanbanFieldMapper._();

  /// Auto-assign fields to header / body / footer based on type
  static KanbanCardTemplate autoMap(List<OdooField> fields) {
    final header = <KanbanCardField>[];
    final body = <KanbanCardField>[];
    final footer = <KanbanCardField>[];

    for (final field in fields) {
      if (field.invisible) continue;

      final kf = KanbanCardField.fromField(field);

      if (_isHeaderField(field)) {
        header.add(kf.copyWith(bold: true));
      } else if (_isFooterField(field)) {
        footer.add(kf);
      } else {
        body.add(kf);
      }
    }

    return KanbanCardTemplate(
      headerFields: header,
      bodyFields: body,
      footerFields: footer,
    );
  }

  static bool _isHeaderField(OdooField f) {
    return f.name == 'name' ||
        f.name == 'display_name' ||
        f.widget == 'statusbar' ||
        f.fieldType == OdooFieldType.many2one && f.name.endsWith('_id');
  }

  static bool _isFooterField(OdooField f) {
    return f.fieldType == OdooFieldType.many2one ||
        f.fieldType == OdooFieldType.selection ||
        f.name == 'user_id' ||
        f.name == 'priority' ||
        f.widget == 'priority';
  }
}
