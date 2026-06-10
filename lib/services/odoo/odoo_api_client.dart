// lib/services/odoo/odoo_api_client.dart
//
// Optional: connect to a live Odoo instance via JSON-RPC
// to fetch model fields. Feature-flagged by AppConfig.enableOdooConnection.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/odoo_field.dart';

class OdooConnectionConfig {
  final String baseUrl;
  final String database;
  final String username;
  final String apiKey;

  const OdooConnectionConfig({
    required this.baseUrl,
    required this.database,
    required this.username,
    required this.apiKey,
  });
}

class OdooApiClient {
  final OdooConnectionConfig config;
  String? _sessionId;

  OdooApiClient(this.config);

  Uri _endpoint(String path) {
    final base = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    return Uri.parse('$base$path');
  }

  // ─── Authentication ────────────────────────────────────────────────────

  Future<bool> authenticate() async {
    try {
      final response = await http.post(
        _endpoint('/web/session/authenticate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'db': config.database,
            'login': config.username,
            'password': config.apiKey,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result != null && result['uid'] != null) {
          _sessionId = response.headers['set-cookie'];
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── Fetch Model Fields ────────────────────────────────────────────────

  Future<List<OdooFieldInfo>> fetchModelFields(String model) async {
    try {
      final response = await http.post(
        _endpoint('/web/dataset/call_kw'),
        headers: {
          'Content-Type': 'application/json',
          if (_sessionId != null) 'Cookie': _sessionId!,
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': model,
            'method': 'fields_get',
            'args': <dynamic>[],
            'kwargs': {
              'attributes': [
                'type',
                'string',
                'required',
                'readonly',
                'relation',
                'selection',
              ],
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = data['result'] as Map<String, dynamic>?;
        if (result == null) return [];

        return result.entries.map((entry) {
          final info = entry.value as Map<String, dynamic>;
          return OdooFieldInfo(
            name: entry.key,
            type: info['type'] as String? ?? 'char',
            label: info['string'] as String?,
            required: info['required'] as bool? ?? false,
            readonly: info['readonly'] as bool? ?? false,
            comodel: info['relation'] as String?,
          );
        }).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}

/// Raw field info from Odoo API
class OdooFieldInfo {
  final String name;
  final String type;
  final String? label;
  final bool required;
  final bool readonly;
  final String? comodel;

  const OdooFieldInfo({
    required this.name,
    required this.type,
    this.label,
    this.required = false,
    this.readonly = false,
    this.comodel,
  });

  /// Convert to OdooField with a generated ID
  OdooField toOdooField() {
    return OdooField.create(
      name: name,
      fieldType: OdooFieldType.fromString(type),
      label: label,
    ).copyWith(
      required: required,
      readonly: readonly,
      comodel: comodel,
    );
  }
}


