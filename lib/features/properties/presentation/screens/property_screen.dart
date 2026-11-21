import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/property_entities.dart';
import '../controllers/property_controller.dart';

class PropertyScreen extends GetView<PropertyController> {
  const PropertyScreen({super.key});

  String _t(String key) => key.tr;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  String _message(String en, String ar) => _isArabic ? ar : en;

  String _translatedValue(String value) {
    final key = value.toLowerCase().trim();
    const keys = {
      'residential',
      'commercial',
      'apartment',
      'shop',
      'office',
      'villa',
      'other',
      'available',
      'occupied',
      'rented',
      'maintenance',
      'unavailable',
    };
    return keys.contains(key) ? key.tr : value;
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return _message('$field is required.', 'مطلوب.');
    }
    return null;
  }

  String? _positiveNumber(
    String? value,
    String field, {
    bool allowZero = false,
  }) {
    final number = double.tryParse((value ?? '').trim());
    if (number == null ||
        !number.isFinite ||
        (allowZero ? number < 0 : number <= 0)) {
      return allowZero
          ? _message(
              '$field must be zero or greater.',
              '$field يجب أن يكون صفراً أو أكبر.',
            )
          : _message(
              '$field must be greater than zero.',
              '$field يجب أن يكون أكبر من صفر.',
            );
    }
    return null;
  }

  String? _floorValidator(String? value) {
    final floor = int.tryParse((value ?? '').trim());
    if (floor == null || floor < 0) {
      return _message(
        'Enter a valid floor number (0 or greater).',
        'أدخل رقم طابق صحيحاً (0 أو أكبر).',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(_t('properties_title'))),
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
                    hintText: _t('search_properties'),
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(
                height: 150,
                child: controller.filteredProperties.isEmpty
                    ? Center(child: Text(_t('no_properties')))
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: controller.filteredProperties.length,
                        itemBuilder: (context, index) {
                          final property = controller.filteredProperties[index];
                          final selected =
                              property.id != null &&
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
                                            tooltip: _t('edit'),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                _propertyDialog(property),
                                          ),
                                          IconButton(
                                            visualDensity:
                                                VisualDensity.compact,
                                            tooltip: _t('delete'),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: property.id == null
                                                ? null
                                                : () => _confirmDelete(
                                                    _t('delete_property_title'),
                                                    () => controller
                                                        .removeProperty(
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
                                      Text(_translatedValue(property.type)),
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
                    label: Text(_t('add_property')),
                  ),
                ),
              ),
              const Divider(),
              if (controller.selectedProperty.value == null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _t('select_property_message'),
                        textAlign: TextAlign.center,
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
                    Tab(text: _t('departments')),
                    Tab(text: _t('units')),
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
                label: Text(_t('add_department')),
              ),
            ),
          ),
          Expanded(
            child: controller.departments.isEmpty
                ? Center(child: Text(_t('no_departments')))
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
                                tooltip: _t('edit'),
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _departmentDialog(item),
                              ),
                              IconButton(
                                tooltip: _t('delete'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: item.id == null
                                    ? null
                                    : () => _confirmDelete(
                                        _t('delete_department_title'),
                                        () => controller.removeDepartment(
                                          item.id!,
                                        ),
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
                label: Text(_t('add_unit')),
              ),
            ),
          ),
          Expanded(
            child: controller.units.isEmpty
                ? Center(child: Text(_t('no_units')))
                : ListView.builder(
                    itemCount: controller.units.length,
                    itemBuilder: (context, index) {
                      final item = controller.units[index];
                      return Card(
                        child: ListTile(
                          onTap: () => _showUnitDetails(item),
                          leading: const Icon(Icons.door_front_door_outlined),
                          title: Text('${_t('unit')} ${item.number}'),
                          subtitle: Text(
                            '${_translatedValue(item.type)}  _  '
                            '${item.rent.toStringAsFixed(2)}  _  '
                            '${_translatedValue(item.status)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            children: [
                              IconButton(
                                tooltip: _t('edit'),
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _unitDialog(item),
                              ),
                              IconButton(
                                tooltip: _t('delete'),
                                icon: const Icon(Icons.delete_outline),
                                onPressed: item.id == null
                                    ? null
                                    : () => _confirmDelete(
                                        _t('delete_unit_title'),
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

  void _showUnitDetails(UnitEntity item) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_t('unit')} ${item.number}',
                  style: Get.textTheme.titleLarge,
                ),
                const Divider(),
                _detailRow(_t('unit_type'), _translatedValue(item.type)),
                _detailRow(_t('floor'), item.floor.toString()),
                _detailRow(_t('area'), item.area.toString()),
                _detailRow(_t('monthly_rent'), item.rent.toStringAsFixed(2)),
                _detailRow(_t('availability'), _translatedValue(item.status)),
                _detailRow(_t('description'), item.description),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Get.back();
                      _unitDialog(item);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(_t('edit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Get.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 3, child: Text(value.isEmpty ? '_' : value)),
        ],
      ),
    );
  }

  Future<void> _propertyDialog([PropertyEntity? item]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: item?.name ?? '');
    final address = TextEditingController(text: item?.address ?? '');
    final description = TextEditingController(text: item?.description ?? '');
    String type = item?.type ?? 'residential';

    try {
      await Get.dialog<void>(
        StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              item == null ? _t('new_property') : _t('edit_property'),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(
                      name,
                      _t('property_name_required'),
                      validator: (v) =>
                          _required(v, _t('property_name_required')),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('property_type_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      items: ['residential', 'commercial', 'other']
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(_translatedValue(v)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _formField(address, 'address'.tr),
                    _formField(description, _t('description')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(_t('cancel'))),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final saved = await controller.saveProperty(
                    PropertyEntity(
                      id: item?.id,
                      name: name.text.trim(),
                      type: type,
                      address: address.text.trim(),
                      description: description.text.trim(),
                    ),
                  );
                  if (saved) Get.back();
                },
                child: Text(_t('save')),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      name.dispose();
      address.dispose();
      description.dispose();
    }
  }

  Future<void> _departmentDialog([DepartmentEntity? item]) async {
    final selected = controller.selectedProperty.value;
    if (selected?.id == null) return;

    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: item?.name ?? '');
    final description = TextEditingController(text: item?.description ?? '');

    try {
      await Get.dialog<void>(
        AlertDialog(
          title: Text(_t('department')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _formField(
                    name,
                    _t('department_name_required'),
                    validator: (v) =>
                        _required(v, _t('department_name_required')),
                  ),
                  _formField(description, _t('description')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: Get.back, child: Text(_t('cancel'))),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final saved = await controller.saveDepartment(
                  DepartmentEntity(
                    id: item?.id,
                    propertyId: selected!.id!,
                    name: name.text.trim(),
                    description: description.text.trim(),
                  ),
                );
                if (saved) Get.back();
              },
              child: Text(_t('save')),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } finally {
      name.dispose();
      description.dispose();
    }
  }

  Future<void> _unitDialog([UnitEntity? item]) async {
    final selected = controller.selectedProperty.value;
    if (selected?.id == null) return;

    final formKey = GlobalKey<FormState>();
    final number = TextEditingController(text: item?.number ?? '');
    final floor = TextEditingController(text: '${item?.floor ?? 0}');
    final area = TextEditingController(text: '${item?.area ?? ''}');
    final rent = TextEditingController(text: '${item?.rent ?? ''}');
    final description = TextEditingController(text: item?.description ?? '');

    int? departmentId = item?.departmentId;
    String type = item?.type ?? 'apartment';
    String status = item?.status ?? 'available';

    const unitTypes = ['apartment', 'shop', 'office', 'villa', 'other'];
    const statuses = ['available', 'occupied', 'maintenance'];

    if (!unitTypes.contains(type)) type = 'other';
    if (!statuses.contains(status)) status = 'available';

    try {
      await Get.dialog<void>(
        StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(_t('unit_details')),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _formField(
                      number,
                      _t('unit_number_required'),
                      validator: (v) =>
                          _required(v, _t('unit_number_required')),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('unit_type'),
                        border: const OutlineInputBorder(),
                      ),
                      items: unitTypes
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(_translatedValue(v)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _formField(
                      floor,
                      _t('floor'),
                      numeric: true,
                      validator: _floorValidator,
                    ),
                    _formField(
                      area,
                      _t('area'),
                      numeric: true,
                      validator: (v) => _positiveNumber(v, _t('area')),
                    ),
                    _formField(
                      rent,
                      _t('monthly_rent'),
                      numeric: true,
                      validator: (v) => _positiveNumber(
                        v,
                        _t('monthly_rent'),
                        allowZero: true,
                      ),
                    ),
                    DropdownButtonFormField<int?>(
                      initialValue: departmentId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('department_optional'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(_t('no_department')),
                        ),
                        ...controller.departments
                            .where((d) => d.id != null)
                            .map(
                              (d) => DropdownMenuItem<int?>(
                                value: d.id,
                                child: Text(d.name),
                              ),
                            ),
                      ],
                      onChanged: (v) => setState(() => departmentId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('availability'),
                        border: const OutlineInputBorder(),
                      ),
                      items: statuses
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(_translatedValue(v)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => status = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    _formField(description, _t('description')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: Get.back, child: Text(_t('cancel'))),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final floorValue = int.parse(floor.text.trim());
                  final areaValue = double.parse(area.text.trim());
                  final rentValue = double.parse(rent.text.trim());

                  final saved = await controller.saveUnit(
                    UnitEntity(
                      id: item?.id,
                      propertyId: selected!.id!,
                      departmentId: departmentId,
                      number: number.text.trim(),
                      type: type,
                      floor: floorValue,
                      area: areaValue,
                      rent: rentValue,
                      status: status,
                      description: description.text.trim(),
                    ),
                  );
                  if (saved) Get.back();
                },
                child: Text(_t('save')),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      number.dispose();
      floor.dispose();
      area.dispose();
      rent.dispose();
      description.dispose();
    }
  }

  Widget _formField(
    TextEditingController textController,
    String label, {
    bool numeric = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: textController,
        validator: validator,
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

  Future<void> _confirmDelete(
    String title,
    Future<void> Function() action,
  ) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(title),
        content: Text(_t('this_action_cannot_be_undone')),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(_t('cancel')),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text(_t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) await action();
  }
}
