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

  Future<void> loadAll() async {
    isLoading.value = true;

    try {
      tenants.assignAll(await useCases.tenants());
      units.assignAll(await useCases.units());
      contracts.assignAll(await useCases.contracts());
    } catch (e) {
      _showError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void search(String value) {
    searchText.value = value;
  }

  Future<bool> saveTenant(TenantEntity tenant) async {
    try {
      await useCases.saveTenant(tenant);
      await loadAll();
      Get.snackbar('Success', 'Tenant saved successfully');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> deleteTenant(int id) async {
    try {
      await useCases.deleteTenant(id);
      await loadAll();
      Get.snackbar('Success', 'Tenant deleted');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> saveContract(ContractEntity contract) async {
    try {
      await useCases.saveContract(contract);
      await loadAll();
      Get.snackbar('Success', 'Contract saved successfully');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  Future<bool> changeStatus(int id, String status) async {
    try {
      await useCases.changeContractStatus(id, status);
      await loadAll();
      Get.snackbar('Success', 'Contract updated');
      return true;
    } catch (e) {
      _showError(e);
      return false;
    }
  }

  void _showError(Object error) {
    Get.snackbar(
      'Operation failed',
      error.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}