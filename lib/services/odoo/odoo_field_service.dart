// lib/services/odoo/odoo_field_service.dart

import '../../data/models/odoo_field.dart';
import 'odoo_api_client.dart';

class OdooFieldService {
  final OdooApiClient _client;

  OdooFieldService(this._client);

  /// Fetches real field definitions from a live Odoo instance
  Future<List<OdooField>> fetchFields(String model) async {
    final infos = await _client.fetchModelFields(model);
    return infos.map((info) => info.toOdooField()).toList();
  }
}
