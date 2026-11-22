import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/services_controller.dart';

class ServicesScreen extends GetView<ServicesController> {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('services_title'.tr),
          bottom: TabBar(
            tabs: [
              Tab(text: 'service_catalog'.tr),
              Tab(text: 'contract_services'.tr),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [_servicesTab(context), _assignmentsTab(context)],
          );
        }),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final index = DefaultTabController.of(context).index;

                if (index == 0) {
                  _showServiceDialog();
                } else {
                  _showAssignmentDialog();
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _servicesTab(BuildContext context) {
    if (controller.services.isEmpty) {
      return Center(child: Text('no_services'.tr));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.services.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.services[index];
        final isActive = item['is_active'] == 1;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                isActive
                    ? Icons.miscellaneous_services
                    : Icons.pause_circle_outline,
              ),
            ),
            title: Text('${item['name'] ?? ''}'),
            subtitle: Text(
              '${item['default_amount']} • '
              '${item['billing_period'] == 'monthly' ? 'monthly'.tr : 'one_time'.tr}\n'
              '${isActive ? 'active'.tr : 'inactive'.tr}\n'
              '${item['description'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showServiceDialog(item: item);
                } else if (value == 'deactivate') {
                  controller.deactivateService(item['id'] as int);
                } else if (value == 'activate') {
                  controller.activateService(item['id'] as int);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text('edit'.tr)),
                if (isActive)
                  PopupMenuItem(
                    value: 'deactivate',
                    child: Text('deactivate_service'.tr),
                  )
                else
                  PopupMenuItem(
                    value: 'activate',
                    child: Text('activate_service'.tr),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _assignmentsTab(BuildContext context) {
    if (controller.assignments.isEmpty) {
      return Center(child: Text('no_contract_services'.tr));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.assignments.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = controller.assignments[index];

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.link)),
            title: Text('${item['service_name'] ?? ''}'),
            subtitle: Text(
              '${item['contract_number']} • ${item['tenant_name']}\n'
              '${item['amount']}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'remove_assignment'.tr,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await Get.dialog<bool>(
                  AlertDialog(
                    title: Text('remove_assignment_title'.tr),
                    content: Text('remove_assignment_message'.tr),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(result: false),
                        child: Text('cancel'.tr),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true),
                        child: Text('confirm'.tr),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                final removed = await controller.removeAssignment(
                  item['id'] as int,
                );

                if (removed) {
                  Get.snackbar('success'.tr, 'assignment_removed'.tr);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showServiceDialog({Map<String, Object?>? item}) async {
    await Get.dialog<void>(
      _ServiceFormDialog(controller: controller, item: item),
    );
  }

  Future<void> _showAssignmentDialog() async {
    if (controller.contracts.isEmpty || controller.services.isEmpty) {
      Get.snackbar('notice'.tr, 'add_contract_service_first'.tr);
      return;
    }

    final availableServices = controller.services
        .where((item) => item['is_active'] == 1)
        .toList();

    if (availableServices.isEmpty) {
      Get.snackbar('notice'.tr, 'no_active_services'.tr);
      return;
    }

    await Get.dialog<void>(
      _ServiceAssignmentDialog(
        controller: controller,
        contracts: controller.contracts.toList(),
        services: availableServices,
      ),
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  const _ServiceFormDialog({required this.controller, this.item});

  final ServicesController controller;
  final Map<String, Object?>? item;

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;

  late String _period;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _nameController = TextEditingController(text: '${item?['name'] ?? ''}');

    _descriptionController = TextEditingController(
      text: '${item?['description'] ?? ''}',
    );

    _amountController = TextEditingController(
      text: '${item?['default_amount'] ?? ''}',
    );

    _period = '${item?['billing_period'] ?? 'monthly'}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_amountController.text.trim());

    if (_nameController.text.trim().isEmpty ||
        value == null ||
        !value.isFinite ||
        value < 0) {
      Get.snackbar('notice'.tr, 'valid_name_amount'.tr);
      return;
    }

    final saved = await widget.controller.saveService(
      id: widget.item?['id'] as int?,
      name: _nameController.text,
      description: _descriptionController.text,
      amount: value,
      billingPeriod: _period,
    );

    if (!mounted) return;

    if (saved) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('service_details'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'service_name'.tr),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'description'.tr),
            ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: 'default_amount'.tr),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: InputDecoration(labelText: 'billing_period'.tr),
              items: [
                DropdownMenuItem(value: 'monthly', child: Text('monthly'.tr)),
                DropdownMenuItem(value: 'one_time', child: Text('one_time'.tr)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _period = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        FilledButton(onPressed: _save, child: Text('save'.tr)),
      ],
    );
  }
}

class _ServiceAssignmentDialog extends StatefulWidget {
  const _ServiceAssignmentDialog({
    required this.controller,
    required this.contracts,
    required this.services,
  });

  final ServicesController controller;
  final List<Map<String, Object?>> contracts;
  final List<Map<String, Object?>> services;

  @override
  State<_ServiceAssignmentDialog> createState() =>
      _ServiceAssignmentDialogState();
}

class _ServiceAssignmentDialogState extends State<_ServiceAssignmentDialog> {
  late int _contractId;
  late int _serviceId;
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();

    _contractId = widget.contracts.first['id'] as int;
    _serviceId = widget.services.first['id'] as int;

    _amountController = TextEditingController(
      text: '${widget.services.first['default_amount'] ?? 0}',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _assign() async {
    final value = double.tryParse(_amountController.text.trim());

    if (value == null || !value.isFinite || value < 0) {
      Get.snackbar('notice'.tr, 'valid_amount'.tr);
      return;
    }

    final saved = await widget.controller.assignService(
      contractId: _contractId,
      serviceId: _serviceId,
      amount: value,
    );

    if (!mounted) return;

    if (saved) {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('assign_service_title'.tr),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _contractId,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'contract'.tr),
              items: widget.contracts.map((item) {
                return DropdownMenuItem(
                  value: item['id'] as int,
                  child: Text(
                    '${item['contract_number']} - ${item['tenant_name']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _contractId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _serviceId,
              isExpanded: true,
              decoration: InputDecoration(labelText: 'service'.tr),
              items: widget.services.map((item) {
                return DropdownMenuItem(
                  value: item['id'] as int,
                  child: Text('${item['name']}'),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                final selected = widget.services.firstWhere(
                  (item) => item['id'] == value,
                );

                setState(() {
                  _serviceId = value;
                  _amountController.text = '${selected['default_amount'] ?? 0}';
                });
              },
            ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'contract_service_amount'.tr,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
        FilledButton(onPressed: _assign, child: Text('assign_service'.tr)),
      ],
    );
  }
}
