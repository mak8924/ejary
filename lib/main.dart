import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/locale/app_translations.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final preferences = await PreferencesService().init();
  Get.put<PreferencesService>(preferences, permanent: true);

  runApp(const StarterApp());
}

class StarterApp extends StatelessWidget {
  const StarterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = Get.find<PreferencesService>();

    return GetMaterialApp(
      title: 'EJARY',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: preferences.themeMode,
      translations: AppTranslations(),
      locale: preferences.locale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppPages.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}
