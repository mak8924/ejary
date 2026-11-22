import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dues_payments_controller.dart';

class DuesPaymentsScreen extends GetView<DuesPaymentsController> {
  const DuesPaymentsScreen({super.key});

  static const double _epsilon = 0.000001;

  String _money(Object? value) {
    final number = (value as num?)?.toDouble() ?? 0;
    return number.toStringAsFixed(2);
  }

  String _displayDueDescription(Object? value) {
    var description = value?.toString() ?? '';
    description = description.replaceAll(
      RegExp(r'\s*\[service:\d+\]', caseSensitive: false),
      '',
    );
    return description.trim();
  }

  String _dueStatus(Map<String, Object?> item) {
    final balance = (item['balance'] as num?)?.toDouble() ?? 0;

    if (balance <= _epsilon) return 'paid'.tr;

    final paid = (item['paid_amount'] as num?)?.toDouble() ?? 0;
    if (paid > _epsilon) return 'partial'.tr;

    final parsedDate = DateTime.tryParse('${item['due_date']}');

    if (parsedDate != null) {
      final dueDay = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (dueDay.isBefore(today)) return 'overdue'.tr;
    }

    return 'unpaid'.tr;
  }

  Widget _contractDropdown({
    required int? value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: 'contract'.tr),
      items: controller.contracts.map((item) {
        return DropdownMenuItem<int>(
          value: item['id'] as int,
          child: Text(
            '${item['contract_number']} - ${item['tenant_name']}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _dialogContent(Widget child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('dues_payments_title'.tr),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'dues_tab'.tr),
              Tab(text: 'payments_tab'.tr),
              Tab(text: 'allocations_tab'.tr),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [_duesTab(), _paymentsTab(), _allocationsTab()],
            ),
            Obx(() {
              if (!controller.isLoading.value) {
                return const SizedBox.shrink();
              }

              return Positioned.fill(
                child: ColoredBox(
                  color: Colors.black12,
                  child: const Center(child: CircularProgressIndicator()),
                ),
              );
            }),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              tooltip: 'add'.tr,
              onPressed: () {
                final tab = DefaultTabController.of(context).index;

                if (tab == 0) {
                  _showDueDialog();
                } else if (tab == 1) {
                  _showPaymentDialog();
                } else {
                  _showAllocationDialog();
                }
              },
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _duesTab() {
    return Obx(() {
      if (controller.dues.isEmpty) {
        return Center(child: Text('no_dues'.tr));
      }

      return RefreshIndicator(
        onRefresh: controller.loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.dues.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = controller.dues[index];
            final balance = (item['balance'] as num?)?.toDouble() ?? 0;

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text(
                  _displayDueDescription(item['description']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item['tenant_name']} • ${item['contract_number']}\n'
                  '${'due_date'.tr}: ${item['due_date']}\n'
                  '${'amount'.tr}: ${_money(item['amount'])}   '
                  '${'paid_amount'.tr}: ${_money(item['paid_amount'])}\n'
                  '${'remaining_amount'.tr}: ${_money(balance)}',
                ),
                isThreeLine: true,
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 85),
                  child: Text(
                    _dueStatus(item),
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: balance <= _epsilon
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _paymentsTab() {
    return Obx(() {
      if (controller.payments.isEmpty) {
        return Center(child: Text('no_payments'.tr));
      }

      return RefreshIndicator(
        onRefresh: controller.loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.payments.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = controller.payments[index];

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.payments_outlined),
                ),
                title: Text(
                  '${'payment'.tr} #${item['id']} • '
                  '${_money(item['amount'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item['tenant_name']}\n'
                  '${item['contract_number'] ?? ''}\n'
                  '${'payment_date'.tr}: ${item['payment_date']}\n'
                  '${'allocated_amount'.tr}: '
                  '${_money(item['allocated_amount'])}   '
                  '${'remaining_amount'.tr}: '
                  '${_money(item['remaining_amount'])}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _allocationsTab() {
    return Obx(() {
      if (controller.allocations.isEmpty) {
        return Center(child: Text('no_allocations'.tr));
      }

      return RefreshIndicator(
        onRefresh: controller.loadData,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: controller.allocations.length,
          separatorBuilder: (_, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = controller.allocations[index];

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.call_split_outlined),
                ),
                title: Text(
                  _displayDueDescription(item['due_description']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item['tenant_name']} • ${item['contract_number']}\n'
                  '${'payment'.tr} #${item['payment_id']} • '
                  '${'payment_date'.tr}: ${item['payment_date']}',
                ),
                trailing: Text(
                  _money(item['allocated_amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _showDueDialog() async {
    if (controller.contracts.isEmpty) {
      Get.snackbar('notice'.tr, 'no_contracts'.tr);
      return;
    }

    String description = '';
    String amountText = '';
    String dateText = DateTime.now().toIso8601String().substring(0, 10);

    int? contractId = controller.contracts.first['id'] as int;
    bool saving = false;

    await Get.dialog<bool>(
      StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text('add_due'.tr),
            content: _dialogContent(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _contractDropdown(
                    value: contractId,
                    onChanged: saving
                        ? (_) {}
                        : (value) {
                            setState(() => contractId = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: description,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'due_description'.tr,
                    ),
                    onChanged: (value) => description = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: amountText,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'amount'.tr),
                    onChanged: (value) => amountText = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: dateText,
                    decoration: InputDecoration(
                      labelText: 'due_date_format'.tr,
                      hintText: 'YYYY-MM-DD',
                    ),
                    onChanged: (value) => dateText = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text('cancel'.tr),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final parsed = double.tryParse(amountText.trim());

                        if (contractId == null ||
                            description.trim().isEmpty ||
                            parsed == null ||
                            parsed <= 0 ||
                            DateTime.tryParse(dateText.trim()) == null) {
                          Get.snackbar('error'.tr, 'invalid_due'.tr);
                          return;
                        }

                        setState(() => saving = true);

                        final saved = await controller.createManualDue(
                          contractId: contractId!,
                          description: description,
                          amount: parsed,
                          dueDate: dateText.trim(),
                        );

                        if (!dialogContext.mounted) return;

                        if (saved) {
                          Navigator.of(dialogContext).pop(true);
                        } else {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('save'.tr),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showPaymentDialog() async {
    if (controller.contracts.isEmpty) {
      Get.snackbar('notice'.tr, 'no_contracts'.tr);
      return;
    }

    String amountText = '';
    String dateText = DateTime.now().toIso8601String().substring(0, 10);
    String referenceText = '';
    String notesText = '';

    int? contractId = controller.contracts.first['id'] as int;
    String method = 'cash';
    bool saving = false;

    await Get.dialog<bool>(
      StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text('record_payment'.tr),
            content: _dialogContent(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _contractDropdown(
                    value: contractId,
                    onChanged: saving
                        ? (_) {}
                        : (value) {
                            setState(() => contractId = value);
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: amountText,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'amount'.tr),
                    onChanged: (value) => amountText = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: dateText,
                    decoration: InputDecoration(
                      labelText: 'payment_date_format'.tr,
                      hintText: 'YYYY-MM-DD',
                    ),
                    onChanged: (value) => dateText = value,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'payment_method'.tr),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text('cash'.tr)),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('bank_transfer'.tr),
                      ),
                      DropdownMenuItem(value: 'card', child: Text('card'.tr)),
                      DropdownMenuItem(value: 'other', child: Text('other'.tr)),
                    ],
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => method = value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: referenceText,
                    decoration: InputDecoration(
                      labelText: 'reference_number'.tr,
                    ),
                    onChanged: (value) => referenceText = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: notesText,
                    decoration: InputDecoration(labelText: 'notes'.tr),
                    maxLines: 2,
                    onChanged: (value) => notesText = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text('cancel'.tr),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final parsed = double.tryParse(amountText.trim());

                        if (contractId == null ||
                            parsed == null ||
                            parsed <= 0 ||
                            DateTime.tryParse(dateText.trim()) == null) {
                          Get.snackbar('error'.tr, 'invalid_payment'.tr);
                          return;
                        }

                        setState(() => saving = true);

                        final saved = await controller.recordPayment(
                          contractId: contractId!,
                          amount: parsed,
                          paymentDate: dateText.trim(),
                          paymentMethod: method,
                          referenceNumber: referenceText,
                          notes: notesText,
                        );

                        if (!dialogContext.mounted) return;

                        if (saved) {
                          Navigator.of(dialogContext).pop(true);
                        } else {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('save'.tr),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _showAllocationDialog() async {
    final availablePayments = controller.payments.where((item) {
      final remaining = (item['remaining_amount'] as num?)?.toDouble() ?? 0;
      return remaining > _epsilon;
    }).toList();

    if (availablePayments.isEmpty) {
      Get.snackbar('notice'.tr, 'no_unallocated_payments'.tr);
      return;
    }

    int paymentId = availablePayments.first['id'] as int;
    int? dueId;
    String amountText = '';
    bool saving = false;

    List<Map<String, Object?>> eligibleDues(int selectedPaymentId) {
      final payment = availablePayments.firstWhere(
        (item) => item['id'] == selectedPaymentId,
      );
      final tenantId = payment['tenant_id'];

      return controller.dues.where((due) {
        final balance = (due['balance'] as num?)?.toDouble() ?? 0;
        return due['tenant_id'] == tenantId && balance > _epsilon;
      }).toList();
    }

    final initialCandidates = eligibleDues(paymentId);
    if (initialCandidates.isNotEmpty) {
      dueId = initialCandidates.first['id'] as int;
    }

    await Get.dialog<bool>(
      StatefulBuilder(
        builder: (dialogContext, setState) {
          final candidates = eligibleDues(paymentId);
          final selectedDueExists = candidates.any(
            (item) => item['id'] == dueId,
          );

          final displayedDueId = selectedDueExists ? dueId : null;

          return AlertDialog(
            title: Text('allocate_payment'.tr),
            content: _dialogContent(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: paymentId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'select_payment'.tr),
                    items: availablePayments.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(
                          '#${item['id']} • ${item['tenant_name']} • '
                          '${'remaining_amount'.tr}: '
                          '${_money(item['remaining_amount'])}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value == null) return;

                            setState(() {
                              paymentId = value;
                              final next = eligibleDues(value);
                              dueId = next.isEmpty
                                  ? null
                                  : next.first['id'] as int;
                            });
                          },
                  ),
                  const SizedBox(height: 12),
                  if (candidates.isEmpty)
                    Text('no_outstanding_dues'.tr)
                  else
                    DropdownButtonFormField<int>(
                      key: ValueKey('due-$paymentId-$displayedDueId'),
                      initialValue: displayedDueId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'select_due'.tr),
                      items: candidates.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(
                            '${_displayDueDescription(item['description'])} • '
                            '${'remaining_amount'.tr}: '
                            '${_money(item['balance'])}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              setState(() => dueId = value);
                            },
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: amountText,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'allocation_amount'.tr,
                    ),
                    onChanged: (value) => amountText = value,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: Text('cancel'.tr),
              ),
              FilledButton(
                onPressed:
                    saving || candidates.isEmpty || displayedDueId == null
                    ? null
                    : () async {
                        final parsed = double.tryParse(amountText.trim());

                        if (parsed == null || parsed <= 0) {
                          Get.snackbar('error'.tr, 'invalid_allocation'.tr);
                          return;
                        }

                        setState(() => saving = true);

                        final saved = await controller.allocatePayment(
                          paymentId: paymentId,
                          dueId: displayedDueId,
                          amount: parsed,
                        );

                        if (!dialogContext.mounted) return;

                        if (saved) {
                          Navigator.of(dialogContext).pop(true);
                        } else {
                          setState(() => saving = false);
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('allocate'.tr),
              ),
            ],
          );
        },
      ),
      barrierDismissible: false,
    );
  }
}
