import 'package:get/get.dart';

import '../../data/repositories/dues_payments_repository.dart';

class DuesPaymentsController extends GetxController {
  DuesPaymentsController({required this.repository});

  final DuesPaymentsRepository repository;

  final dues = <Map<String, Object?>>[].obs;
  final payments = <Map<String, Object?>>[].obs;
  final allocations = <Map<String, Object?>>[].obs;
  final contracts = <Map<String, Object?>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final results = await Future.wait([
        repository.getDues(),
        repository.getPayments(),
        repository.getAllocations(),
        repository.getContracts(),
      ]);

      dues.assignAll(results[0]);
      payments.assignAll(results[1]);
      allocations.assignAll(results[2]);
      contracts.assignAll(results[3]);
    } catch (error) {
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createManualDue({
    required int contractId,
    required String description,
    required double amount,
    required String dueDate,
  }) async {
    try {
      await repository.createManualDue(
        contractId: contractId,
        description: description,
        amount: amount,
        dueDate: dueDate,
      );
      await loadData();
      Get.snackbar('success'.tr, 'due_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> recordPayment({
    required int contractId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    required String referenceNumber,
    required String notes,
  }) async {
    try {
      await repository.recordPayment(
        contractId: contractId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      await loadData();
      Get.snackbar('success'.tr, 'payment_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> allocatePayment({
    required int paymentId,
    required int dueId,
    required double amount,
  }) async {
    try {
      await repository.allocatePayment(
        paymentId: paymentId,
        dueId: dueId,
        amount: amount,
      );
      await loadData();
      Get.snackbar('success'.tr, 'allocation_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  void _showError(Object error) {
    Get.snackbar(
      'error'.tr,
      error.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}
