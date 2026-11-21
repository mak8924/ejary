import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';
import '../../domain/entities/tenant_entities.dart';
import '../../domain/repositories/tenant_contract_repository.dart';

class TenantContractRepositoryImpl implements TenantContractRepository {
  TenantContractRepositoryImpl({required this.localDatabase});

  final LocalDatabase localDatabase;

  Database get db => localDatabase.database;

  @override
  Future<List<TenantEntity>> getTenants() async {
    final rows = await db.query('tenants', orderBy: 'full_name COLLATE NOCASE');
    return rows.map(TenantEntity.fromMap).toList();
  }

  @override
  Future<void> saveTenant(TenantEntity tenant) async {
    final values = {
      'full_name': tenant.fullName.trim(),
      'phone': tenant.phone.trim(),
      'email': tenant.email.trim(),
      'national_id': tenant.nationalId.trim(),
      'address': tenant.address.trim(),
      'notes': tenant.notes.trim(),
    };

    if (tenant.fullName.trim().isEmpty) {
      throw Exception('Tenant name is required.');
    }

    if (tenant.id == null) {
      final id = await db.insert('tenants', {
        ...values,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _audit(
        'CREATE',
        'tenant',
        id,
        'Tenant created: ${tenant.fullName}',
      );
    } else {
      await db.update(
        'tenants',
        values,
        where: 'id = ?',
        whereArgs: [tenant.id],
      );
      await _audit(
        'UPDATE',
        'tenant',
        tenant.id!,
        'Tenant updated: ${tenant.fullName}',
      );
    }
  }

  @override
  Future<void> deleteTenant(int id) async {
    final contracts = await db.query(
      'contracts',
      columns: ['id'],
      where: 'tenant_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (contracts.isNotEmpty) {
      throw Exception(
        'This tenant has contract history and cannot be deleted. Archive or retain the tenant instead.',
      );
    }

    await db.delete('tenants', where: 'id = ?', whereArgs: [id]);
    await _audit('DELETE', 'tenant', id, 'Tenant deleted');
  }

  @override
  Future<List<UnitOption>> getUnits() async {
    final rows = await db.rawQuery('''
      SELECT
        u.id,
        u.unit_number || ' - ' || p.name AS label,
        u.monthly_rent,
        u.status
      FROM units u
      INNER JOIN properties p ON p.id = u.property_id
      ORDER BY p.name, u.unit_number
    ''');

    return rows.map(UnitOption.fromMap).toList();
  }

  @override
  Future<List<ContractEntity>> getContracts() async {
    final rows = await db.rawQuery('''
      SELECT
        c.*,
        t.full_name AS tenant_name,
        u.unit_number || ' - ' || p.name AS unit_label
      FROM contracts c
      INNER JOIN tenants t ON t.id = c.tenant_id
      INNER JOIN units u ON u.id = c.unit_id
      INNER JOIN properties p ON p.id = u.property_id
      ORDER BY c.id DESC
    ''');

    return rows.map(ContractEntity.fromMap).toList();
  }

  @override
  Future<void> saveContract(ContractEntity contract) async {
    if (contract.startDate.compareTo(contract.endDate) > 0) {
      throw Exception('The contract end date must be after the start date.');
    }

    if (contract.monthlyRent < 0 || contract.depositAmount < 0) {
      throw Exception('Rent and deposit cannot be negative.');
    }

    await db.transaction((txn) async {
      final conflicts = await txn.rawQuery(
        '''
        SELECT id FROM contracts
        WHERE unit_id = ?
          AND status = 'active'
          AND start_date <= ?
          AND end_date >= ?
          AND (? IS NULL OR id != ?)
        LIMIT 1
      ''',
        [
          contract.unitId,
          contract.endDate,
          contract.startDate,
          contract.id,
          contract.id,
        ],
      );

      if (conflicts.isNotEmpty) {
        throw Exception(
          'This unit already has an overlapping active contract.',
        );
      }

      final values = {
        'tenant_id': contract.tenantId,
        'unit_id': contract.unitId,
        'start_date': contract.startDate,
        'end_date': contract.endDate,
        'monthly_rent': contract.monthlyRent,
        'deposit_amount': contract.depositAmount,
        'notes': contract.notes,
      };

      if (contract.id == null) {
        final number = 'EJ-${DateTime.now().millisecondsSinceEpoch}';
        final id = await txn.insert('contracts', {
          ...values,
          'contract_number': number,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });

        await txn.insert('audit_logs', {
          'action': 'CREATE',
          'entity_type': 'contract',
          'entity_id': id,
          'description': 'Contract $number created',
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        await txn.update(
          'contracts',
          values,
          where: 'id = ?',
          whereArgs: [contract.id],
        );

        await txn.insert('audit_logs', {
          'action': 'UPDATE',
          'entity_type': 'contract',
          'entity_id': contract.id,
          'description': 'Contract ${contract.contractNumber} updated',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      await _syncUnitStatus(txn, contract.unitId);
    });
  }

  @override
  Future<void> changeContractStatus(int id, String status) async {
    const allowed = ['terminated', 'archived'];
    if (!allowed.contains(status)) {
      throw Exception('Unsupported contract status.');
    }

    await db.transaction((txn) async {
      final rows = await txn.query(
        'contracts',
        columns: ['unit_id', 'contract_number'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) throw Exception('Contract not found.');

      final unitId = rows.first['unit_id'] as int;
      final number = rows.first['contract_number'] as String;

      await txn.update(
        'contracts',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );

      await txn.insert('audit_logs', {
        'action': status.toUpperCase(),
        'entity_type': 'contract',
        'entity_id': id,
        'description': 'Contract $number $status',
        'created_at': DateTime.now().toIso8601String(),
      });

      await _syncUnitStatus(txn, unitId);
    });
  }

  Future<void> _syncUnitStatus(Transaction txn, int unitId) async {
    final unitRows = await txn.query(
      'units',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [unitId],
    );

    if (unitRows.isEmpty) return;

    final currentStatus = unitRows.first['status'] as String;

    // Do not overwrite statuses such as maintenance or unavailable.
    if (currentStatus != 'available' && currentStatus != 'rented') return;

    final activeRows = await txn.rawQuery(
      '''
      SELECT id FROM contracts
      WHERE unit_id = ?
        AND status = 'active'
        AND date('now') BETWEEN date(start_date) AND date(end_date)
      LIMIT 1
    ''',
      [unitId],
    );

    await txn.update(
      'units',
      {'status': activeRows.isEmpty ? 'available' : 'rented'},
      where: 'id = ?',
      whereArgs: [unitId],
    );
  }

  Future<void> _audit(
    String action,
    String entity,
    int id,
    String description,
  ) async {
    await db.insert('audit_logs', {
      'action': action,
      'entity_type': entity,
      'entity_id': id,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
