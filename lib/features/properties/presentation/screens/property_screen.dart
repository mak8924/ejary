import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/property_entities.dart';
import '../controllers/property_controller.dart';

class PropertyScreen extends GetView<PropertyController> {
  const PropertyScreen({super.key});

  bool get isArabic => Get.locale?.languageCode == 'ar';
  String trText(String en, String ar) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            trText('Property Management', 'ط¥ط¯ط§ط±ط© ط§ظ„ط¹ظ‚ط§ط±ط§طھ'),
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value && controller.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: controller.searchProperties,
                  decoration: InputDecoration(
                    hintText: trText(
                      'Search properties...',
                      'ط§ط¨ط­ط« ط¹ظ† ط¹ظ‚ط§ط±...',
                    ),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: controller.filteredProperties.isEmpty
                    ? Center(
                        child: Text(
                          trText(
                            'No properties yet',
                            'ظ„ط§ طھظˆط¬ط¯ ط¹ظ‚ط§ط±ط§طھ ط¨ط¹ط¯',
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: controller.filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = controller.filteredProperties[index];
                          final selected =
                              property.id ==
                              controller.selectedProperty.value?.id;

                          return SizedBox(
                            width: 245,
                            child: Card(
                              color: selected
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : null,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    controller.selectProperty(property),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.apartment),
                                          const Spacer(),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                _propertyDialog(property),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () => _confirmDelete(
                                              trText(
                                                'Delete property?',
                                                'ط­ط°ظپ ط§ظ„ط¹ظ‚ط§ط±طں',
                                              ),
                                              () => controller.removeProperty(
                                                property.id!,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        property.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        property.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(property.type),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _propertyDialog(),
                    icon: const Icon(Icons.add),
                    label: Text(trText('Add Property', 'ط¥ط¶ط§ظپط© ط¹ظ‚ط§ط±')),
                  ),
                ),
              ),
              const Divider(),
              if (controller.selectedProperty.value == null)
                Expanded(
                  child: Center(
                    child: Text(
                      trText(
                        'Select a property to manage its departments and units.',
                        'ط§ط®طھط± ط¹ظ‚ط§ط±ط§ظ‹ ظ„ط¥ط¯ط§ط±ط© ط£ظ‚ط³ط§ظ…ظ‡ ظˆظˆط­ط¯ط§طھظ‡.',
                      ),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          controller.selectedProperty.value!.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: trText('Departments', 'ط§ظ„ط£ظ‚ط³ط§ظ…')),
                    Tab(text: trText('Units', 'ط§ظ„ظˆط­ط¯ط§طھ')),
                  ],
                ),
                Expanded(
                  child: TabBarView(children: [_departmentList(), _unitList()]),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _departmentList() {
    return Obx(
      () => Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.icon(
                onPressed: () => _departmentDialog(),
                icon: const Icon(Icons.add),
                label: Text(trText('Add Department', 'ط¥ط¶ط§ظپط© ظ‚ط³ظ…')),
              ),
            ),
          ),
          Expanded(
            child: controller.departments.isEmpty
                ? Center(
                    child: Text(
                      trText('No departments', 'ظ„ط§ طھظˆط¬ط¯ ط£ظ‚ط³ط§ظ…'),
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.departments.length,
                    itemBuilder: (context, index) {
                      final item = controller.departments[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.layers_outlined),
                          title: Text(item.name),
                          subtitle: Text(item.description),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _departmentDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(
                                  trText(
                                    'Delete department?',
                                    'ط­ط°ظپ ط§ظ„ظ‚ط³ظ…طں',
                                  ),
                                  () => controller.removeDepartment(item.id!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _unitList() {
    return Obx(
      () => Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FilledButton.icon(
                onPressed: () => _unitDialog(),
                icon: const Icon(Icons.add),
                label: Text(trText('Add Unit', 'ط¥ط¶ط§ظپط© ظˆط­ط¯ط©')),
              ),
            ),
          ),
          Expanded(
            child: controller.units.isEmpty
                ? Center(
                    child: Text(trText('No units', 'ظ„ط§ طھظˆط¬ط¯ ظˆط­ط¯ط§طھ')),
                  )
                : ListView.builder(
                    itemCount: controller.units.length,
                    itemBuilder: (context, index) {
                      final item = controller.units[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.door_front_door_outlined),
                          title: Text(
                            '${trText('Unit', 'ظˆط­ط¯ط©')} ${item.number}',
                          ),
                          subtitle: Text(
                            '${item.type} â€¢ ${item.rent.toStringAsFixed(2)} â€¢ ${item.status}',
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _unitDialog(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(
                                  trText(
                                    'Delete unit?',
                                    'ط­ط°ظپ ط§ظ„ظˆط­ط¯ط©طں',
                                  ),
                                  () => controller.removeUnit(item.id!),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _propertyDialog([PropertyEntity? item]) {
    final name = TextEditingController(text: item?.name ?? '');
    final type = TextEditingController(text: item?.type ?? 'residential');
    final address = TextEditingController(text: item?.address ?? '');
    final description = TextEditingController(text: item?.description ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(
          trText(
            item == null ? 'New Property' : 'Edit Property',
            item == null ? 'ط¹ظ‚ط§ط± ط¬ط¯ظٹط¯' : 'طھط¹ط¯ظٹظ„ ط§ظ„ط¹ظ‚ط§ط±',
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(name, trText('Property name *', 'ط§ط³ظ… ط§ظ„ط¹ظ‚ط§ط± *')),
              _field(
                type,
                trText(
                  'Type (residential/commercial)',
                  'ط§ظ„ظ†ظˆط¹ (ط³ظƒظ†ظٹ/طھط¬ط§ط±ظٹ)',
                ),
              ),
              _field(address, trText('Address', 'ط§ظ„ط¹ظ†ظˆط§ظ†')),
              _field(description, trText('Description', 'ط§ظ„ظˆطµظپ')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(trText('Cancel', 'ط¥ظ„ط؛ط§ط،')),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Get.back();
              controller.saveProperty(
                PropertyEntity(
                  id: item?.id,
                  name: name.text.trim(),
                  type: type.text.trim(),
                  address: address.text.trim(),
                  description: description.text.trim(),
                ),
              );
            },
            child: Text(trText('Save', 'ط­ظپط¸')),
          ),
        ],
      ),
    );
  }

  void _departmentDialog([DepartmentEntity? item]) {
    final propertyId = controller.selectedProperty.value!.id!;
    final name = TextEditingController(text: item?.name ?? '');
    final description = TextEditingController(text: item?.description ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(trText('Department', 'ط§ظ„ظ‚ط³ظ…')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(name, trText('Department name *', 'ط§ط³ظ… ط§ظ„ظ‚ط³ظ… *')),
            _field(description, trText('Description', 'ط§ظ„ظˆطµظپ')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(trText('Cancel', 'ط¥ظ„ط؛ط§ط،')),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Get.back();
              controller.saveDepartment(
                DepartmentEntity(
                  id: item?.id,
                  propertyId: propertyId,
                  name: name.text.trim(),
                  description: description.text.trim(),
                ),
              );
            },
            child: Text(trText('Save', 'ط­ظپط¸')),
          ),
        ],
      ),
    );
  }

  void _unitDialog([UnitEntity? item]) {
    final propertyId = controller.selectedProperty.value!.id!;
    final number = TextEditingController(text: item?.number ?? '');
    final type = TextEditingController(text: item?.type ?? 'apartment');
    final floor = TextEditingController(text: '${item?.floor ?? 0}');
    final area = TextEditingController(text: '${item?.area ?? 0}');
    final rent = TextEditingController(text: '${item?.rent ?? 0}');
    final description = TextEditingController(text: item?.description ?? '');
    int? departmentId = item?.departmentId;
    String status = item?.status ?? 'available';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(trText('Unit details', 'ط¨ظٹط§ظ†ط§طھ ط§ظ„ظˆط­ط¯ط©')),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(
                    number,
                    trText('Unit number *', 'ط±ظ‚ظ… ط§ظ„ظˆط­ط¯ط© *'),
                  ),
                  _field(type, trText('Unit type', 'ظ†ظˆط¹ ط§ظ„ظˆط­ط¯ط©')),
                  _field(floor, trText('Floor', 'ط§ظ„ط·ط§ط¨ظ‚'), numeric: true),
                  _field(area, trText('Area', 'ط§ظ„ظ…ط³ط§ط­ط©'), numeric: true),
                  _field(
                    rent,
                    trText('Monthly rent', 'ط§ظ„ط¥ظٹط¬ط§ط± ط§ظ„ط´ظ‡ط±ظٹ'),
                    numeric: true,
                  ),
                  DropdownButtonFormField<int?>(
                    initialValue: departmentId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: trText(
                        'Department (optional)',
                        'ط§ظ„ظ‚ط³ظ… (ط§ط®طھظٹط§ط±ظٹ)',
                      ),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(trText('No department', 'ط¨ط¯ظˆظ† ظ‚ط³ظ…')),
                      ),
                      ...controller.departments.map(
                        (d) => DropdownMenuItem<int?>(
                          value: d.id,
                          child: Text(d.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => departmentId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: InputDecoration(
                      labelText: trText(
                        'Availability',
                        'ط­ط§ظ„ط© ط§ظ„ظˆط­ط¯ط©',
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'available',
                        child: Text(trText('Available', 'ظ…طھط§ط­ط©')),
                      ),
                      DropdownMenuItem(
                        value: 'occupied',
                        child: Text(trText('Occupied', 'ظ…ط´ط؛ظˆظ„ط©')),
                      ),
                      DropdownMenuItem(
                        value: 'maintenance',
                        child: Text(trText('Maintenance', 'طµظٹط§ظ†ط©')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => status = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(description, trText('Description', 'ط§ظ„ظˆطµظپ')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: Text(trText('Cancel', 'ط¥ظ„ط؛ط§ط،')),
              ),
              FilledButton(
                onPressed: () {
                  if (number.text.trim().isEmpty) return;
                  Get.back();
                  controller.saveUnit(
                    UnitEntity(
                      id: item?.id,
                      propertyId: propertyId,
                      departmentId: departmentId,
                      number: number.text.trim(),
                      type: type.text.trim(),
                      floor: int.tryParse(floor.text) ?? 0,
                      area: double.tryParse(area.text) ?? 0,
                      rent: double.tryParse(rent.text) ?? 0,
                      status: status,
                      description: description.text.trim(),
                    ),
                  );
                },
                child: Text(trText('Save', 'ط­ظپط¸')),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _confirmDelete(String title, VoidCallback action) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(
          trText(
            'This action cannot be undone.',
            'ظ„ط§ ظٹظ…ظƒظ† ط§ظ„طھط±ط§ط¬ط¹ ط¹ظ† ظ‡ط°ط§ ط§ظ„ط¥ط¬ط±ط§ط،.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(trText('Cancel', 'ط¥ظ„ط؛ط§ط،')),
          ),
          FilledButton(
            onPressed: () {
              Get.back();
              action();
            },
            child: Text(trText('Delete', 'ط­ط°ظپ')),
          ),
        ],
      ),
    );
  }
}
