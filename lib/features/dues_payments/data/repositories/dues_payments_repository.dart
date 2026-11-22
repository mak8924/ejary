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

      if (paymentContractId != null && paymentContractId != dueContractId) {
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
      final paymentAllocated = (paymentAllocatedRows.first['total'] as num)
          .toDouble();
      final dueAllocated = (dueAllocatedRows.first['total'] as num).toDouble();

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
