import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/preferences_service.dart';
import '../../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final preferences = Get.find<PreferencesService>();

  Future<void> setTheme(ThemeMode mode) async {
    await preferences.saveThemeMode(mode);
    Get.changeThemeMode(mode);
  }

  Future<void> setLanguage(String languageCode) async {
    final locale = languageCode == 'ar'
        ? const Locale('ar', 'YE')
        : const Locale('en', 'US');
    await preferences.saveLocale(locale);
    Get.updateLocale(locale);
  }

  void lockApp() => Get.offAllNamed(AppRoutes.pinVerify);

  void openChangePin() => Get.toNamed(AppRoutes.pinChange);
}
