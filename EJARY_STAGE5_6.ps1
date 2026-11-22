
$ErrorActionPreference = 'Stop'

$Project = 'D:\Flutter_Dart2\lab4\ejary'
$BackupRoot = 'D:\Flutter_Dart2\lab4\ejary_backups'
$Stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$Backup = Join-Path $BackupRoot "stage5_6_$Stamp"
$Utf8 = New-Object System.Text.UTF8Encoding($false)

if (!(Test-Path $Project)) { throw "Project not found: $Project" }

$Files = @(
    'lib\routes\app_routes.dart',
    'lib\routes\app_pages.dart',
    'lib\core\locale\app_translations.dart',
    'lib\features\dues_payments\data\repositories\dues_payments_repository.dart',
    'lib\features\dues_payments\presentation\bindings\dues_payments_binding.dart',
    'lib\features\dues_payments\presentation\controllers\dues_payments_controller.dart',
    'lib\features\dues_payments\presentation\screens\dues_payments_screen.dart'
)

New-Item -ItemType Directory -Path $Backup -Force | Out-Null

foreach ($Relative in $Files) {
    $Full = Join-Path $Project $Relative
    if (Test-Path $Full) {
        $Dest = Join-Path $Backup $Relative
        New-Item -ItemType Directory -Path (Split-Path $Dest) -Force | Out-Null
        Copy-Item $Full $Dest -Force
    }
}

function Write-ProjectFile {
    param([string]$Relative, [string]$Content)
    $Full = Join-Path $Project $Relative
    New-Item -ItemType Directory -Path (Split-Path $Full) -Force | Out-Null
    [IO.File]::WriteAllText($Full, $Content, $Utf8)
}

try {
    # =========================================================
    # Repository: Dues, Payments and Allocations
    # =========================================================

    $Repository = @'
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';

class DuesPaymentsRepository {
  DuesPaymentsRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Database get _db => localDatabase.database;

  Future<List<Map<String, Object?>>> getContracts() async {
    return _db.rawQuery('''
      SELECT c.id, c.contract_number, c.tenant_id, c.status,
             t.full_name AS tenant_name
      FROM contracts c
      INNER JOIN tenants t ON t.id = c.tenant_id
      ORDER BY c.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> getDues() async {
    return _db.rawQuery('''
      SELECT
        d.id, d.contract_id, d.description, d.amount, d.due_date,
        d.status, d.created_at,
        c.contract_number, c.tenant_id,
        t.full_name AS tenant_name,
        COALESCE(SUM(pa.allocated_amount), 0) AS paid_amount,
        d.amount - COALESCE(SUM(pa.allocated_amount), 0) AS balance
      FROM dues d
      INNER JOIN contracts c ON c.id = d.contract_id
      INNER JOIN tenants t ON t.id = c.tenant_id
      LEFT JOIN payment_allocations pa ON pa.due_id = d.id
      GROUP BY d.id
      ORDER BY d.due_date DESC, d.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> getPayments() async {
    return _db.rawQuery('''
      SELECT
        p.id, p.tenant_id, p.contract_id, p.amount, p.payment_date,
        p.payment_method, p.reference_number, p.notes, p.created_at,
        t.full_name AS tenant_name,
        c.contract_number,
        COALESCE(SUM(pa.allocated_amount), 0) AS allocated_amount,
        p.amount - COALESCE(SUM(pa.allocated_amount), 0) AS remaining_amount
      FROM payments p
      INNER JOIN tenants t ON t.id = p.tenant_id
      LEFT JOIN contracts c ON c.id = p.contract_id
      LEFT JOIN payment_allocations pa ON pa.payment_id = p.id
      GROUP BY p.id
      ORDER BY p.payment_date DESC, p.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> getAllocations() async {
    return _db.rawQuery('''
      SELECT
        pa.id, pa.payment_id, pa.due_id, pa.allocated_amount,
        pa.created_at,
        p.payment_date, p.reference_number,
        t.full_name AS tenant_name,
        d.description AS due_description,
        d.due_date,
        c.contract_number
      FROM payment_allocations pa
      INNER JOIN payments p ON p.id = pa.payment_id
      INNER JOIN tenants t ON t.id = p.tenant_id
      INNER JOIN dues d ON d.id = pa.due_id
      INNER JOIN contracts c ON c.id = d.contract_id
      ORDER BY pa.id DESC
    ''');
  }

  Future<void> createManualDue({
    required int contractId,
    required String description,
    required double amount,
    required String dueDate,
  }) async {
    if (description.trim().isEmpty ||
        !amount.isFinite ||
        amount <= 0 ||
        DateTime.tryParse(dueDate) == null) {
      throw Exception('Enter valid due information.');
    }

    await _db.transaction((txn) async {
      final contracts = await txn.query(
        'contracts',
        columns: ['id', 'status'],
        where: 'id = ?',
        whereArgs: [contractId],
        limit: 1,
      );

      if (contracts.isEmpty) throw Exception('Contract not found.');

      await txn.insert('dues', {
        'contract_id': contractId,
        'description': description.trim(),
        'amount': amount,
        'due_date': dueDate,
        'status': 'unpaid',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _audit(
        txn,
        'CREATE',
        'due',
        contractId,
        'Manual due created: ${description.trim()}',
      );
    });
  }

  Future<void> recordPayment({
    required int contractId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    required String referenceNumber,
    required String notes,
  }) async {
    if (!amount.isFinite ||
        amount <= 0 ||
        DateTime.tryParse(paymentDate) == null) {
      throw Exception('Enter a valid payment amount and date.');
    }

    await _db.transaction((txn) async {
      final contracts = await txn.query(
        'contracts',
        columns: ['id', 'tenant_id', 'contract_number'],
        where: 'id = ?',
        whereArgs: [contractId],
        limit: 1,
      );

      if (contracts.isEmpty) throw Exception('Contract not found.');

      final contract = contracts.first;
      final tenantId = contract['tenant_id'] as int;

      final paymentId = await txn.insert('payments', {
        'tenant_id': tenantId,
        'contract_id': contractId,
        'amount': amount,
        'payment_date': paymentDate,
        'payment_method': paymentMethod,
        'reference_number': referenceNumber.trim(),
        'notes': notes.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _audit(
        txn,
        'CREATE',
        'payment',
        paymentId,
        'Payment recorded for contract ${contract['contract_number']}',
      );
    });
  }

  Future<void> allocatePayment({
    required int paymentId,
    required int dueId,
    required double amount,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw Exception('Allocation amount must be greater than zero.');
    }

    await _db.transaction((txn) async {
      final paymentRows = await txn.query(
        'payments',
        columns: ['id', 'tenant_id', 'contract_id', 'amount'],
        where: 'id = ?',
        whereArgs: [paymentId],
        limit: 1,
      );

      if (paymentRows.isEmpty) throw Exception('Payment not found.');

      final dueRows = await txn.rawQuery(
        '''
        SELECT d.id, d.contract_id, d.amount,
               c.tenant_id, c.contract_number
        FROM dues d
        INNER JOIN contracts c ON c.id = d.contract_id
        WHERE d.id = ?
        LIMIT 1
        ''',
        [dueId],
      );

      if (dueRows.isEmpty) throw Exception('Due not found.');

      final payment = paymentRows.first;
      final due = dueRows.first;

      if (payment['tenant_id'] != due['tenant_id']) {
        throw Exception('Payment and due belong to different tenants.');
      }

      final paymentContractId = payment['contract_id'] as int?;
      final dueContractId = due['contract_id'] as int;

      if (paymentContractId != null &&
          paymentContractId != dueContractId) {
        throw Exception('Payment and due belong to different contracts.');
      }

      final paymentAllocatedRows = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(allocated_amount), 0) AS total
        FROM payment_allocations
        WHERE payment_id = ?
        ''',
        [paymentId],
      );

      final dueAllocatedRows = await txn.rawQuery(
        '''
        SELECT COALESCE(SUM(allocated_amount), 0) AS total
        FROM payment_allocations
        WHERE due_id = ?
        ''',
        [dueId],
      );

      final paymentAmount = (payment['amount'] as num).toDouble();
      final dueAmount = (due['amount'] as num).toDouble();
      final paymentAllocated =
          (paymentAllocatedRows.first['total'] as num).toDouble();
      final dueAllocated =
          (dueAllocatedRows.first['total'] as num).toDouble();

      final paymentBalance = paymentAmount - paymentAllocated;
      final dueBalance = dueAmount - dueAllocated;
      const tolerance = 0.000001;

      if (amount > paymentBalance + tolerance) {
        throw Exception('Allocation exceeds the remaining payment balance.');
      }

      if (amount > dueBalance + tolerance) {
        throw Exception('Allocation exceeds the remaining due balance.');
      }

      await txn.insert('payment_allocations', {
        'payment_id': paymentId,
        'due_id': dueId,
        'allocated_amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      });

      final newDuePaid = dueAllocated + amount;
      final String newStatus;

      if (newDuePaid >= dueAmount - tolerance) {
        newStatus = 'paid';
      } else if (newDuePaid > tolerance) {
        newStatus = 'partial';
      } else {
        newStatus = 'unpaid';
      }

      await txn.update(
        'dues',
        {'status': newStatus},
        where: 'id = ?',
        whereArgs: [dueId],
      );

      await _audit(
        txn,
        'ALLOCATE',
        'payment',
        paymentId,
        'Allocated $amount to due $dueId',
      );
    });
  }

  Future<void> _audit(
    Transaction txn,
    String action,
    String entityType,
    int entityId,
    String description,
  ) async {
    await txn.insert('audit_logs', {
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
'@

    Write-ProjectFile `
        'lib\features\dues_payments\data\repositories\dues_payments_repository.dart' `
        $Repository

    # =========================================================
    # Binding
    # =========================================================

    $Binding = @'
import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/dues_payments_repository.dart';
import '../controllers/dues_payments_controller.dart';

class DuesPaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DuesPaymentsRepository>(
      () => DuesPaymentsRepository(
        localDatabase: Get.find<LocalDatabase>(),
      ),
    );

    Get.lazyPut<DuesPaymentsController>(
      () => DuesPaymentsController(
        repository: Get.find<DuesPaymentsRepository>(),
      ),
    );
  }
}
'@

    Write-ProjectFile `
        'lib\features\dues_payments\presentation\bindings\dues_payments_binding.dart' `
        $Binding

    # =========================================================
    # Controller
    # =========================================================

    $Controller = @'
import 'package:get/get.dart';

import '../../data/repositories/dues_payments_repository.dart';

class DuesPaymentsController extends GetxController {
  DuesPaymentsController({required this.repository});

  final DuesPaymentsRepository repository;

  final dues = <Map<String, Object?>>[].obs;
  final payments = <Map<String, Object?>>[].obs;
  final allocations = <Map<String, Object?>>[].obs;
  final contracts = <Map<String, Object?>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final results = await Future.wait([
        repository.getDues(),
        repository.getPayments(),
        repository.getAllocations(),
        repository.getContracts(),
      ]);

      dues.assignAll(results[0]);
      payments.assignAll(results[1]);
      allocations.assignAll(results[2]);
      contracts.assignAll(results[3]);
    } catch (error) {
      _showError(error);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createManualDue({
    required int contractId,
    required String description,
    required double amount,
    required String dueDate,
  }) async {
    try {
      await repository.createManualDue(
        contractId: contractId,
        description: description,
        amount: amount,
        dueDate: dueDate,
      );
      await loadData();
      Get.snackbar('success'.tr, 'due_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> recordPayment({
    required int contractId,
    required double amount,
    required String paymentDate,
    required String paymentMethod,
    required String referenceNumber,
    required String notes,
  }) async {
    try {
      await repository.recordPayment(
        contractId: contractId,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        notes: notes,
      );
      await loadData();
      Get.snackbar('success'.tr, 'payment_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  Future<bool> allocatePayment({
    required int paymentId,
    required int dueId,
    required double amount,
  }) async {
    try {
      await repository.allocatePayment(
        paymentId: paymentId,
        dueId: dueId,
        amount: amount,
      );
      await loadData();
      Get.snackbar('success'.tr, 'allocation_saved'.tr);
      return true;
    } catch (error) {
      _showError(error);
      return false;
    }
  }

  void _showError(Object error) {
    Get.snackbar(
      'error'.tr,
      error.toString().replaceFirst('Exception: ', ''),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  }
}
'@

    Write-ProjectFile `
        'lib\features\dues_payments\presentation\controllers\dues_payments_controller.dart' `
        $Controller

    # =========================================================
    # Screen
    # =========================================================

    $Screen = @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dues_payments_controller.dart';

class DuesPaymentsScreen extends GetView<DuesPaymentsController> {
  const DuesPaymentsScreen({super.key});

  String _money(Object? value) {
    final number = (value as num?)?.toDouble() ?? 0;
    return number.toStringAsFixed(2);
  }

  String _dueStatus(Map<String, Object?> item) {
    final balance = (item['balance'] as num?)?.toDouble() ?? 0;
    if (balance <= 0.000001) return 'paid'.tr;

    final paid = (item['paid_amount'] as num?)?.toDouble() ?? 0;
    if (paid > 0) return 'partial'.tr;

    final date = DateTime.tryParse('${item['due_date']}');
    if (date != null && date.isBefore(DateTime.now()) &&
        date.year != DateTime.now().year ||
        date != null && date.isBefore(DateTime.now()) &&
        date.month != DateTime.now().month ||
        date != null && date.isBefore(DateTime.now()) &&
        date.day != DateTime.now().day) {
      return 'overdue'.tr;
    }

    return 'unpaid'.tr;
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
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            children: [
              _duesTab(),
              _paymentsTab(),
              _allocationsTab(),
            ],
          );
        }),
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

            return Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.receipt_long_outlined),
                ),
                title: Text('${item['description']}'),
                subtitle: Text(
                  '${item['tenant_name']} • ${item['contract_number']}\n'
                  '${'due_date'.tr}: ${item['due_date']}\n'
                  '${'amount'.tr}: ${_money(item['amount'])}   '
                  '${'paid_amount'.tr}: ${_money(item['paid_amount'])}\n'
                  '${'remaining_amount'.tr}: ${_money(item['balance'])}',
                ),
                isThreeLine: true,
                trailing: Text(
                  _dueStatus(item),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: (item['balance'] as num).toDouble() <= 0
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
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
                  '${'payment'.tr} #${item['id']} • ${_money(item['amount'])}',
                ),
                subtitle: Text(
                  '${item['tenant_name']}\n'
                  '${item['contract_number'] ?? ''}\n'
                  '${'payment_date'.tr}: ${item['payment_date']}\n'
                  '${'allocated_amount'.tr}: ${_money(item['allocated_amount'])}   '
                  '${'remaining_amount'.tr}: ${_money(item['remaining_amount'])}',
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
                title: Text('${item['due_description']}'),
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

    final description = TextEditingController();
    final amount = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    int? contractId = controller.contracts.first['id'] as int;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('add_due'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: contractId,
                    decoration: InputDecoration(labelText: 'contract'.tr),
                    items: controller.contracts.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(
                          '${item['contract_number']} - ${item['tenant_name']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => contractId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: description,
                    decoration: InputDecoration(
                      labelText: 'due_description'.tr,
                    ),
                  ),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'amount'.tr),
                  ),
                  TextField(
                    controller: date,
                    decoration: InputDecoration(
                      labelText: 'due_date_format'.tr,
                      hintText: 'YYYY-MM-DD',
                    ),
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
                  final parsed = double.tryParse(amount.text.trim());
                  if (contractId == null || parsed == null) {
                    Get.snackbar('error'.tr, 'invalid_due'.tr);
                    return;
                  }

                  final saved = await controller.createManualDue(
                    contractId: contractId!,
                    description: description.text,
                    amount: parsed,
                    dueDate: date.text.trim(),
                  );

                  if (saved) Get.back();
                },
                child: Text('save'.tr),
              ),
            ],
          );
        },
      ),
    );

    description.dispose();
    amount.dispose();
    date.dispose();
  }

  Future<void> _showPaymentDialog() async {
    if (controller.contracts.isEmpty) {
      Get.snackbar('notice'.tr, 'no_contracts'.tr);
      return;
    }

    final amount = TextEditingController();
    final date = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final reference = TextEditingController();
    final notes = TextEditingController();

    int? contractId = controller.contracts.first['id'] as int;
    String method = 'cash';

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('record_payment'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: contractId,
                    decoration: InputDecoration(labelText: 'contract'.tr),
                    items: controller.contracts.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(
                          '${item['contract_number']} - ${item['tenant_name']}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => contractId = value),
                  ),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(labelText: 'amount'.tr),
                  ),
                  TextField(
                    controller: date,
                    decoration: InputDecoration(
                      labelText: 'payment_date_format'.tr,
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: InputDecoration(
                      labelText: 'payment_method'.tr,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'cash',
                        child: Text('cash'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('bank_transfer'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('card'.tr),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('other'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => method = value);
                    },
                  ),
                  TextField(
                    controller: reference,
                    decoration: InputDecoration(
                      labelText: 'reference_number'.tr,
                    ),
                  ),
                  TextField(
                    controller: notes,
                    decoration: InputDecoration(labelText: 'notes'.tr),
                    maxLines: 2,
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
                  final parsed = double.tryParse(amount.text.trim());
                  if (contractId == null || parsed == null) {
                    Get.snackbar('error'.tr, 'invalid_payment'.tr);
                    return;
                  }

                  final saved = await controller.recordPayment(
                    contractId: contractId!,
                    amount: parsed,
                    paymentDate: date.text.trim(),
                    paymentMethod: method,
                    referenceNumber: reference.text,
                    notes: notes.text,
                  );

                  if (saved) Get.back();
                },
                child: Text('save'.tr),
              ),
            ],
          );
        },
      ),
    );

    amount.dispose();
    date.dispose();
    reference.dispose();
    notes.dispose();
  }

  Future<void> _showAllocationDialog() async {
    final availablePayments = controller.payments.where((item) {
      return ((item['remaining_amount'] as num?)?.toDouble() ?? 0) > 0.000001;
    }).toList();

    if (availablePayments.isEmpty) {
      Get.snackbar('notice'.tr, 'no_unallocated_payments'.tr);
      return;
    }

    int? paymentId = availablePayments.first['id'] as int;
    int? dueId;
    final amount = TextEditingController();

    List<Map<String, Object?>> eligibleDues(int selectedPaymentId) {
      final payment = availablePayments.firstWhere(
        (item) => item['id'] == selectedPaymentId,
      );
      final tenantId = payment['tenant_id'];

      return controller.dues.where((due) {
        final balance = (due['balance'] as num?)?.toDouble() ?? 0;
        return due['tenant_id'] == tenantId && balance > 0.000001;
      }).toList();
    }

    var candidates = eligibleDues(paymentId);
    if (candidates.isNotEmpty) {
      dueId = candidates.first['id'] as int;
    }

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          candidates = eligibleDues(paymentId!);

          if (dueId != null &&
              !candidates.any((item) => item['id'] == dueId)) {
            dueId = candidates.isEmpty ? null : candidates.first['id'] as int;
          }

          return AlertDialog(
            title: Text('allocate_payment'.tr),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: paymentId,
                    decoration: InputDecoration(
                      labelText: 'select_payment'.tr,
                    ),
                    items: availablePayments.map((item) {
                      return DropdownMenuItem<int>(
                        value: item['id'] as int,
                        child: Text(
                          '#${item['id']} • ${item['tenant_name']} • '
                          '${'remaining_amount'.tr}: '
                          '${_money(item['remaining_amount'])}',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          paymentId = value;
                          final next = eligibleDues(value);
                          dueId = next.isEmpty ? null : next.first['id'] as int;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (candidates.isEmpty)
                    Text('no_outstanding_dues'.tr)
                  else
                    DropdownButtonFormField<int>(
                      initialValue: dueId,
                      decoration: InputDecoration(
                        labelText: 'select_due'.tr,
                      ),
                      items: candidates.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['id'] as int,
                          child: Text(
                            '${item['description']} • '
                            '${'remaining_amount'.tr}: ${_money(item['balance'])}',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => dueId = value),
                    ),
                  TextField(
                    controller: amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'allocation_amount'.tr,
                    ),
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
                onPressed: candidates.isEmpty || dueId == null
                    ? null
                    : () async {
                        final parsed = double.tryParse(amount.text.trim());
                        if (parsed == null) {
                          Get.snackbar('error'.tr, 'invalid_allocation'.tr);
                          return;
                        }

                        final saved = await controller.allocatePayment(
                          paymentId: paymentId!,
                          dueId: dueId!,
                          amount: parsed,
                        );

                        if (saved) Get.back();
                      },
                child: Text('allocate'.tr),
              ),
            ],
          );
        },
      ),
    );

    amount.dispose();
  }
}
'@

    Write-ProjectFile `
        'lib\features\dues_payments\presentation\screens\dues_payments_screen.dart' `
        $Screen

    # =========================================================
    # Add route constant and page registration
    # =========================================================

    $RoutesPath = Join-Path $Project 'lib\routes\app_routes.dart'
    $RoutesSource = [IO.File]::ReadAllText($RoutesPath)

    if ($RoutesSource -notmatch 'duesPayments') {
        $Anchor = "  static const services = '/services';"
        if (!$RoutesSource.Contains($Anchor)) {
            throw 'Could not locate services route in app_routes.dart'
        }
        $RoutesSource = $RoutesSource.Replace(
            $Anchor,
            $Anchor + "`r`n  static const duesPayments = '/dues-payments';"
        )
    }

    [IO.File]::WriteAllText($RoutesPath, $RoutesSource, $Utf8)

    $PagesPath = Join-Path $Project 'lib\routes\app_pages.dart'
    $PagesSource = [IO.File]::ReadAllText($PagesPath)

    if ($PagesSource -notmatch 'DuesPaymentsBinding') {
        $ImportAnchor = "import '../features/services/presentation/screens/services_screen.dart';"
        if (!$PagesSource.Contains($ImportAnchor)) {
            throw 'Could not locate services screen import in app_pages.dart'
        }

        $PagesSource = $PagesSource.Replace(
            $ImportAnchor,
            $ImportAnchor + "`r`n" +
            "import '../features/dues_payments/presentation/bindings/dues_payments_binding.dart';`r`n" +
            "import '../features/dues_payments/presentation/screens/dues_payments_screen.dart';"
        )

                $RoutePattern = '(?s)(    GetPage\(\s*name:\s*AppRoutes\.services,\s*page:\s*\(\)\s*=>\s*const ServicesScreen\(\),\s*binding:\s*ServicesBinding\(\),\s*\),)'

        $RouteMatch = [regex]::Match($PagesSource, $RoutePattern)

        if (!$RouteMatch.Success) {
            throw 'Could not locate services page registration in app_pages.dart'
        }

        $NewRoute = @'
    GetPage(
      name: AppRoutes.duesPayments,
      page: () => const DuesPaymentsScreen(),
      binding: DuesPaymentsBinding(),
    ),
'@

        $InsertPosition = $RouteMatch.Index + $RouteMatch.Length

        $PagesSource = $PagesSource.Insert(
            $InsertPosition,
            [Environment]::NewLine + $NewRoute.TrimStart("`r", "`n")
        )
    }

    [IO.File]::WriteAllText($PagesPath, $PagesSource, $Utf8)

    # =========================================================
    # Add translation entries to both locales
    # =========================================================

    $TranslationPath = Join-Path $Project 'lib\core\locale\app_translations.dart'
    $TranslationSource = [IO.File]::ReadAllText($TranslationPath)

    $EnglishEntries = [ordered]@{
        'dues_payments_title' = 'Dues & Payments'
        'dues_tab' = 'Dues'
        'payments_tab' = 'Payments'
        'allocations_tab' = 'Allocations'
        'no_dues' = 'No dues found.'
        'no_payments' = 'No payments found.'
        'no_allocations' = 'No allocations found.'
        'no_contracts' = 'No contracts available.'
        'add_due' = 'Add manual due'
        'due_description' = 'Due description'
        'due_date' = 'Due date'
        'due_date_format' = 'Due date (YYYY-MM-DD)'
        'payment_date' = 'Payment date'
        'payment_date_format' = 'Payment date (YYYY-MM-DD)'
        'amount' = 'Amount'
        'paid_amount' = 'Paid amount'
        'remaining_amount' = 'Remaining amount'
        'allocated_amount' = 'Allocated amount'
        'record_payment' = 'Record payment'
        'payment' = 'Payment'
        'payment_method' = 'Payment method'
        'cash' = 'Cash'
        'bank_transfer' = 'Bank transfer'
        'card' = 'Card'
        'other' = 'Other'
        'reference_number' = 'Reference number'
        'notes' = 'Notes'
        'allocate_payment' = 'Allocate payment'
        'select_payment' = 'Select payment'
        'select_due' = 'Select due'
        'allocation_amount' = 'Allocation amount'
        'allocate' = 'Allocate'
        'no_unallocated_payments' = 'No payments with remaining balance.'
        'no_outstanding_dues' = 'No outstanding dues for this tenant.'
        'invalid_due' = 'Enter a valid description, amount and date.'
        'invalid_payment' = 'Enter a valid payment amount.'
        'invalid_allocation' = 'Enter a valid allocation amount.'
        'due_saved' = 'Due saved successfully.'
        'payment_saved' = 'Payment recorded successfully.'
        'allocation_saved' = 'Payment allocated successfully.'
        'unpaid' = 'Unpaid'
        'partial' = 'Partially paid'
        'paid' = 'Paid'
        'overdue' = 'Overdue'
    }

        $ArabicEntries = [ordered]@{
        'dues_payments_title' = '\u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642\u0627\u062A \u0648\u0627\u0644\u062F\u0641\u0639\u0627\u062A'
        'dues_tab' = '\u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642\u0627\u062A'
        'payments_tab' = '\u0627\u0644\u062F\u0641\u0639\u0627\u062A'
        'allocations_tab' = '\u062A\u0648\u0632\u064A\u0639 \u0627\u0644\u062F\u0641\u0639\u0627\u062A'
        'no_dues' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u0627\u0633\u062A\u062D\u0642\u0627\u0642\u0627\u062A.'
        'no_payments' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u062F\u0641\u0639\u0627\u062A.'
        'no_allocations' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u062A\u0648\u0632\u064A\u0639\u0627\u062A \u0644\u0644\u062F\u0641\u0639\u0627\u062A.'
        'no_contracts' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u0639\u0642\u0648\u062F \u0645\u062A\u0627\u062D\u0629.'
        'add_due' = '\u0625\u0636\u0627\u0641\u0629 \u0627\u0633\u062A\u062D\u0642\u0627\u0642 \u064A\u062F\u0648\u064A'
        'due_description' = '\u0648\u0635\u0641 \u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642'
        'due_date' = '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642'
        'due_date_format' = '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642 (YYYY-MM-DD)'
        'payment_date' = '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u062F\u0641\u0639\u0629'
        'payment_date_format' = '\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u062F\u0641\u0639\u0629 (YYYY-MM-DD)'
        'amount' = '\u0627\u0644\u0645\u0628\u0644\u063A'
        'paid_amount' = '\u0627\u0644\u0645\u0628\u0644\u063A \u0627\u0644\u0645\u0633\u062F\u062F'
        'remaining_amount' = '\u0627\u0644\u0645\u0628\u0644\u063A \u0627\u0644\u0645\u062A\u0628\u0642\u064A'
        'allocated_amount' = '\u0627\u0644\u0645\u0628\u0644\u063A \u0627\u0644\u0645\u0648\u0632\u0639'
        'record_payment' = '\u062A\u0633\u062C\u064A\u0644 \u062F\u0641\u0639\u0629'
        'payment' = '\u062F\u0641\u0639\u0629'
        'payment_method' = '\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639'
        'cash' = '\u0646\u0642\u062F\u064B\u0627'
        'bank_transfer' = '\u062A\u062D\u0648\u064A\u0644 \u0628\u0646\u0643\u064A'
        'card' = '\u0628\u0637\u0627\u0642\u0629'
        'other' = '\u0623\u062E\u0631\u0649'
        'reference_number' = '\u0631\u0642\u0645 \u0627\u0644\u0645\u0631\u062C\u0639'
        'notes' = '\u0645\u0644\u0627\u062D\u0638\u0627\u062A'
        'allocate_payment' = '\u062A\u0648\u0632\u064A\u0639 \u062F\u0641\u0639\u0629'
        'select_payment' = '\u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0644\u062F\u0641\u0639\u0629'
        'select_due' = '\u0627\u062E\u062A\u064A\u0627\u0631 \u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642'
        'allocation_amount' = '\u0645\u0628\u0644\u063A \u0627\u0644\u062A\u0648\u0632\u064A\u0639'
        'allocate' = '\u062A\u0648\u0632\u064A\u0639'
        'no_unallocated_payments' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u062F\u0641\u0639\u0627\u062A \u0644\u0647\u0627 \u0631\u0635\u064A\u062F \u0645\u062A\u0628\u0642\u064D.'
        'no_outstanding_dues' = '\u0644\u0627 \u062A\u0648\u062C\u062F \u0627\u0633\u062A\u062D\u0642\u0627\u0642\u0627\u062A \u0645\u062A\u0628\u0642\u064A\u0629 \u0644\u0647\u0630\u0627 \u0627\u0644\u0645\u0633\u062A\u0623\u062C\u0631.'
        'invalid_due' = '\u0623\u062F\u062E\u0644\u064A \u0648\u0635\u0641\u064B\u0627 \u0648\u0645\u0628\u0644\u063A\u064B\u0627 \u0648\u062A\u0627\u0631\u064A\u062E\u064B\u0627 \u0635\u062D\u064A\u062D\u064B\u0627.'
        'invalid_payment' = '\u0623\u062F\u062E\u0644\u064A \u0645\u0628\u0644\u063A \u062F\u0641\u0639\u0629 \u0635\u062D\u064A\u062D\u064B\u0627.'
        'invalid_allocation' = '\u0623\u062F\u062E\u0644\u064A \u0645\u0628\u0644\u063A \u062A\u0648\u0632\u064A\u0639 \u0635\u062D\u064A\u062D\u064B\u0627.'
        'due_saved' = '\u062A\u0645 \u062D\u0641\u0638 \u0627\u0644\u0627\u0633\u062A\u062D\u0642\u0627\u0642 \u0628\u0646\u062C\u0627\u062D.'
        'payment_saved' = '\u062A\u0645 \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062F\u0641\u0639\u0629 \u0628\u0646\u062C\u0627\u062D.'
        'allocation_saved' = '\u062A\u0645 \u062A\u0648\u0632\u064A\u0639 \u0627\u0644\u062F\u0641\u0639\u0629 \u0628\u0646\u062C\u0627\u062D.'
        'unpaid' = '\u063A\u064A\u0631 \u0645\u0633\u062F\u062F'
        'partial' = '\u0645\u0633\u062F\u062F \u062C\u0632\u0626\u064A\u064B\u0627'
        'paid' = '\u0645\u0633\u062F\u062F'
        'overdue' = '\u0645\u062A\u0623\u062E\u0631'
    }

    foreach ($Key in @($ArabicEntries.Keys)) {
        $ArabicEntries[$Key] = [regex]::Replace(
            $ArabicEntries[$Key],
            '\\u([0-9A-Fa-f]{4})',
            [System.Text.RegularExpressions.MatchEvaluator]{
                param($Match)
                return [string][char][Convert]::ToInt32($Match.Groups[1].Value, 16)
            }
        )
    }

    function Add-LocaleEntries {
        param(
            [string]$Source,
            [string]$Locale,
            [string]$NextLocale,
            [System.Collections.IDictionary]$Entries
        )

        $Start = $Source.IndexOf("'$Locale': {")
        if ($Start -lt 0) { throw "Locale not found: $Locale" }

        if ($NextLocale) {
            $End = $Source.IndexOf("'$NextLocale': {", $Start + 1)
        } else {
            $End = $Source.IndexOf('};', $Start)
        }

        if ($End -lt 0) { throw "Locale ending not found: $Locale" }

        $Close = $Source.LastIndexOf('    },', $End)
        if ($Close -lt $Start) { throw "Map closing not found: $Locale" }

        $Section = $Source.Substring($Start, $Close - $Start)
        $Lines = [System.Collections.Generic.List[string]]::new()

        foreach ($Key in $Entries.Keys) {
            if ($Section -match ("'" + [regex]::Escape($Key) + "'\s*:")) {
                continue
            }

            $Value = ([string]$Entries[$Key]).Replace('\', '\\').Replace("'", "\'")
            $Lines.Add("      '$Key': '$Value',")
        }

        if ($Lines.Count -eq 0) { return $Source }

        return $Source.Insert(
            $Close,
            ($Lines -join "`r`n") + "`r`n"
        )
    }

    $TranslationSource = Add-LocaleEntries `
        -Source $TranslationSource `
        -Locale 'en_US' `
        -NextLocale 'ar_YE' `
        -Entries $EnglishEntries

    $TranslationSource = Add-LocaleEntries `
        -Source $TranslationSource `
        -Locale 'ar_YE' `
        -NextLocale '' `
        -Entries $ArabicEntries

    [IO.File]::WriteAllText($TranslationPath, $TranslationSource, $Utf8)

    # =========================================================
    # Format, analyze and test
    # =========================================================

    Set-Location $Project

    Write-Host "`nFormatting Stage 5 + 6..." -ForegroundColor Cyan
    & dart format lib
    if ($LASTEXITCODE -ne 0) { throw 'Dart format failed.' }

    Write-Host "`nRunning Flutter analyze..." -ForegroundColor Cyan
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analyze failed.' }

    Write-Host "`nRunning Flutter tests..." -ForegroundColor Cyan
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed.' }

    Write-Host "`nSTAGES 5 AND 6 CREATED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "Backup: $Backup"
    Write-Host 'Feature: lib\features\dues_payments'
    Write-Host 'Route: /dues-payments'
}
catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Restoring backed-up files...' -ForegroundColor Yellow

    foreach ($Relative in $Files) {
        $Saved = Join-Path $Backup $Relative
        $Current = Join-Path $Project $Relative

        if (Test-Path $Saved) {
            Copy-Item $Saved $Current -Force
        } elseif (Test-Path $Current) {
            Remove-Item $Current -Force
        }
    }

    Write-Host "Rollback completed. Backup: $Backup" -ForegroundColor Yellow
    throw
}
