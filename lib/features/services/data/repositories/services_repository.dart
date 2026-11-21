import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/services/contract_service_dues_sync.dart';

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
      final contract = await txn.query(
        'contracts',
        columns: ['status'],
        where: 'id = ?',
        whereArgs: [contractId],
        limit: 1,
      );

      if (contract.isEmpty || contract.first['status'] != 'active') {
        throw Exception('Services can only be assigned to active contracts.');
      }

      final service = await txn.query(
        'services',
        columns: ['id', 'is_active'],
        where: 'id = ?',
        whereArgs: [serviceId],
        limit: 1,
      );

      if (service.isEmpty || service.first['is_active'] != 1) {
        throw Exception('Selected service is unavailable.');
      }

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

      await ContractServiceDuesSync.sync(txn, contractId: contractId);
    });
  }

  Future<void> removeAssignment(int id) async {
    final db = _db;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'contract_services',
        columns: ['contract_id'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) return;

      final contractId = rows.first['contract_id'] as int;

      await txn.delete('contract_services', where: 'id = ?', whereArgs: [id]);

      await ContractServiceDuesSync.sync(txn, contractId: contractId);
    });
  }
}
