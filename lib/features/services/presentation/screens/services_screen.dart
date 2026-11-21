
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
            children: [
              _servicesTab(context),
              _assignmentsTab(context),
            ],
          );
        }),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                final index = DefaultTabController.of(context).index;

                if (index == 0) {
                  _showServiceDialog(context);
                } else {
                  _showAssignmentDialog(context);
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
    final active = controller.services
        .where((item) => item['is_active'] == 1)
        .toList();

    if (active.isEmpty) {
      return Center(child: Text('no_services'.tr));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = active[index];

        return Card(
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.miscellaneous_services),
            ),
            title: Text('${item['name'] ?? ''}'),
            subtitle: Text(
              '${item['default_amount']} • '
              '${item['billing_period'] == 'monthly' ? 'monthly'.tr : 'one_time'.tr}\n'
              '${item['description'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showServiceDialog(context, item: item);
                }

                if (value == 'deactivate') {
                  controller.deactivateService(item['id'] as int);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('edit'.tr),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Text('deactivate_service'.tr),
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
            leading: const CircleAvatar(
              child: Icon(Icons.link),
            ),
            title: Text('${item['service_name'] ?? ''}'),
            subtitle: Text(
              '${item['contract_number']} • ${item['tenant_name']}\n'
              '${item['amount']}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'remove_assignment'.tr,
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                controller.removeAssignment(item['id'] as int);
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _showServiceDialog(
    BuildContext context, {
    Map<String, Object?>? item,
  }) async {
    final name = TextEditingController(
      text: '${item?['name'] ?? ''}',
    );

    final description = TextEditingController(
      text: '${item?['description'] ?? ''}',
    );

    final amount = TextEditingController(
      text: '${item?['default_amount'] ?? ''}',
    );

    String period = '${item?['billing_period'] ?? 'monthly'}';

    await Get.dialog(
      AlertDialog(
        title: Text('service_details'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(
                  labelText: 'service_name'.tr,
                ),
              ),
              TextField(
                controller: description,
                decoration: InputDecoration(
                  labelText: 'description'.tr,
                ),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'default_amount'.tr,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: period,
                decoration: InputDecoration(
                  labelText: 'billing_period'.tr,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('monthly'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'one_time',
                    child: Text('one_time'.tr),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) period = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text.trim());

              if (name.text.trim().isEmpty ||
                  value == null ||
                  !value.isFinite ||
                  value < 0) {
                Get.snackbar(
                  'notice'.tr,
                  'valid_name_amount'.tr,
                );
                return;
              }

              final saved = await controller.saveService(
                id: item?['id'] as int?,
                name: name.text,
                description: description.text,
                amount: value,
                billingPeriod: period,
              );

              if (saved) Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );

    name.dispose();
    description.dispose();
    amount.dispose();
  }

  Future<void> _showAssignmentDialog(BuildContext context) async {
    if (controller.contracts.isEmpty || controller.services.isEmpty) {
      Get.snackbar(
        'notice'.tr,
        'add_contract_service_first'.tr,
      );
      return;
    }

    final availableServices = controller.services
        .where((item) => item['is_active'] == 1)
        .toList();

    if (availableServices.isEmpty) {
      Get.snackbar(
        'notice'.tr,
        'no_active_services'.tr,
      );
      return;
    }

    int contractId = controller.contracts.first['id'] as int;
    int serviceId = availableServices.first['id'] as int;

    final amount = TextEditingController(
      text: '${availableServices.first['default_amount'] ?? 0}',
    );

    await Get.dialog(
      AlertDialog(
        title: Text('assign_service_title'.tr),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: contractId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'contract'.tr,
                    ),
                    items: controller.contracts.map((item) {
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
                        setState(() => contractId = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: serviceId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'service'.tr,
                    ),
                    items: availableServices.map((item) {
                      return DropdownMenuItem(
                        value: item['id'] as int,
                        child: Text('${item['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          serviceId = value;

                          final selected = availableServices.firstWhere(
                            (item) => item['id'] == value,
                          );

                          amount.text =
                              '${selected['default_amount'] ?? 0}';
                        });
                      }
                    },
                  ),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'contract_service_amount'.tr,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text.trim());

              if (value == null || !value.isFinite || value < 0) {
                Get.snackbar(
                  'notice'.tr,
                  'valid_amount'.tr,
                );
                return;
              }

              final saved = await controller.assignService(
                contractId: contractId,
                serviceId: serviceId,
                amount: value,
              );

              if (saved) Get.back();
            },
            child: Text('assign_service'.tr),
          ),
        ],
      ),
    );

    amount.dispose();
  }
}
