import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';

class AuditReportsRepository {
  AuditReportsRepository({required this.localDatabase});

  final LocalDatabase localDatabase;

  Database get _db => localDatabase.database;

  Future<List<Map<String, Object?>>> getAuditLogs({
    String search = '',
    String action = 'all',
    String entity = 'all',
  }) async {
    final conditions = <String>[];
    final arguments = <Object?>[];

    if (search.trim().isNotEmpty) {
      conditions.add(
        '(action LIKE ? OR entity_type LIKE ? OR description LIKE ? OR CAST(entity_id AS TEXT) LIKE ?)',
      );
      final value = '%${search.trim()}%';
      arguments.addAll([value, value, value, value]);
    }

    if (action != 'all') {
      conditions.add('UPPER(action) = ?');
      arguments.add(action.toUpperCase());
    }

    if (entity != 'all') {
      conditions.add('LOWER(entity_type) = ?');
      arguments.add(entity.toLowerCase());
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    return _db.rawQuery(
      'SELECT id, action, entity_type, entity_id, description, created_at '
      'FROM audit_logs $where ORDER BY created_at DESC, id DESC',
      arguments,
    );
  }

  Future<Map<String, num>> getReportSummary() async {
    Future<num> scalar(String sql) async {
      final rows = await _db.rawQuery(sql);
      final value = rows.first.values.first;
      return value is num ? value : 0;
    }

    final values = <String, num>{};

    values['properties'] =
        await scalar('SELECT COUNT(*) FROM properties');
    values['departments'] =
        await scalar('SELECT COUNT(*) FROM departments');
    values['units'] = await scalar('SELECT COUNT(*) FROM units');
    values['available'] = await scalar(
      "SELECT COUNT(*) FROM units WHERE LOWER(status) = 'available'",
    );
    values['occupied'] = await scalar(
      "SELECT COUNT(*) FROM units WHERE LOWER(status) = 'occupied'",
    );
    values['tenants'] = await scalar('SELECT COUNT(*) FROM tenants');
    values['contracts'] = await scalar('SELECT COUNT(*) FROM contracts');
    values['activeContracts'] = await scalar(
      "SELECT COUNT(*) FROM contracts WHERE LOWER(status) = 'active'",
    );
    values['dues'] = await scalar('SELECT COUNT(*) FROM dues');

    values['outstanding'] = await scalar('''
      SELECT COALESCE(SUM(
        CASE WHEN remaining > 0 THEN remaining ELSE 0 END
      ), 0)
      FROM (
        SELECT d.amount - COALESCE((
          SELECT SUM(pa.allocated_amount)
          FROM payment_allocations pa
          WHERE pa.due_id = d.id
        ), 0) AS remaining
        FROM dues d
      )
    ''');

    values['overdue'] = await scalar('''
      SELECT COALESCE(SUM(
        CASE WHEN remaining > 0 THEN remaining ELSE 0 END
      ), 0)
      FROM (
        SELECT d.amount - COALESCE((
          SELECT SUM(pa.allocated_amount)
          FROM payment_allocations pa
          WHERE pa.due_id = d.id
        ), 0) AS remaining,
        d.due_date
        FROM dues d
      )
      WHERE date(due_date) < date('now', 'localtime')
    ''');

    values['payments'] =
        await scalar('SELECT COALESCE(SUM(amount), 0) FROM payments');

    values['allocated'] = await scalar(
      'SELECT COALESCE(SUM(allocated_amount), 0) FROM payment_allocations',
    );

    values['unallocated'] = await scalar('''
      SELECT COALESCE(SUM(
        CASE WHEN remaining > 0 THEN remaining ELSE 0 END
      ), 0)
      FROM (
        SELECT p.amount - COALESCE((
          SELECT SUM(pa.allocated_amount)
          FROM payment_allocations pa
          WHERE pa.payment_id = p.id
        ), 0) AS remaining
        FROM payments p
      )
    ''');

    return values;
  }
}