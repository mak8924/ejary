import 'package:sqflite/sqflite.dart';

class ContractServiceDuesSync {
  ContractServiceDuesSync._();

  static String _dateText(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static Future<void> sync(Transaction txn, {required int contractId}) async {
    final contracts = await txn.query(
      'contracts',
      columns: ['start_date', 'end_date', 'status'],
      where: 'id = ?',
      whereArgs: [contractId],
      limit: 1,
    );

    if (contracts.isEmpty || contracts.first['status'] != 'active') {
      return;
    }

    final start = DateTime.tryParse(
      contracts.first['start_date'] as String? ?? '',
    );
    final end = DateTime.tryParse(contracts.first['end_date'] as String? ?? '');

    if (start == null || end == null || end.isBefore(start)) {
      throw Exception('Invalid contract dates for service dues.');
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayText = _dateText(today);

    // Preserve paid and allocated records.
    final removable = await txn.rawQuery(
      '''
      SELECT d.id
      FROM dues d
      LEFT JOIN payment_allocations pa ON pa.due_id = d.id
      WHERE d.contract_id = ?
        AND d.description LIKE 'Service: %'
        AND d.due_date > ?
        AND LOWER(d.status) = 'unpaid'
        AND pa.id IS NULL
    ''',
      [contractId, todayText],
    );

    for (final row in removable) {
      await txn.delete('dues', where: 'id = ?', whereArgs: [row['id']]);
    }

    final assignments = await txn.rawQuery(
      '''
      SELECT cs.service_id, cs.amount, s.name, s.billing_period
      FROM contract_services cs
      INNER JOIN services s ON s.id = cs.service_id
      WHERE cs.contract_id = ?
      ORDER BY cs.id
    ''',
      [contractId],
    );

    for (final service in assignments) {
      final serviceId = service['service_id'] as int;
      final name = (service['name'] as String?) ?? 'Service';
      final amount = (service['amount'] as num?)?.toDouble();
      final period =
          (service['billing_period'] as String?)?.trim().toLowerCase() ??
          'monthly';

      if (amount == null || !amount.isFinite || amount < 0) {
        throw Exception('Invalid amount for service: $name');
      }

      if (period == 'one_time' || period == 'one-time' || period == 'once') {
        final dueDate = start.isAfter(today) ? start : today;
        final description = 'Service: $name [service:$serviceId] - one-time';

        await _insertIfMissing(
          txn,
          contractId,
          description,
          amount,
          _dateText(dueDate),
        );
        continue;
      }

      var month = DateTime(start.year, start.month);
      final lastMonth = DateTime(end.year, end.month);

      while (!month.isAfter(lastMonth)) {
        final lastDay = DateTime(month.year, month.month + 1, 0).day;
        final day = start.day > lastDay ? lastDay : start.day;
        final dueDate = DateTime(month.year, month.month, day);

        if (!dueDate.isAfter(end)) {
          final monthLabel =
              '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}';
          final description =
              'Service: $name [service:$serviceId] - $monthLabel';

          await _insertIfMissing(
            txn,
            contractId,
            description,
            amount,
            _dateText(dueDate),
          );
        }

        month = DateTime(month.year, month.month + 1);
      }
    }
  }

  static Future<void> _insertIfMissing(
    Transaction txn,
    int contractId,
    String description,
    double amount,
    String dueDate,
  ) async {
    final existing = await txn.query(
      'dues',
      columns: ['id'],
      where: 'contract_id = ? AND due_date = ? AND description = ?',
      whereArgs: [contractId, dueDate, description],
      limit: 1,
    );

    if (existing.isNotEmpty) return;

    await txn.insert('dues', {
      'contract_id': contractId,
      'description': description,
      'amount': amount,
      'due_date': dueDate,
      'status': 'unpaid',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
