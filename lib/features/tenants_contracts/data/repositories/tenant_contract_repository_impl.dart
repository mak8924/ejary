import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/services/contract_service_dues_sync.dart';
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
    final name = tenant.fullName.trim();

    if (name.isEmpty) {
      throw Exception('Tenant name is required.');
    }

    final values = {
      'full_name': name,
      'phone': tenant.phone.trim(),
      'email': tenant.email.trim(),
      'national_id': tenant.nationalId.trim(),
      'address': tenant.address.trim(),
      'notes': tenant.notes.trim(),
    };

    await db.transaction((txn) async {
      if (tenant.id == null) {
        final id = await txn.insert('tenants', {
          ...values,
          'created_at': DateTime.now().toIso8601String(),
        });

        await _audit(txn, 'CREATE', 'tenant', id, 'Tenant created: $name');
      } else {
        final affected = await txn.update(
          'tenants',
          values,
          where: 'id = ?',
          whereArgs: [tenant.id],
        );

        if (affected == 0) {
          throw Exception('Tenant not found.');
        }

        await _audit(
          txn,
          'UPDATE',
          'tenant',
          tenant.id!,
          'Tenant updated: $name',
        );
      }
    });
  }

  @override
  Future<void> deleteTenant(int id) async {
    await db.transaction((txn) async {
      final contracts = await txn.query(
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

      final affected = await txn.delete(
        'tenants',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (affected == 0) {
        throw Exception('Tenant not found.');
      }

      await _audit(txn, 'DELETE', 'tenant', id, 'Tenant deleted');
    });
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
    final start = DateTime.tryParse(contract.startDate);
    final end = DateTime.tryParse(contract.endDate);

    if (start == null || end == null) {
      throw Exception('Enter valid contract dates.');
    }

    if (end.isBefore(start)) {
      throw Exception('The contract end date must be after the start date.');
    }

    if (!contract.monthlyRent.isFinite ||
        contract.monthlyRent <= 0 ||
        !contract.depositAmount.isFinite ||
        contract.depositAmount < 0) {
      throw Exception('Enter valid rent and deposit amounts.');
    }

    await db.transaction((txn) async {
      final tenant = await txn.query(
        'tenants',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [contract.tenantId],
        limit: 1,
      );

      if (tenant.isEmpty) {
        throw Exception('Tenant not found.');
      }

      final unit = await txn.query(
        'units',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [contract.unitId],
        limit: 1,
      );

      if (unit.isEmpty) {
        throw Exception('Unit not found.');
      }

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

      int? previousUnitId;
      late int contractId;

      if (contract.id == null) {
        final number = 'EJ-${DateTime.now().millisecondsSinceEpoch}';

        final id = await txn.insert('contracts', {
          ...values,
          'contract_number': number,
          'status': 'active',
          'created_at': DateTime.now().toIso8601String(),
        });

        contractId = id;
        await _audit(txn, 'CREATE', 'contract', id, 'Contract $number created');
      } else {
        final oldRows = await txn.query(
          'contracts',
          columns: ['unit_id'],
          where: 'id = ?',
          whereArgs: [contract.id],
          limit: 1,
        );

        if (oldRows.isEmpty) {
          throw Exception('Contract not found.');
        }

        previousUnitId = oldRows.first['unit_id'] as int;
        contractId = contract.id!;

        final affected = await txn.update(
          'contracts',
          values,
          where: 'id = ?',
          whereArgs: [contract.id],
        );

        if (affected == 0) {
          throw Exception('Contract not found.');
        }

        await _audit(
          txn,
          'UPDATE',
          'contract',
          contract.id!,
          'Contract ${contract.contractNumber} updated',
        );
      }

      await _syncMonthlyDues(txn, contractId, start, end, contract.monthlyRent);

      if (previousUnitId != null && previousUnitId != contract.unitId) {
        await _syncUnitStatus(txn, previousUnitId);
      }

      await _syncUnitStatus(txn, contract.unitId);
    });
  }

  @override
  Future<void> changeContractStatus(int id, String status) async {
    const allowed = ['active', 'terminated', 'archived'];

    if (!allowed.contains(status)) {
      throw Exception('Unsupported contract status.');
    }

    await db.transaction((txn) async {
      final rows = await txn.query(
        'contracts',
        columns: [
          'unit_id',
          'contract_number',
          'start_date',
          'end_date',
          'monthly_rent',
        ],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Contract not found.');
      }

      final row = rows.first;
      final unitId = row['unit_id'] as int;
      final number = row['contract_number'] as String;

      if (status == 'active') {
        final conflicts = await txn.rawQuery(
          '''
          SELECT id FROM contracts
          WHERE unit_id = ?
            AND status = 'active'
            AND start_date <= ?
            AND end_date >= ?
            AND id != ?
          LIMIT 1
          ''',
          [unitId, row['end_date'], row['start_date'], id],
        );

        if (conflicts.isNotEmpty) {
          throw Exception(
            'This unit already has an overlapping active contract.',
          );
        }
      }

      await txn.update(
        'contracts',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );

      await _audit(
        txn,
        status.toUpperCase(),
        'contract',
        id,
        'Contract $number $status',
      );

      if (status == 'active') {
        final start = DateTime.tryParse(row['start_date'] as String? ?? '');
        final end = DateTime.tryParse(row['end_date'] as String? ?? '');
        final rent = (row['monthly_rent'] as num?)?.toDouble();

        if (start != null && end != null && rent != null) {
          await _syncMonthlyDues(txn, id, start, end, rent);
        }
      } else {
        await _removeFutureUnallocatedDues(txn, id);
      }

      await _syncUnitStatus(txn, unitId);
    });
  }

  Future<void> _syncMonthlyDues(
    Transaction txn,
    int contractId,
    DateTime start,
    DateTime end,
    double monthlyRent,
  ) async {
    final contractRows = await txn.query(
      'contracts',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [contractId],
      limit: 1,
    );

    if (contractRows.isEmpty || contractRows.first['status'] != 'active') {
      return;
    }

    if (!monthlyRent.isFinite || monthlyRent <= 0) {
      throw Exception('Invalid monthly rent for automatic dues.');
    }

    await _removeFutureUnallocatedDues(txn, contractId);

    final firstMonth = DateTime(start.year, start.month);
    final lastMonth = DateTime(end.year, end.month);

    var month = firstMonth;

    while (!month.isAfter(lastMonth)) {
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final day = start.day > lastDay ? lastDay : start.day;
      final dueDate = DateTime(month.year, month.month, day);

      if (!dueDate.isAfter(end)) {
        final dateText =
            '${dueDate.year.toString().padLeft(4, '0')}-'
            '${dueDate.month.toString().padLeft(2, '0')}-'
            '${dueDate.day.toString().padLeft(2, '0')}';

        final monthLabel =
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}';
        final description = 'Monthly rent - $monthLabel';

        final existing = await txn.query(
          'dues',
          columns: ['id'],
          where: 'contract_id = ? AND due_date = ? AND description = ?',
          whereArgs: [contractId, dateText, description],
          limit: 1,
        );

        if (existing.isEmpty) {
          await txn.insert('dues', {
            'contract_id': contractId,
            'description': description,
            'amount': monthlyRent,
            'due_date': dateText,
            'status': 'unpaid',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }

      month = DateTime(month.year, month.month + 1);
    }

    await ContractServiceDuesSync.sync(txn, contractId: contractId);
  }

  Future<void> _removeFutureUnallocatedDues(
    Transaction txn,
    int contractId,
  ) async {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final rows = await txn.rawQuery(
      '''
      SELECT d.id
      FROM dues d
      LEFT JOIN payment_allocations pa ON pa.due_id = d.id
      WHERE d.contract_id = ?
        AND d.due_date > ?
        AND LOWER(d.status) = 'unpaid'
        AND pa.id IS NULL
        AND (
          d.description LIKE 'Monthly rent - %'
          OR d.description LIKE 'Service: %'
        )
      ''',
      [contractId, today],
    );

    for (final row in rows) {
      await txn.delete('dues', where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  Future<void> _syncUnitStatus(Transaction txn, int unitId) async {
    final unitRows = await txn.query(
      'units',
      columns: ['status'],
      where: 'id = ?',
      whereArgs: [unitId],
      limit: 1,
    );

    if (unitRows.isEmpty) return;

    final currentStatus = unitRows.first['status'] as String;

    // Keep maintenance and other manually assigned statuses unchanged.
    if (currentStatus != 'available' &&
        currentStatus != 'occupied' &&
        currentStatus != 'rented') {
      return;
    }

    final activeRows = await txn.rawQuery(
      '''
      SELECT id FROM contracts
      WHERE unit_id = ?
        AND status = 'active'
        AND date('now', 'localtime')
            BETWEEN date(start_date) AND date(end_date)
      LIMIT 1
      ''',
      [unitId],
    );

    await txn.update(
      'units',
      {'status': activeRows.isEmpty ? 'available' : 'occupied'},
      where: 'id = ?',
      whereArgs: [unitId],
    );
  }

  Future<void> _audit(
    Transaction txn,
    String action,
    String entity,
    int id,
    String description,
  ) async {
    await txn.insert('audit_logs', {
      'action': action,
      'entity_type': entity,
      'entity_id': id,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
