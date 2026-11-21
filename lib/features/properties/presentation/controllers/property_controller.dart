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

    return properties.where((property) {
      return property.name.toLowerCase().contains(query) ||
          property.address.toLowerCase().contains(query);
    }).toList();
  }

  bool get _isArabic => Get.locale?.languageCode == 'ar';

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
        final matches = properties.where((p) => p.id == selectedId);

        if (matches.isNotEmpty) {
          selectedProperty.value = matches.first;
          await loadPropertyDetails(selectedId);
        } else {
          selectedProperty.value = null;
          departments.clear();
          units.clear();
        }
      }
    } catch (error) {
      _error(error);
    } finally {
      isLoading.value = false;
    }
  }

  void searchProperties(String value) {
    searchText.value = value;
  }

  Future<void> selectProperty(PropertyEntity property) async {
    selectedProperty.value = property;

    final id = property.id;
    if (id == null) return;

    await loadPropertyDetails(id);
  }

  Future<bool> loadPropertyDetails(int id) async {
    try {
      departments.assignAll(await useCases.departments(id));
      units.assignAll(await useCases.units(id));
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> saveProperty(PropertyEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addProperty(value);
      } else {
        await useCases.updateProperty(value);
      }

      await loadProperties();
      _success(
        _isArabic ? 'تم حفظ العقار بنجاح.' : 'Property saved successfully.',
      );
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> removeProperty(int id) async {
    try {
      await useCases.deleteProperty(id);
      await loadProperties();

      _success(_isArabic ? 'تم حذف العقار.' : 'Property deleted.');
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> saveDepartment(DepartmentEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addDepartment(value);
      } else {
        await useCases.updateDepartment(value);
      }

      await loadPropertyDetails(value.propertyId);

      _success(
        _isArabic ? 'تم حفظ القسم بنجاح.' : 'Department saved successfully.',
      );
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> removeDepartment(int id) async {
    final propertyId = selectedProperty.value?.id;

    if (propertyId == null) {
      _error(StateError('No property is selected.'));
      return false;
    }

    try {
      await useCases.deleteDepartment(id);
      await loadPropertyDetails(propertyId);

      _success(_isArabic ? 'تم حذف القسم.' : 'Department deleted.');
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> saveUnit(UnitEntity value) async {
    try {
      if (value.id == null) {
        await useCases.addUnit(value);
      } else {
        await useCases.updateUnit(value);
      }

      await loadPropertyDetails(value.propertyId);

      _success(_isArabic ? 'تم حفظ الوحدة بنجاح.' : 'Unit saved successfully.');
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  Future<bool> removeUnit(int id) async {
    final propertyId = selectedProperty.value?.id;

    if (propertyId == null) {
      _error(StateError('No property is selected.'));
      return false;
    }

    try {
      await useCases.deleteUnit(id);
      await loadPropertyDetails(propertyId);

      _success(_isArabic ? 'تم حذف الوحدة.' : 'Unit deleted.');
      return true;
    } catch (error) {
      _error(error);
      return false;
    }
  }

  void _success(String message) {
    Get.snackbar(
      _isArabic ? 'نجاح' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  void _error(Object error) {
    final message = error.toString().toLowerCase();
    String friendlyMessage;

    if (message.contains('property with this name already exists')) {
      friendlyMessage = _isArabic
          ? 'اسم العقار موجود بالفعل. اختاري اسمًا آخر.'
          : 'A property with this name already exists. Choose another name.';
    } else if (message.contains('department with this name already exists')) {
      friendlyMessage = _isArabic
          ? 'اسم القسم موجود بالفعل في هذا العقار.'
          : 'A department with this name already exists in this property.';
    } else if (message.contains('unit number already exists') ||
        message.contains('unit with this number already exists')) {
      friendlyMessage = _isArabic
          ? 'رقم الوحدة موجود بالفعل في هذا العقار.'
          : 'A unit with this number already exists in this property.';
    } else if (message.contains('floor number cannot be negative')) {
      friendlyMessage = _isArabic
          ? 'رقم الطابق لا يمكن أن يكون سالبًا.'
          : 'Floor number cannot be negative.';
    } else if (message.contains('area must be greater than zero')) {
      friendlyMessage = _isArabic
          ? 'المساحة يجب أن تكون أكبر من صفر.'
          : 'Area must be greater than zero.';
    } else if (message.contains('monthly rent cannot be negative')) {
      friendlyMessage = _isArabic
          ? 'الإيجار الشهري لا يمكن أن يكون سالبًا.'
          : 'Monthly rent cannot be negative.';
    } else if (message.contains('department does not belong')) {
      friendlyMessage = _isArabic
          ? 'القسم المحدد لا يتبع هذا العقار.'
          : 'The selected department does not belong to this property.';
    } else if (message.contains('cannot delete property')) {
      friendlyMessage = _isArabic
          ? 'لا يمكن حذف العقار قبل معالجة الأقسام والوحدات المرتبطة به.'
          : 'This property cannot be deleted while it has linked departments or units.';
    } else if (message.contains('cannot delete unit')) {
      friendlyMessage = _isArabic
          ? 'لا يمكن حذف هذه الوحدة لوجود عقود مرتبطة بها.'
          : 'This unit cannot be deleted because it has linked contracts.';
    } else {
      friendlyMessage = _isArabic
          ? 'تعذّر إتمام العملية. راجعي البيانات وحاولي مرة أخرى.'
          : 'The operation could not be completed. Check the information and try again.';
    }

    Get.snackbar(
      _isArabic ? 'خطأ' : 'Error',
      friendlyMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }
}
