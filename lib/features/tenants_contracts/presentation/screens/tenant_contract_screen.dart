import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tenant_entities.dart';
import '../controllers/tenant_contract_controller.dart';

class TenantContractScreen extends GetView<TenantContractController> {
  const TenantContractScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tenants & Contracts'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Tenants'),
              Tab(
                icon: Icon(Icons.description_outlined),
                text: 'Contracts',
              ),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value &&
              controller.tenants.isEmpty &&
              controller.contracts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _buildTenants(context),
              _buildContracts(context),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildTenants(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: controller.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search tenants by name, phone or ID',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final items = controller.filteredTenants;

            if (items.isEmpty) {
              return const Center(
                child: Text('No tenants yet. Add your first tenant.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final tenant = items[index];
                final count = controller.contracts
                    .where((c) => c.tenantId == tenant.id)
                    .length;

                return Card(
                  key: ValueKey('tenant_${tenant.id}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.fullName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tenant.phone.isEmpty ? 'No phone' : tenant.phone} • $count contract(s)',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Tenant options',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _tenantDialog(context, tenant: tenant);
                            } else if (value == 'delete') {
                              _confirmDeleteTenant(context, tenant);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _tenantDialog(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Tenant'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContracts(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final items = controller.contracts;

            if (items.isEmpty) {
              return const Center(
                child: Text('No contracts yet. Create your first contract.'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final contract = items[index];

                return Card(
                  key: ValueKey('contract_${contract.id}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.description_outlined),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contract.contractNumber,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(contract.tenantName),
                              Text(contract.unitLabel),
                              Text(
                                '${contract.startDate} → ${contract.endDate}',
                              ),
                              Text(
                                'Rent: ${contract.monthlyRent.toStringAsFixed(2)}',
                              ),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(
                                  _capitalize(contract.status),
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Contract options',
                          onSelected: (value) {
                            if (value == 'edit') {
                              _contractDialog(context, contract: contract);
                            } else if (value == 'terminate') {
                              _confirmContractStatus(
                                context,
                                contract,
                                'terminated',
                              );
                            } else if (value == 'archive') {
                              _confirmContractStatus(
                                context,
                                contract,
                                'archived',
                              );
                            }
                          },
                          itemBuilder: (_) => [
                            if (contract.status == 'active')
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                            if (contract.status == 'active')
                              const PopupMenuItem(
                                value: 'terminate',
                                child: Text('Terminate'),
                              ),
                            if (contract.status != 'archived')
                              const PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _contractDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Contract'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _tenantDialog(
    BuildContext context, {
    TenantEntity? tenant,
  }) async {
    final name = TextEditingController(text: tenant?.fullName ?? '');
    final phone = TextEditingController(text: tenant?.phone ?? '');
    final email = TextEditingController(text: tenant?.email ?? '');
    final nationalId = TextEditingController(text: tenant?.nationalId ?? '');
    final address = TextEditingController(text: tenant?.address ?? '');
    final notes = TextEditingController(text: tenant?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          var isSaving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(tenant == null ? 'Add Tenant' : 'Edit Tenant'),
                content: SizedBox(
                  width: 440,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: name,
                            decoration: const InputDecoration(
                              labelText: 'Full name *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          TextFormField(
                            controller: email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          TextFormField(
                            controller: nationalId,
                            decoration: const InputDecoration(
                              labelText: 'National ID',
                            ),
                          ),
                          TextFormField(
                            controller: address,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                            ),
                          ),
                          TextFormField(
                            controller: notes,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            setDialogState(() => isSaving = true);

                            final saved = await controller.saveTenant(
                              TenantEntity(
                                id: tenant?.id,
                                fullName: name.text.trim(),
                                phone: phone.text.trim(),
                                email: email.text.trim(),
                                nationalId: nationalId.text.trim(),
                                address: address.text.trim(),
                                notes: notes.text.trim(),
                              ),
                            );

                            if (saved && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            } else if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      name.dispose();
      phone.dispose();
      email.dispose();
      nationalId.dispose();
      address.dispose();
      notes.dispose();
    }
  }

  Future<void> _contractDialog(
    BuildContext context, {
    ContractEntity? contract,
  }) async {
    if (controller.tenants.isEmpty) {
      Get.snackbar('Cannot create contract', 'Please add a tenant first.');
      return;
    }

    if (controller.units.isEmpty) {
      Get.snackbar(
        'Cannot create contract',
        'Please add a property and unit first.',
      );
      return;
    }

    final tenantIds = controller.tenants.map((t) => t.id).toSet();
    final unitIds = controller.units.map((u) => u.id).toSet();

    int tenantId = contract?.tenantId ?? controller.tenants.first.id!;
    int unitId = contract?.unitId ?? controller.units.first.id;

    if (!tenantIds.contains(tenantId)) {
      tenantId = controller.tenants.first.id!;
    }

    if (!unitIds.contains(unitId)) {
      unitId = controller.units.first.id;
    }

    DateTime startDate =
        DateTime.tryParse(contract?.startDate ?? '') ?? DateTime.now();

    DateTime endDate =
        DateTime.tryParse(contract?.endDate ?? '') ??
        DateTime.now().add(const Duration(days: 365));

    final rent = TextEditingController(
      text: (contract?.monthlyRent ??
              controller.units.firstWhere((u) => u.id == unitId).monthlyRent)
          .toString(),
    );

    final deposit = TextEditingController(
      text: (contract?.depositAmount ?? 0).toString(),
    );

    final notes = TextEditingController(text: contract?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    String dateText(DateTime date) {
      return '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          var isSaving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  contract == null ? 'Create Contract' : 'Edit Contract',
                ),
                content: SizedBox(
                  width: 460,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: tenantId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Tenant',
                            ),
                            items: controller.tenants.map((tenant) {
                              return DropdownMenuItem<int>(
                                value: tenant.id,
                                child: Text(
                                  tenant.fullName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setDialogState(() => tenantId = value);
                                    }
                                  },
                          ),
                          DropdownButtonFormField<int>(
                            initialValue: unitId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                            items: controller.units.map((unit) {
                              return DropdownMenuItem<int>(
                                value: unit.id,
                                child: Text(
                                  '${unit.label} (${unit.status})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) return;

                                    setDialogState(() {
                                      unitId = value;

                                      if (contract == null) {
                                        rent.text = controller.units
                                            .firstWhere((u) => u.id == value)
                                            .monthlyRent
                                            .toString();
                                      }
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          _dateSelector(
                            context: context,
                            title: 'Start date',
                            date: startDate,
                            enabled: !isSaving,
                            onSelected: (value) {
                              setDialogState(() {
                                startDate = value;

                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            },
                          ),
                          _dateSelector(
                            context: context,
                            title: 'End date',
                            date: endDate,
                            enabled: !isSaving,
                            firstDate: startDate,
                            onSelected: (value) {
                              setDialogState(() => endDate = value);
                            },
                          ),
                          TextFormField(
                            controller: rent,
                            decoration: const InputDecoration(
                              labelText: 'Monthly rent',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final amount = double.tryParse(value ?? '');

                              if (amount == null) {
                                return 'Enter a valid rent';
                              }

                              if (amount < 0) {
                                return 'Rent cannot be negative';
                              }

                              return null;
                            },
                          ),
                          TextFormField(
                            controller: deposit,
                            decoration: const InputDecoration(
                              labelText: 'Deposit amount',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final amount = double.tryParse(value ?? '');

                              if (amount == null) {
                                return 'Enter a valid deposit';
                              }

                              if (amount < 0) {
                                return 'Deposit cannot be negative';
                              }

                              return null;
                            },
                          ),
                          TextFormField(
                            controller: notes,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                            ),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;

                            if (endDate.isBefore(startDate)) {
                              Get.snackbar(
                                'Invalid dates',
                                'End date must not be before start date.',
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);

                            final selectedTenant = controller.tenants
                                .firstWhere((t) => t.id == tenantId);

                            final selectedUnit = controller.units
                                .firstWhere((u) => u.id == unitId);

                            final saved = await controller.saveContract(
                              ContractEntity(
                                id: contract?.id,
                                contractNumber:
                                    contract?.contractNumber ?? '',
                                tenantId: tenantId,
                                tenantName: selectedTenant.fullName,
                                unitId: unitId,
                                unitLabel: selectedUnit.label,
                                startDate: dateText(startDate),
                                endDate: dateText(endDate),
                                monthlyRent: double.parse(rent.text),
                                depositAmount: double.parse(deposit.text),
                                status: contract?.status ?? 'active',
                                notes: notes.text.trim(),
                              ),
                            );

                            if (saved && dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            } else if (dialogContext.mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      rent.dispose();
      deposit.dispose();
      notes.dispose();
    }
  }

  Widget _dateSelector({
    required BuildContext context,
    required String title,
    required DateTime date,
    required bool enabled,
    required ValueChanged<DateTime> onSelected,
    DateTime? firstDate,
  }) {
    final formatted =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: firstDate ?? DateTime(2000),
                lastDate: DateTime(2100),
              );

              if (selected != null) {
                onSelected(selected);
              }
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(formatted),
                ],
              ),
            ),
            const Icon(Icons.calendar_month),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTenant(
    BuildContext context,
    TenantEntity tenant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete tenant?'),
        content: Text(
          'Delete ${tenant.fullName}? Tenants with contract history cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && tenant.id != null) {
      await controller.deleteTenant(tenant.id!);
    }
  }

  Future<void> _confirmContractStatus(
    BuildContext context,
    ContractEntity contract,
    String status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_capitalize(status)} contract?'),
        content: Text(
          'Are you sure you want to $status ${contract.contractNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(_capitalize(status)),
          ),
        ],
      ),
    );

    if (confirmed == true && contract.id != null) {
      await controller.changeStatus(contract.id!, status);
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}