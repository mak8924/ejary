import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:get/get.dart';

import 'core/database/local_database.dart';
import 'core/locale/app_translations.dart';
import 'core/services/preferences_service.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

Future<void> inspectEjaryDatabase() async {
  final db = LocalDatabase().database;

  debugPrint('========== EJARY DATABASE INSPECTION ==========');
  final versionResult = await db.rawQuery('PRAGMA user_version');
  debugPrint('Database version: ${versionResult.first['user_version']}');

  final tables = await db.rawQuery("""
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  """);

  for (final item in tables) {
    final table = item['name'] as String;

    debugPrint('\n========== TABLE: $table ==========');

    final columns = await db.rawQuery('PRAGMA table_info("$table")');

    for (final column in columns) {
      debugPrint(
        'Column: ${column['name']} | '
        'Type: ${column['type']} | '
        'Not Null: ${column['notnull']} | '
        'Primary Key: ${column['pk']}',
      );
    }

    final count = await db.rawQuery('SELECT COUNT(*) AS total FROM "$table"');

    debugPrint('RECORD COUNT: ${count.first['total']}');

    final foreignKeys = await db.rawQuery('PRAGMA foreign_key_list("$table")');

    for (final fk in foreignKeys) {
      debugPrint('FOREIGN KEY: $fk');
    }

    final indexes = await db.rawQuery('PRAGMA index_list("$table")');

    for (final index in indexes) {
      debugPrint('INDEX: $index');
    }
  }

  final integrity = await db.rawQuery('PRAGMA integrity_check');

  debugPrint('\n========== INTEGRITY CHECK ==========');
  debugPrint('$integrity');
  debugPrint('========== INSPECTION COMPLETE ==========');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  final database = await LocalDatabase().init();
  Get.put<LocalDatabase>(database, permanent: true);

  await inspectEjaryDatabase();

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'YE'),
        Locale('en'),
        Locale('ar'),
      ],
      getPages: AppPages.pages,
      initialRoute: AppRoutes.splash,
    );
  }
}
