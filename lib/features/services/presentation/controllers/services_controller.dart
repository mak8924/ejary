import 'package:get/get.dart';

import '../../data/repositories/services_repository.dart';

class ServicesController extends GetxController {
  final ServicesRepository repository;

  ServicesController({required this.repository});

  final services = <Map<String, Object?>>[].obs;
  final contracts = <Map<String, Object?>>[].obs;
  final assignments = <Map<String, Object?>>[].obs;
  final isLoading = false.obs;

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        repository.getServices(),
        repository.getContracts(),
        repository.getAssignments(),
      ]);
      services.assignAll(results[0]);
      contracts.assignAll(results[1]);
      assignments.assignAll(results[2]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveService({
    int? id,
    required String name,
    required String description,
    required double amount,
    required String billingPeriod,
  }) async {
    try {
      await repository.saveService(
        id: id,
        name: name,
        description: description,
        amount: amount,
        billingPeriod: billingPeriod,
      );
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar(
        'Error'.tr,
        error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deactivateService(int id) async {
    try {
      await repository.deactivateService(id);
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
      return false;
    }
  }

  Future<bool> assignService({
    required int contractId,
    required int serviceId,
    required double amount,
  }) async {
    try {
      await repository.assignService(
        contractId: contractId,
        serviceId: serviceId,
        amount: amount,
      );
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
      return false;
    }
  }

  Future<void> removeAssignment(int id) async {
    try {
      await repository.removeAssignment(id);
      await loadData();
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
}
