import 'package:get/get.dart';

import '../../domain/entities/tenant_entities.dart';
import '../../domain/usecases/tenant_contract_use_cases.dart';

class TenantContractController extends GetxController {
  TenantContractController({required this.useCases});

  final TenantContractUseCases useCases;

  final tenants = <TenantEntity>[].obs;
  final units = <UnitOption>[].obs;
  final contracts = <ContractEntity>[].obs;
  final isLoading = false.obs;
  final searchText = ''.obs;

  List<TenantEntity> get filteredTenants {
    final query = searchText.value.trim().toLowerCase();

    if (query.isEmpty) return tenants.toList();

    return tenants.where((tenant) {
      return tenant.fullName.toLowerCase().contains(query) ||
          tenant.phone.toLowerCase().contains(query) ||
          tenant.nationalId.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  /// Loads all three collections together.
  /// Existing visible data is preserved if any query fails.
  Future<bool> loadAll({bool showError = true}) async {
    if (isLoading.value) return false;

    isLoading.value = true;

    try {
      final loadedTenants = await useCases.tenants();
      final loadedUnits = await useCases.units();
      final loadedContracts = await useCases.contracts();

      tenants.assignAll(loadedTenants);
      units.assignAll(loadedUnits);
      contracts.assignAll(loadedContracts);

      return true;
    } catch (error) {
      if (showError) _showError(error);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void search(String value) {
    searchText.value = value;
  }

  /// A successful database write remains successful even if refreshing
  /// the displayed lists fails. This prevents duplicate submissions.
  Future<void> _refreshAfterMutation() async {
    final refreshed = await loadAll(showError: false);

    if (!refreshed) {
      Get.snackbar(
        'error'.tr,
        _isArabic
            ? 'تم الحفظ، لكن تعذر تحديث القائمة. يرجى إعادة تحميل الشاشة.'
            : 'Saved, but the list could not be refreshed. Please reload.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<bool> saveTenant(TenantEntity tenant) async {
    try {
      await useCases.saveTenant(tenant);
      await _refreshAfterMutation();

      Get.snackbar('success'.tr, 'tenant_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> deleteTenant(int id) async {
    try {
      await useCases.deleteTenant(id);
      await _refreshAfterMutation();

      Get.snackbar('success'.tr, 'tenant_deleted'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> saveContract(ContractEntity contract) async {
    try {
      await useCases.saveContract(contract);
      await _refreshAfterMutation();

      Get.snackbar('success'.tr, 'contract_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> changeStatus(int id, String status) async {
    try {
      await useCases.changeContractStatus(id, status);
      await _refreshAfterMutation();

      Get.snackbar('success'.tr, 'contract_updated'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  void _showError(Object error) {
    final message = error.toString().toLowerCase();

    String friendlyMessage;

    if (message.contains('already exists') ||
        message.contains('duplicate') ||
        message.contains('unique constraint')) {
      friendlyMessage = _isArabic
          ? 'هذه البيانات مسجلة مسبقاً. يرجى التحقق من المدخلات.'
          : 'This record already exists. Please check the entered information.';
    } else if (message.contains('overlap') ||
        message.contains('conflict') ||
        message.contains('active contract')) {
      friendlyMessage = _isArabic
          ? 'توجد فترة عقد نشط متعارضة لهذه الوحدة.'
          : 'An active contract already overlaps this unit and date range.';
    } else if (message.contains('contract history') ||
        message.contains('foreign key constraint')) {
      friendlyMessage = _isArabic
          ? 'لا يمكن تنفيذ العملية لوجود سجلات مرتبطة بهذا العنصر.'
          : 'This operation cannot be completed because related records exist.';
    } else if (message.contains('not found') ||
        message.contains('no longer exists')) {
      friendlyMessage = _isArabic
          ? 'السجل المطلوب غير موجود أو تم تغييره.'
          : 'The requested record was not found or has changed.';
    } else {
      friendlyMessage = _isArabic
          ? 'تعذر إكمال العملية. يرجى مراجعة البيانات والمحاولة مرة أخرى.'
          : 'The operation could not be completed. Check the data and try again.';
    }

    Get.snackbar(
      'error'.tr,
      friendlyMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}
