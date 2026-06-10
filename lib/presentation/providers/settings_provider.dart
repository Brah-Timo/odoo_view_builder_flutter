// lib/presentation/providers/settings_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

// ─── Theme Mode ──────────────────────────────────────────────────────────────

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(AppConstants.prefThemeMode) ?? 'light';
    state = switch (val) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefThemeMode, mode.name);
  }

  void toggle() {
    setThemeMode(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

// ─── Odoo Version ────────────────────────────────────────────────────────────

final odooVersionProvider =
    StateNotifierProvider<OdooVersionNotifier, String>((ref) {
  return OdooVersionNotifier();
});

class OdooVersionNotifier extends StateNotifier<String> {
  OdooVersionNotifier() : super('16.0') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(AppConstants.prefOdooVersion) ?? '16.0';
  }

  Future<void> setVersion(String version) async {
    state = version;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefOdooVersion, version);
  }
}

// ─── XML Settings ────────────────────────────────────────────────────────────

final xmlIndentSizeProvider =
    StateNotifierProvider<IntSettingNotifier, int>((ref) {
  return IntSettingNotifier(AppConstants.prefIndentSize, 4);
});

final showLineNumbersProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefShowLineNumbers, true);
});

final autoSaveProvider =
    StateNotifierProvider<BoolSettingNotifier, bool>((ref) {
  return BoolSettingNotifier(AppConstants.prefAutoSave, true);
});

// ─── Default Preferences ─────────────────────────────────────────────────────

final defaultModelProvider =
    StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier(
      AppConstants.prefDefaultModel, AppConstants.defaultModel);
});

final defaultModuleProvider =
    StateNotifierProvider<StringSettingNotifier, String>((ref) {
  return StringSettingNotifier(
      AppConstants.prefDefaultModule, AppConstants.defaultModuleName);
});

// ─── Generic notifiers ───────────────────────────────────────────────────────

class IntSettingNotifier extends StateNotifier<int> {
  final String _key;
  IntSettingNotifier(this._key, int defaultValue) : super(defaultValue) {
    _load(defaultValue);
  }

  Future<void> _load(int def) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? def;
  }

  Future<void> set(int value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, value);
  }
}

class BoolSettingNotifier extends StateNotifier<bool> {
  final String _key;
  BoolSettingNotifier(this._key, bool defaultValue) : super(defaultValue) {
    _load(defaultValue);
  }

  Future<void> _load(bool def) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? def;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  void toggle() => set(!state);
}

class StringSettingNotifier extends StateNotifier<String> {
  final String _key;
  StringSettingNotifier(this._key, String defaultValue) : super(defaultValue) {
    _load(defaultValue);
  }

  Future<void> _load(String def) async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key) ?? def;
  }

  Future<void> set(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}
