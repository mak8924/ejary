import 'package:get/get.dart';

import '../../domain/entities/property_entities.dart';
import '../../domain/usecases/property_use_cases.dart';

class PropertyController extends GetxController {
  final PropertyUseCases useCases;

  PropertyController({required this.useCases});

  final properties = <PropertyEntity>[].obs;
  final departments = <DepartmentEntity>[].obs;
  final units = <UnitEntity>[].obs;
  final selectedProperty = Rxn<PropertyEntity>();
  final searchText = ''.obs;
  final isLoading = false.obs;

  List<PropertyEntity> get filteredProperties {
    final query = searchText.value.trim().toLowerCase();
    if (query.isEmpty) return properties;
    return properties
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              p.address.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadProperties();
  }

  Future<void> loadProperties() async {
    isLoading.value = true;
    try {
      properties.assignAll(await useCases.properties());

      final selectedId = selectedProperty.value?.id;
      if (selectedId != null) {
        final match = properties.where((p) => p.id == selectedId);
        if (match.isNotEmpty) {
          selectedProperty.value = match.first;
          await loadPropertyDetails(selectedId);
        } else {
          selectedProperty.value = null;
          departments.clear();
          units.clear();
        }
      }
    } catch (e) {
      _error(e);
    } finally {
      isLoading.value = false;
    }
  }

  void searchProperties(String value) => searchText.value = value;

  Future<void> selectProperty(PropertyEntity property) async {
    selectedProperty.value = property;
    await loadPropertyDetails(property.id!);
  }

  Future<void> loadPropertyDetails(int id) async {
    try {
      departments.assignAll(await useCases.departments(id));
      units.assignAll(await useCases.units(id));
    } catch (e) {
      _error(e);
    }
  }

  Future<void> saveProperty(PropertyEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addProperty(value);
      } else {
        await useCases.updateProperty(value);
      }
      await loadProperties();
      Get.snackbar('Success'.tr, 'Property saved successfully'.tr);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> removeProperty(int id) async {
    try {
      await useCases.deleteProperty(id);
      await loadProperties();
      Get.snackbar('Success'.tr, 'Property deleted'.tr);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> saveDepartment(DepartmentEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addDepartment(value);
      } else {
        await useCases.updateDepartment(value);
      }
      await loadPropertyDetails(value.propertyId);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> removeDepartment(int id) async {
    final propertyId = selectedProperty.value?.id;
    if (propertyId == null) return;
    try {
      await useCases.deleteDepartment(id);
      await loadPropertyDetails(propertyId);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> saveUnit(UnitEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addUnit(value);
      } else {
        await useCases.updateUnit(value);
      }
      await loadPropertyDetails(value.propertyId);
    } catch (e) {
      _error(e);
    }
  }

  Future<void> removeUnit(int id) async {
    final propertyId = selectedProperty.value?.id;
    if (propertyId == null) return;
    try {
      await useCases.deleteUnit(id);
      await loadPropertyDetails(propertyId);
    } catch (e) {
      _error(e);
    }
  }

  void _error(Object error) {
    Get.snackbar(
      'Error',
      'Operation failed: $error',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
