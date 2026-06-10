// lib/data/local_storage/shared_preferences_helper.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Simple typed wrapper around SharedPreferences
class SharedPrefsHelper {
  SharedPrefsHelper._();
  static SharedPrefsHelper instance = SharedPrefsHelper._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getString(String key) async =>
      (await prefs).getString(key);

  Future<void> setString(String key, String value) async =>
      (await prefs).setString(key, value);

  Future<bool> getBool(String key, {bool defaultValue = false}) async =>
      (await prefs).getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) async =>
      (await prefs).setBool(key, value);

  Future<int> getInt(String key, {int defaultValue = 0}) async =>
      (await prefs).getInt(key) ?? defaultValue;

  Future<void> setInt(String key, int value) async =>
      (await prefs).setInt(key, value);

  Future<void> remove(String key) async =>
      (await prefs).remove(key);

  Future<void> clear() async => (await prefs).clear();
}
