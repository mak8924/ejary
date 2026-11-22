import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/entities/tenant_entities.dart';
import '../controllers/tenant_contract_controller.dart';
import '../../../../routes/app_routes.dart';

class TenantContractScreen extends GetView<TenantContractController> {
  const TenantContractScreen({super.key});

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  String _local(String ar, String en) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('tenants_contracts_title'.tr),
          actions: [
            IconButton(
              tooltip: 'dues_payments_title'.tr,
              icon: const Icon(Icons.payments_outlined),
              onPressed: () => Get.toNamed(AppRoutes.duesPayments),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.people_outline),
                text: 'tenants_tab'.tr,
              ),
              Tab(
                icon: const Icon(Icons.description_outlined),
                text: 'contracts_tab'.tr,
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
            children: [_buildTenants(context), _buildContracts(context)],
          );
        }),
      ),
    );
  }

  // TENANTS

  Widget _buildTenants(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: controller.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'search_tenants'.tr,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final items = controller.filteredTenants;

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('no_tenants'.tr, textAlign: TextAlign.center),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final tenant = items[index];
                final count = controller.contracts
                    .where((contract) => contract.tenantId == tenant.id)
                    .length;

                return Card(
                  key: ValueKey('tenant_${tenant.id}'),
                  margin: const EdgeInsets.only(bottom: 10),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showTenantDetails(context, tenant, count),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tenant.fullName,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tenant.phone.isEmpty ? 'no_phone'.tr : tenant.phone} • '
                                  '${'contract_count'.trParams({'count': count.toString()})}',
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'tenant_options'.tr,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _tenantDialog(context, tenant: tenant);
                              } else if (value == 'delete') {
                                _confirmDeleteTenant(context, tenant);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('edit'.tr),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('delete'.tr),
                              ),
                            ],
                          ),
                        ],
                      ),
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
              label: Text('add_tenant'.tr),
            ),
          ),
        ),
      ],
    );
  }

  void _showTenantDetails(
    BuildContext context,
    TenantEntity tenant,
    int contractCount,
  ) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tenant.fullName, style: Get.textTheme.titleLarge),
                const Divider(),
                _detailRow(_local('الهاتف', 'Phone'), _display(tenant.phone)),
                _detailRow(
                  _local('البريد الإلكتروني', 'Email'),
                  _display(tenant.email),
                ),
                _detailRow(
                  _local('رقم الهوية', 'National ID'),
                  _display(tenant.nationalId),
                ),
                _detailRow(
                  _local('العنوان', 'Address'),
                  _display(tenant.address),
                ),
                _detailRow(
                  _local('عدد العقود', 'Contracts'),
                  contractCount.toString(),
                ),
                _detailRow(_local('ملاحظات', 'Notes'), _display(tenant.notes)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Get.back();
                      _tenantDialog(context, tenant: tenant);
                    },
                    icon: const Icon(Icons.edit),
                    label: Text('edit'.tr),
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

  // CONTRACTS

  Widget _buildContracts(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            final items = controller.contracts;

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('no_contracts'.tr, textAlign: TextAlign.center),
                ),
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
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _showContractDetails(context, contract),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(contract.tenantName),
                                Text(contract.unitLabel),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Chip(
                                      label: Text(
                                        _translatedStatus(contract.status),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    Text(
                                      'rent_label'.trParams({
                                        'amount': contract.monthlyRent
                                            .toStringAsFixed(2),
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'contract_options'.tr,
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
                              } else if (value == 'restore') {
                                _confirmContractStatus(
                                  context,
                                  contract,
                                  'active',
                                );
                              }
                            },
                            itemBuilder: (_) => [
                              if (contract.status == 'active') ...[
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('edit'.tr),
                                ),
                                PopupMenuItem(
                                  value: 'terminate',
                                  child: Text('terminate'.tr),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text('archive'.tr),
                                ),
                              ],
                              if (contract.status == 'terminated')
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text('archive'.tr),
                                ),
                              if (contract.status == 'terminated' ||
                                  contract.status == 'archived')
                                PopupMenuItem(
                                  value: 'restore',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.restore, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        _local(
                                          'استعادة العقد',
                                          'Restore contract',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
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
              label: Text('create_contract'.tr),
            ),
          ),
        ),
      ],
    );
  }

  void _showContractDetails(BuildContext context, ContractEntity contract) {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contract.contractNumber, style: Get.textTheme.titleLarge),
                const Divider(),
                _detailRow(_local('المستأجر', 'Tenant'), contract.tenantName),
                _detailRow(_local('الوحدة', 'Unit'), contract.unitLabel),
                _detailRow(
                  _local('تاريخ البداية', 'Start date'),
                  contract.startDate,
                ),
                _detailRow(
                  _local('تاريخ النهاية', 'End date'),
                  contract.endDate,
                ),
                _detailRow(
                  _local('الإيجار الشهري', 'Monthly rent'),
                  contract.monthlyRent.toStringAsFixed(2),
                ),
                _detailRow(
                  _local('مبلغ التأمين', 'Deposit'),
                  contract.depositAmount.toStringAsFixed(2),
                ),
                _detailRow(
                  _local('الحالة', 'Status'),
                  _translatedStatus(contract.status),
                ),
                _detailRow(
                  _local('ملاحظات', 'Notes'),
                  _display(contract.notes),
                ),
                if (contract.status == 'active') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Get.back();
                        _contractDialog(context, contract: contract);
                      },
                      icon: const Icon(Icons.edit),
                      label: Text('edit'.tr),
                    ),
                  ),
                ],
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
          Expanded(flex: 3, child: SelectableText(value.isEmpty ? '—' : value)),
        ],
      ),
    );
  }

  String _display(String value) =>
      value.trim().isEmpty ? _local('غير محدد', 'Not provided') : value.trim();

  // ADD / EDIT TENANT

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
            builder: (context, setDialogState) => AlertDialog(
              title: Text(tenant == null ? 'add_tenant'.tr : 'edit_tenant'.tr),
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
                          decoration: InputDecoration(
                            labelText: 'full_name_required'.tr,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'name_required'.tr;
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: phone,
                          decoration: InputDecoration(labelText: 'phone'.tr),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return null;
                            final digits = input.replaceAll(
                              RegExp(r'[\s()+\-]'),
                              '',
                            );
                            if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
                              return _local(
                                'أدخل رقم هاتف صحيحًا من 7 إلى 15 رقمًا',
                                'Enter a valid phone number (7–15 digits)',
                              );
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: email,
                          decoration: InputDecoration(labelText: 'email'.tr),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final input = value?.trim() ?? '';
                            if (input.isEmpty) return null;
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(input)) {
                              return _local(
                                'أدخل بريدًا إلكترونيًا صحيحًا',
                                'Enter a valid email address',
                              );
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: nationalId,
                          decoration: InputDecoration(
                            labelText: 'national_id'.tr,
                          ),
                        ),
                        TextFormField(
                          controller: address,
                          decoration: InputDecoration(labelText: 'address'.tr),
                        ),
                        TextFormField(
                          controller: notes,
                          decoration: InputDecoration(labelText: 'notes'.tr),
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
                  child: Text('cancel'.tr),
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ],
            ),
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

  // ADD / EDIT CONTRACT

  Future<void> _contractDialog(
    BuildContext context, {
    ContractEntity? contract,
  }) async {
    if (controller.tenants.isEmpty) {
      Get.snackbar('cannot_create_contract'.tr, 'add_tenant_first'.tr);
      return;
    }
    if (controller.units.isEmpty) {
      Get.snackbar('cannot_create_contract'.tr, 'add_property_unit_first'.tr);
      return;
    }

    final tenants = controller.tenants.toList();
    final units = controller.units.toList();

    final tenantIds = tenants.map((t) => t.id).whereType<int>().toSet();
    final unitIds = units.map((u) => u.id).toSet();

    if (tenantIds.isEmpty || unitIds.isEmpty) {
      Get.snackbar('cannot_create_contract'.tr, 'add_property_unit_first'.tr);
      return;
    }

    int tenantId = contract?.tenantId ?? tenantIds.first;
    int unitId = contract?.unitId ?? unitIds.first;

    if (!tenantIds.contains(tenantId)) tenantId = tenantIds.first;
    if (!unitIds.contains(unitId)) unitId = unitIds.first;

    DateTime startDate =
        DateTime.tryParse(contract?.startDate ?? '') ?? DateTime.now();
    DateTime endDate =
        DateTime.tryParse(contract?.endDate ?? '') ??
        startDate.add(const Duration(days: 365));

    if (endDate.isBefore(startDate)) endDate = startDate;

    final initialUnit = units.firstWhere((u) => u.id == unitId);
    final rent = TextEditingController(
      text: (contract?.monthlyRent ?? initialUnit.monthlyRent).toString(),
    );
    final deposit = TextEditingController(
      text: (contract?.depositAmount ?? 0).toString(),
    );
    final notes = TextEditingController(text: contract?.notes ?? '');
    final formKey = GlobalKey<FormState>();

    String dateText(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    String? amountValidator(String? value, {required bool allowZero}) {
      final amount = double.tryParse(value?.trim() ?? '');
      if (amount == null || !amount.isFinite) {
        return _local('أدخل مبلغًا رقميًا صحيحًا', 'Enter a valid number');
      }
      if (allowZero ? amount < 0 : amount <= 0) {
        return allowZero
            ? _local(
                'لا يمكن أن يكون المبلغ سالبًا',
                'Amount cannot be negative',
              )
            : _local(
                'يجب أن يكون المبلغ أكبر من صفر',
                'Amount must be greater than zero',
              );
      }
      return null;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          var isSaving = false;

          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text(
                contract == null ? 'create_contract'.tr : 'edit_contract'.tr,
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
                          decoration: InputDecoration(labelText: 'tenant'.tr),
                          items: tenants.where((t) => t.id != null).map((
                            tenant,
                          ) {
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
                          decoration: InputDecoration(labelText: 'unit'.tr),
                          items: units.map((unit) {
                            return DropdownMenuItem<int>(
                              value: unit.id,
                              child: Text(
                                '${unit.label} (${_translatedStatus(unit.status)})',
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
                                      rent.text = units
                                          .firstWhere(
                                            (unit) => unit.id == value,
                                          )
                                          .monthlyRent
                                          .toString();
                                    }
                                  });
                                },
                        ),
                        const SizedBox(height: 8),
                        _dateSelector(
                          context: context,
                          title: 'start_date'.tr,
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
                          title: 'end_date'.tr,
                          date: endDate,
                          enabled: !isSaving,
                          firstDate: startDate,
                          onSelected: (value) =>
                              setDialogState(() => endDate = value),
                        ),
                        TextFormField(
                          controller: rent,
                          decoration: InputDecoration(
                            labelText: 'monthly_rent'.tr,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              amountValidator(value, allowZero: false),
                        ),
                        TextFormField(
                          controller: deposit,
                          decoration: InputDecoration(
                            labelText: 'deposit_amount'.tr,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              amountValidator(value, allowZero: true),
                        ),
                        TextFormField(
                          controller: notes,
                          decoration: InputDecoration(labelText: 'notes'.tr),
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
                  child: Text('cancel'.tr),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          if (endDate.isBefore(startDate)) {
                            Get.snackbar(
                              'invalid_dates'.tr,
                              'end_date_before_start'.tr,
                            );
                            return;
                          }

                          final selectedTenant = tenants.where(
                            (t) => t.id == tenantId,
                          );
                          final selectedUnit = units.where(
                            (u) => u.id == unitId,
                          );

                          if (selectedTenant.isEmpty || selectedUnit.isEmpty) {
                            Get.snackbar(
                              _local('تعذر الحفظ', 'Unable to save'),
                              _local(
                                'تغيرت البيانات المختارة. أغلق النافذة وحاول مجددًا.',
                                'The selected data changed. Close and try again.',
                              ),
                            );
                            return;
                          }

                          final rentValue = double.tryParse(rent.text.trim());
                          final depositValue = double.tryParse(
                            deposit.text.trim(),
                          );

                          if (rentValue == null ||
                              !rentValue.isFinite ||
                              rentValue <= 0 ||
                              depositValue == null ||
                              !depositValue.isFinite ||
                              depositValue < 0) {
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          final saved = await controller.saveContract(
                            ContractEntity(
                              id: contract?.id,
                              contractNumber: contract?.contractNumber ?? '',
                              tenantId: tenantId,
                              tenantName: selectedTenant.first.fullName,
                              unitId: unitId,
                              unitLabel: selectedUnit.first.label,
                              startDate: dateText(startDate),
                              endDate: dateText(endDate),
                              monthlyRent: rentValue,
                              depositAmount: depositValue,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      rent.dispose();
      deposit.dispose();
      notes.dispose();
    }
  }

  // DATE PICKER

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
              final minimum = firstDate ?? DateTime(2000);
              final maximum = DateTime(2100);
              final initial = date.isBefore(minimum)
                  ? minimum
                  : date.isAfter(maximum)
                  ? maximum
                  : date;

              final selected = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: minimum,
                lastDate: maximum,
                locale: Get.locale,
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
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
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

  // DELETE TENANT

  Future<void> _confirmDeleteTenant(
    BuildContext context,
    TenantEntity tenant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('delete_tenant_title'.tr),
        content: Text(
          'delete_tenant_message'.trParams({'name': tenant.fullName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true && tenant.id != null) {
      await controller.deleteTenant(tenant.id!);
    }
  }

  // CONTRACT STATUS CONFIRMATION

  Future<void> _confirmContractStatus(
    BuildContext context,
    ContractEntity contract,
    String status,
  ) async {
    final translatedStatus = _translatedStatus(status);
    final isRestore = status == 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          isRestore
              ? _local('استعادة العقد', 'Restore contract')
              : 'delete_contract_title'.trParams({'status': translatedStatus}),
        ),
        content: Text(
          isRestore
              ? _local(
                  'هل تريد إعادة العقد رقم ${contract.contractNumber} إلى الحالة النشطة؟',
                  'Restore contract ${contract.contractNumber} to active status?',
                )
              : 'confirm_contract_status'.trParams({
                  'status': translatedStatus,
                  'number': contract.contractNumber,
                }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isRestore ? _local('استعادة', 'Restore') : translatedStatus,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && contract.id != null) {
      await controller.changeStatus(contract.id!, status);
    }
  }

  // TRANSLATE STATUS VALUES

  String _translatedStatus(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return 'active'.tr;
      case 'terminated':
        return 'terminated'.tr;
      case 'archived':
        return 'archived'.tr;
      case 'available':
        return 'available'.tr;
      case 'occupied':
        return 'occupied'.tr;
      case 'maintenance':
        return 'maintenance'.tr;
      default:
        return value;
    }
  }
}
