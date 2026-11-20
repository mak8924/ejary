import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends GetxService {
  late SharedPreferences _preferences;

  static const _themeKey = 'theme_mode';
  static const _localeKey = 'app_locale';

  Future<PreferencesService> init() async {
    _preferences = await SharedPreferences.getInstance();
    return this;
  }

  ThemeMode get themeMode {
    switch (_preferences.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale {
    final value = _preferences.getString(_localeKey) ?? 'en';
    return value == 'ar' ? const Locale('ar', 'YE') : const Locale('en', 'US');
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _preferences.setString(_themeKey, value);
  }

  Future<void> saveLocale(Locale locale) async {
    await _preferences.setString(
      _localeKey,
      locale.languageCode == 'ar' ? 'ar' : 'en',
    );
  }
}
