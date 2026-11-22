import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/services/preferences_service.dart';
import '../../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final preferences = Get.find<PreferencesService>();
  final _database = Get.find<LocalDatabase>();

  final dashboardMetrics = <String, num>{}.obs;
  final isLoadingDashboard = false.obs;
  final dashboardError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<num> _count(String table, {String? where, List<Object?>? args}) async {
    final result = await _database.database.rawQuery(
      'SELECT COUNT(*) AS total FROM $table'
      '${where == null ? '' : ' WHERE $where'}',
      args,
    );
    return (result.first['total'] as num?) ?? 0;
  }

  Future<num> _sum(String table, String column) async {
    final result = await _database.database.rawQuery(
      'SELECT COALESCE(SUM($column), 0) AS total FROM $table',
    );
    return (result.first['total'] as num?) ?? 0;
  }

  Future<num> _outstandingBalance({bool overdueOnly = false}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await _database.database.rawQuery('''
      SELECT COALESCE(
        SUM(
          CASE
            WHEN d.amount - COALESCE(
              (
                SELECT SUM(pa.allocated_amount)
                FROM payment_allocations pa
                WHERE pa.due_id = d.id
              ), 0
            ) > 0
            THEN d.amount - COALESCE(
              (
                SELECT SUM(pa.allocated_amount)
                FROM payment_allocations pa
                WHERE pa.due_id = d.id
              ), 0
            )
            ELSE 0
          END
        ), 0
      ) AS total
      FROM dues d
      ${overdueOnly ? "WHERE date(d.due_date) < date(?)" : ""}
      ''', overdueOnly ? [today] : null);

    return (result.first['total'] as num?) ?? 0;
  }

  Future<void> loadDashboard() async {
    isLoadingDashboard.value = true;
    dashboardError.value = '';

    try {
      final metrics = <String, num>{
        'properties': await _count('properties'),
        'units': await _count('units'),
        'available': await _count(
          'units',
          where: 'LOWER(status) = ?',
          args: ['available'],
        ),
        'occupied': await _count(
          'units',
          where: 'LOWER(status) = ?',
          args: ['occupied'],
        ),
        'tenants': await _count('tenants'),
        'activeContracts': await _count(
          'contracts',
          where: 'LOWER(status) = ?',
          args: ['active'],
        ),
        'payments': await _sum('payments', 'amount'),
        'outstanding': await _outstandingBalance(),
        'overdue': await _outstandingBalance(overdueOnly: true),
      };

      dashboardMetrics.assignAll(metrics);
    } catch (error) {
      dashboardError.value = error.toString();
    } finally {
      isLoadingDashboard.value = false;
    }
  }

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

  void lockApp() {
    Get.offAllNamed(AppRoutes.pinVerify);
  }

  void openChangePin() {
    Get.toNamed(AppRoutes.pinChange);
  }

  void openProperties() => Get.toNamed(AppRoutes.properties);

  void openTenantContracts() => Get.toNamed(AppRoutes.tenantContracts);

  void openServices() => Get.toNamed(AppRoutes.services);

  void openAuditLogs() => Get.toNamed(AppRoutes.auditLogs);

  void openReports() => Get.toNamed(AppRoutes.reports);
}
