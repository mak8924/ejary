
$ErrorActionPreference = 'Stop'

$Project = "D:\Flutter_Dart2\lab4\ejary"
$BackupRoot = "D:\Flutter_Dart2\lab4\ejary_backups"
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Backup = Join-Path $BackupRoot "stage4_fixed_$Stamp"

Set-Location $Project

# Verify clean baseline
if (!(Test-Path "lib\core\database\local_database.dart")) {
    throw "LocalDatabase source file not found."
}
if (!(Test-Path "lib\routes\app_routes.dart") -or !(Test-Path "lib\routes\app_pages.dart")) {
    throw "Application route files not found."
}

New-Item -ItemType Directory -Force -Path $Backup | Out-Null

$FilesToBackup = @(
    "lib\routes\app_routes.dart",
    "lib\routes\app_pages.dart"
)

foreach ($File in $FilesToBackup) {
    $Destination = Join-Path $Backup $File
    New-Item -ItemType Directory -Force -Path (Split-Path $Destination) | Out-Null
    Copy-Item $File $Destination -Force
}

$NewFiles = @(
    "lib\features\services\data\repositories\services_repository.dart",
    "lib\features\services\presentation\bindings\services_binding.dart",
    "lib\features\services\presentation\controllers\services_controller.dart",
    "lib\features\services\presentation\screens\services_screen.dart"
)

try {
    foreach ($File in $NewFiles) {
        $FullPath = Join-Path $Project $File
        New-Item -ItemType Directory -Force -Path (Split-Path $FullPath) | Out-Null
    }

    @'
import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';

class ServicesRepository {
  final LocalDatabase localDatabase;

  ServicesRepository({required this.localDatabase});

  Database get _db => localDatabase.database;

  Future<List<Map<String, Object?>>> getServices() async {
    final db = _db;
    return db.query('services', orderBy: 'name COLLATE NOCASE');
  }

  Future<List<Map<String, Object?>>> getContracts() async {
    final db = _db;
    return db.rawQuery('''
      SELECT c.id, c.contract_number, c.status, t.full_name AS tenant_name
      FROM contracts c
      INNER JOIN tenants t ON t.id = c.tenant_id
      ORDER BY c.id DESC
    ''');
  }

  Future<List<Map<String, Object?>>> getAssignments() async {
    final db = _db;
    return db.rawQuery('''
      SELECT cs.id, cs.contract_id, cs.service_id, cs.amount,
             s.name AS service_name, c.contract_number,
             t.full_name AS tenant_name
      FROM contract_services cs
      INNER JOIN services s ON s.id = cs.service_id
      INNER JOIN contracts c ON c.id = cs.contract_id
      INNER JOIN tenants t ON t.id = c.tenant_id
      ORDER BY cs.id DESC
    ''');
  }

  Future<void> saveService({
    int? id,
    required String name,
    required String description,
    required double amount,
    required String billingPeriod,
  }) async {
    final db = _db;
    final values = <String, Object?>{
      'name': name.trim(),
      'description': description.trim(),
      'default_amount': amount,
      'billing_period': billingPeriod,
      'is_active': 1,
    };

    if (name.trim().isEmpty || !amount.isFinite || amount < 0) {
      throw Exception('Invalid service information.');
    }

    if (id == null) {
      await db.insert('services', values);
    } else {
      final count = await db.update(
        'services',
        values,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) throw Exception('Service not found.');
    }
  }

  Future<void> deactivateService(int id) async {
    final db = _db;
    await db.update(
      'services',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> assignService({
    required int contractId,
    required int serviceId,
    required double amount,
  }) async {
    final db = _db;
    if (!amount.isFinite || amount < 0) {
      throw Exception('Invalid service amount.');
    }

    await db.transaction((txn) async {
      final existing = await txn.query(
        'contract_services',
        columns: ['id'],
        where: 'contract_id = ? AND service_id = ?',
        whereArgs: [contractId, serviceId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        await txn.update(
          'contract_services',
          {'amount': amount},
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await txn.insert('contract_services', {
          'contract_id': contractId,
          'service_id': serviceId,
          'amount': amount,
        });
      }
    });
  }

  Future<void> removeAssignment(int id) async {
    final db = _db;
    await db.delete(
      'contract_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
'@ | Set-Content -Encoding UTF8 $NewFiles[0]

    @'
import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/services_repository.dart';
import '../controllers/services_controller.dart';

class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServicesRepository>(
      () => ServicesRepository(localDatabase: Get.find<LocalDatabase>()),
    );
    Get.lazyPut<ServicesController>(
      () => ServicesController(repository: Get.find<ServicesRepository>()),
    );
  }
}
'@ | Set-Content -Encoding UTF8 $NewFiles[1]

    @'
import 'package:get/get.dart';

import '../../data/repositories/services_repository.dart';

class ServicesController extends GetxController {
  final ServicesRepository repository;

  ServicesController({required this.repository});

  final services = <Map<String, Object?>>[].obs;
  final contracts = <Map<String, Object?>>[].obs;
  final assignments = <Map<String, Object?>>[].obs;
  final isLoading = false.obs;

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        repository.getServices(),
        repository.getContracts(),
        repository.getAssignments(),
      ]);
      services.assignAll(results[0]);
      contracts.assignAll(results[1]);
      assignments.assignAll(results[2]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveService({
    int? id,
    required String name,
    required String description,
    required double amount,
    required String billingPeriod,
  }) async {
    try {
      await repository.saveService(
        id: id,
        name: name,
        description: description,
        amount: amount,
        billingPeriod: billingPeriod,
      );
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar(
        'Error'.tr,
        error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deactivateService(int id) async {
    try {
      await repository.deactivateService(id);
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
      return false;
    }
  }

  Future<bool> assignService({
    required int contractId,
    required int serviceId,
    required double amount,
  }) async {
    try {
      await repository.assignService(
        contractId: contractId,
        serviceId: serviceId,
        amount: amount,
      );
      await loadData();
      return true;
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
      return false;
    }
  }

  Future<void> removeAssignment(int id) async {
    try {
      await repository.removeAssignment(id);
      await loadData();
    } catch (error) {
      Get.snackbar('Error'.tr, error.toString());
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }
}
'@ | Set-Content -Encoding UTF8 $NewFiles[2]

    @'
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/services_controller.dart';

class ServicesScreen extends GetView<ServicesController> {
  const ServicesScreen({super.key});

  bool get _ar => Get.locale?.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t('ط§ظ„ط®ط¯ظ…ط§طھ', 'Services')),
          bottom: TabBar(
            tabs: [
              Tab(text: _t('ظ‚ط§ط¦ظ…ط© ط§ظ„ط®ط¯ظ…ط§طھ', 'Service catalog')),
              Tab(text: _t('ط®ط¯ظ…ط§طھ ط§ظ„ط¹ظ‚ظˆط¯', 'Contract services')),
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
      return Center(child: Text(_t('ظ„ط§ طھظˆط¬ط¯ ط®ط¯ظ…ط§طھ ط¨ط¹ط¯', 'No services yet')));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: active.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = active[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.miscellaneous_services)),
            title: Text('${item['name'] ?? ''}'),
            subtitle: Text(
              '${item['default_amount']}  â€¢  ${item['billing_period'] ?? ''}\n${item['description'] ?? ''}',
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showServiceDialog(context, item: item);
                if (value == 'deactivate') {
                  controller.deactivateService(item['id'] as int);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(_t('طھط¹ط¯ظٹظ„', 'Edit'))),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Text(_t('ط¥ظٹظ‚ط§ظپ ط§ظ„ط®ط¯ظ…ط©', 'Deactivate')),
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
      return Center(
        child: Text(_t('ظ„ط§ طھظˆط¬ط¯ ط®ط¯ظ…ط§طھ ظ…ط±طھط¨ط·ط© ط¨ط§ظ„ط¹ظ‚ظˆط¯', 'No contract services yet')),
      );
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
              '${item['contract_number']}  â€¢  ${item['tenant_name']}\n${item['amount']}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: _t('ط¥ط²ط§ظ„ط© ط§ظ„ط±ط¨ط·', 'Remove assignment'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () => controller.removeAssignment(item['id'] as int),
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
    final name = TextEditingController(text: '${item?['name'] ?? ''}');
    final description =
        TextEditingController(text: '${item?['description'] ?? ''}');
    final amount =
        TextEditingController(text: '${item?['default_amount'] ?? ''}');
    String period = '${item?['billing_period'] ?? 'monthly'}';

    await Get.dialog(
      AlertDialog(
        title: Text(_t('ط¨ظٹط§ظ†ط§طھ ط§ظ„ط®ط¯ظ…ط©', 'Service details')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: _t('ط§ط³ظ… ط§ظ„ط®ط¯ظ…ط©', 'Name')),
              ),
              TextField(
                controller: description,
                decoration: InputDecoration(labelText: _t('ط§ظ„ظˆطµظپ', 'Description')),
              ),
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: _t('ط§ظ„ظ…ط¨ظ„ط؛ ط§ظ„ط§ظپطھط±ط§ط¶ظٹ', 'Default amount')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: period,
                decoration: InputDecoration(labelText: _t('ظپطھط±ط© ط§ظ„ظپظˆطھط±ط©', 'Billing period')),
                items: [
                  DropdownMenuItem(value: 'monthly', child: Text(_t('ط´ظ‡ط±ظٹ', 'Monthly'))),
                  DropdownMenuItem(value: 'one_time', child: Text(_t('ظ…ط±ط© ظˆط§ط­ط¯ط©', 'One time'))),
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
            child: Text(_t('ط¥ظ„ط؛ط§ط،', 'Cancel')),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text.trim());
              if (name.text.trim().isEmpty || value == null || !value.isFinite || value < 0) {
                Get.snackbar(
                  _t('طھظ†ط¨ظٹظ‡', 'Notice'),
                  _t('ط£ط¯ط®ظ„ظٹ ط§ط³ظ…ظ‹ط§ ظˆظ…ط¨ظ„ط؛ظ‹ط§ طµط­ظٹط­ظ‹ط§', 'Enter a valid name and amount'),
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
            child: Text(_t('ط­ظپط¸', 'Save')),
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
        _t('طھظ†ط¨ظٹظ‡', 'Notice'),
        _t('ط£ط¶ظٹظپظٹ ط¹ظ‚ط¯ظ‹ط§ ظˆط®ط¯ظ…ط© ظ†ط´ط·ط© ط£ظˆظ„ظ‹ط§', 'Add a contract and an active service first'),
      );
      return;
    }

    int contractId = controller.contracts.first['id'] as int;
    final availableServices =
        controller.services.where((item) => item['is_active'] == 1).toList();
    if (availableServices.isEmpty) {
      Get.snackbar(
        _t('طھظ†ط¨ظٹظ‡', 'Notice'),
        _t('ظ„ط§ طھظˆط¬ط¯ ط®ط¯ظ…ط§طھ ظ†ط´ط·ط©', 'There are no active services'),
      );
      return;
    }

    int serviceId = availableServices.first['id'] as int;
    final amount = TextEditingController(
      text: '${availableServices.first['default_amount'] ?? 0}',
    );

    await Get.dialog(
      AlertDialog(
        title: Text(_t('ط±ط¨ط· ط®ط¯ظ…ط© ط¨ط¹ظ‚ط¯', 'Assign service to contract')),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: contractId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: _t('ط§ظ„ط¹ظ‚ط¯', 'Contract')),
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
                    if (value != null) setState(() => contractId = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: serviceId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: _t('ط§ظ„ط®ط¯ظ…ط©', 'Service')),
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
                        amount.text = '${selected['default_amount'] ?? 0}';
                      });
                    }
                  },
                ),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: _t('ظ…ط¨ظ„ط؛ ط§ظ„ط®ط¯ظ…ط© ظ„ظ„ط¹ظ‚ط¯', 'Contract service amount')),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: Text(_t('ط¥ظ„ط؛ط§ط،', 'Cancel'))),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(amount.text.trim());
              if (value == null || !value.isFinite || value < 0) {
                Get.snackbar(
                  _t('طھظ†ط¨ظٹظ‡', 'Notice'),
                  _t('ط£ط¯ط®ظ„ظٹ ظ…ط¨ظ„ط؛ظ‹ط§ طµط­ظٹط­ظ‹ط§', 'Enter a valid amount'),
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
            child: Text(_t('ط±ط¨ط· ط§ظ„ط®ط¯ظ…ط©', 'Assign')),
          ),
        ],
      ),
    );

    amount.dispose();
  }
}
'@ | Set-Content -Encoding UTF8 $NewFiles[3]

    # Add route constant
    $RoutesPath = Join-Path $Project "lib\routes\app_routes.dart"
    $Routes = Get-Content $RoutesPath -Raw
    if ($Routes -notmatch "services\s*=") {
        $Routes = [regex]::Replace(
            $Routes,
            "\r?\n\}",
            "`r`n  static const services = '/services';`r`n}",
            1
        )
        Set-Content -Encoding UTF8 $RoutesPath $Routes
    }

    # Add route page and imports
    $PagesPath = Join-Path $Project "lib\routes\app_pages.dart"
    $Pages = Get-Content $PagesPath -Raw

    if ($Pages -notmatch "services_screen\.dart") {
        $Pages = $Pages.Replace(
            "import 'app_routes.dart';",
            "import '../features/services/presentation/bindings/services_binding.dart';`r`nimport '../features/services/presentation/screens/services_screen.dart';`r`nimport 'app_routes.dart';"
        )

        $Pages = [regex]::Replace(
            $Pages,
            "\r?\n\s*\];",
            "`r`n    GetPage(name: AppRoutes.services, page: () => const ServicesScreen(), binding: ServicesBinding()),`r`n  ];",
            1
        )
        Set-Content -Encoding UTF8 $PagesPath $Pages
    }

    # Ensure the route was inserted exactly once
    $RoutesCheck = Get-Content $RoutesPath -Raw
    $PagesCheck = Get-Content $PagesPath -Raw
    if ($RoutesCheck -notmatch "static const services") {
        throw "Could not register services route constant."
    }
    if ($PagesCheck -notmatch "ServicesScreen") {
        throw "Could not register services page."
    }

    # Format only changed/new Dart files
    dart format $NewFiles $FilesToBackup

    if ($LASTEXITCODE -ne 0) {
        throw "Dart formatting failed."
    }

    flutter analyze
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter analysis failed."
    }

    flutter test
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter tests failed."
    }

    Write-Host ""
    Write-Host "STAGE 4 SERVICES MODULE CREATED" -ForegroundColor Green
    Write-Host "Backup: $Backup" -ForegroundColor Cyan
    Write-Host "Files created:" -ForegroundColor Green
    $NewFiles | ForEach-Object { Write-Host "  $_" }
}
catch {
    Write-Host ""
    Write-Host "STAGE 4 FAILED - RESTORING CHANGES" -ForegroundColor Red

    foreach ($File in $FilesToBackup) {
        $Source = Join-Path $Backup $File
        if (Test-Path $Source) {
            Copy-Item $Source (Join-Path $Project $File) -Force
        }
    }

    foreach ($File in $NewFiles) {
        $FullPath = Join-Path $Project $File
        if (Test-Path $FullPath) {
            Remove-Item $FullPath -Force
        }
    }

    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "Original route files restored. Backup: $Backup" -ForegroundColor Yellow
    throw
}

