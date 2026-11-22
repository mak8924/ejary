import 'package:get/get.dart';

import '../../data/repositories/audit_reports_repository.dart';

class AuditReportsController extends GetxController {
  AuditReportsController({required this.repository});

  final AuditReportsRepository repository;

  final auditLogs = <Map<String, Object?>>[].obs;
  final summary = <String, num>{}.obs;
  final isLoadingLogs = false.obs;
  final isLoadingReports = false.obs;
  final searchText = ''.obs;
  final selectedAction = 'all'.obs;
  final selectedEntity = 'all'.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAuditLogs();
    loadReports();
  }

  Future<void> loadAuditLogs() async {
    isLoadingLogs.value = true;
    errorMessage.value = '';
    try {
      final result = await repository.getAuditLogs(
        search: searchText.value,
        action: selectedAction.value,
        entity: selectedEntity.value,
      );
      auditLogs.assignAll(result);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoadingLogs.value = false;
    }
  }

  Future<void> loadReports() async {
    isLoadingReports.value = true;
    errorMessage.value = '';
    try {
      final result = await repository.getReportSummary();
      summary.assignAll(result);
    } catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoadingReports.value = false;
    }
  }

  Future<void> updateSearch(String value) async {
    searchText.value = value;
    await loadAuditLogs();
  }

  Future<void> updateAction(String? value) async {
    if (value == null) return;
    selectedAction.value = value;
    await loadAuditLogs();
  }

  Future<void> updateEntity(String? value) async {
    if (value == null) return;
    selectedEntity.value = value;
    await loadAuditLogs();
  }

  num metric(String key) => summary[key] ?? 0;

  String formatAmount(num value) => value.toStringAsFixed(2);
}