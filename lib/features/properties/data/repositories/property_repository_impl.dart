import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';
import '../../domain/entities/property_entities.dart';
import '../../domain/repositories/property_repository.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final LocalDatabase localDatabase;

  PropertyRepositoryImpl({required this.localDatabase});

  Database get db => localDatabase.database;

  String _clean(String value) => value.trim();

  void _requireText(String value, String field) {
    if (_clean(value).isEmpty) {
      throw ArgumentError('$field is required.');
    }
  }

  Future<void> _writeAudit(
    DatabaseExecutor executor, {
    required String action,
    required String entityType,
    required int? entityId,
    required String description,
  }) async {
    await executor.insert('audit_logs', {
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _ensurePropertyExists(
    DatabaseExecutor executor,
    int propertyId,
  ) async {
    final rows = await executor.query(
      'properties',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [propertyId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw StateError('The selected property does not exist.');
    }
  }

  Future<void> _ensureUniquePropertyName(
    DatabaseExecutor executor,
    String name, {
    int? excludeId,
  }) async {
    final rows = await executor.query(
      'properties',
      columns: ['id'],
      where: excludeId == null
          ? 'LOWER(TRIM(name)) = LOWER(TRIM(?))'
          : 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND id != ?',
      whereArgs: excludeId == null ? [name] : [name, excludeId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      throw StateError('A property with this name already exists.');
    }
  }

  Future<void> _ensureUniqueDepartmentName(
    DatabaseExecutor executor,
    int propertyId,
    String name, {
    int? excludeId,
  }) async {
    final rows = await executor.query(
      'departments',
      columns: ['id'],
      where: excludeId == null
          ? 'property_id = ? AND LOWER(TRIM(name)) = LOWER(TRIM(?))'
          : 'property_id = ? AND LOWER(TRIM(name)) = LOWER(TRIM(?)) AND id != ?',
      whereArgs: excludeId == null
          ? [propertyId, name]
          : [propertyId, name, excludeId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      throw StateError('A department with this name already exists.');
    }
  }

  Future<void> _validateUnit(DatabaseExecutor executor, UnitEntity unit) async {
    _requireText(unit.number, 'Unit number');
    _requireText(unit.type, 'Unit type');

    await _ensurePropertyExists(executor, unit.propertyId);

    if (unit.floor < 0) {
      throw ArgumentError('Floor number cannot be negative.');
    }

    if (unit.area <= 0) {
      throw ArgumentError('Area must be greater than zero.');
    }

    if (unit.rent < 0) {
      throw ArgumentError('Monthly rent cannot be negative.');
    }

    const allowedStatuses = {'available', 'occupied', 'maintenance'};

    if (!allowedStatuses.contains(unit.status)) {
      throw ArgumentError('Invalid unit status.');
    }

    if (unit.departmentId != null) {
      final departmentRows = await executor.query(
        'departments',
        columns: ['id'],
        where: 'id = ? AND property_id = ?',
        whereArgs: [unit.departmentId, unit.propertyId],
        limit: 1,
      );

      if (departmentRows.isEmpty) {
        throw StateError(
          'The selected department does not belong to this property.',
        );
      }
    }

    final duplicateRows = await executor.query(
      'units',
      columns: ['id'],
      where: unit.id == null
          ? 'property_id = ? AND LOWER(TRIM(unit_number)) = LOWER(TRIM(?))'
          : 'property_id = ? AND LOWER(TRIM(unit_number)) = LOWER(TRIM(?)) AND id != ?',
      whereArgs: unit.id == null
          ? [unit.propertyId, unit.number]
          : [unit.propertyId, unit.number, unit.id],
      limit: 1,
    );

    if (duplicateRows.isNotEmpty) {
      throw StateError('This unit number already exists in this property.');
    }
  }

  @override
  Future<List<PropertyEntity>> getProperties() async {
    final rows = await db.query('properties', orderBy: 'id DESC');

    return rows.map(PropertyEntity.fromMap).toList();
  }

  @override
  Future<int> addProperty(PropertyEntity property) async {
    _requireText(property.name, 'Property name');
    _requireText(property.type, 'Property type');

    return db.transaction((txn) async {
      await _ensureUniquePropertyName(txn, property.name);

      final now = DateTime.now().toIso8601String();

      final propertyId = await txn.insert('properties', {
        'name': _clean(property.name),
        'property_type': property.type,
        'address': _clean(property.address),
        'description': _clean(property.description),
        'created_at': now,
        'updated_at': now,
      });

      await _writeAudit(
        txn,
        action: 'CREATE',
        entityType: 'property',
        entityId: propertyId,
        description: 'Created property: ${_clean(property.name)}',
      );

      return propertyId;
    });
  }

  @override
  Future<void> updateProperty(PropertyEntity property) async {
    _requireText(property.name, 'Property name');
    _requireText(property.type, 'Property type');

    await db.transaction((txn) async {
      await _ensureUniquePropertyName(
        txn,
        property.name,
        excludeId: property.id,
      );

      final count = await txn.update(
        'properties',
        {
          'name': _clean(property.name),
          'property_type': property.type,
          'address': _clean(property.address),
          'description': _clean(property.description),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [property.id],
      );

      if (count == 0) {
        throw StateError('Property was not found.');
      }

      await _writeAudit(
        txn,
        action: 'UPDATE',
        entityType: 'property',
        entityId: property.id,
        description: 'Updated property: ${_clean(property.name)}',
      );
    });
  }

  @override
  Future<void> deleteProperty(int id) async {
    await db.transaction((txn) async {
      final propertyRows = await txn.query(
        'properties',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final unitRows = await txn.query(
        'units',
        columns: ['id'],
        where: 'property_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final departmentRows = await txn.query(
        'departments',
        columns: ['id'],
        where: 'property_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (unitRows.isNotEmpty || departmentRows.isNotEmpty) {
        throw StateError(
          'Delete the property departments and units before deleting the property.',
        );
      }

      final count = await txn.delete(
        'properties',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw StateError('Property was not found.');
      }

      final propertyName = propertyRows.isNotEmpty
          ? propertyRows.first['name']
          : 'ID $id';

      await _writeAudit(
        txn,
        action: 'DELETE',
        entityType: 'property',
        entityId: id,
        description: 'Deleted property: $propertyName',
      );
    });
  }

  @override
  Future<List<DepartmentEntity>> getDepartments(int propertyId) async {
    final rows = await db.query(
      'departments',
      where: 'property_id = ?',
      whereArgs: [propertyId],
      orderBy: 'id DESC',
    );

    return rows.map(DepartmentEntity.fromMap).toList();
  }

  @override
  Future<int> addDepartment(DepartmentEntity department) async {
    _requireText(department.name, 'Department name');

    return db.transaction((txn) async {
      await _ensurePropertyExists(txn, department.propertyId);
      await _ensureUniqueDepartmentName(
        txn,
        department.propertyId,
        department.name,
      );

      final departmentId = await txn.insert('departments', {
        'property_id': department.propertyId,
        'name': _clean(department.name),
        'description': _clean(department.description),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _writeAudit(
        txn,
        action: 'CREATE',
        entityType: 'department',
        entityId: departmentId,
        description:
            'Created department: ${_clean(department.name)} '
            'in property ID ${department.propertyId}',
      );

      return departmentId;
    });
  }

  @override
  Future<void> updateDepartment(DepartmentEntity department) async {
    _requireText(department.name, 'Department name');

    await db.transaction((txn) async {
      await _ensureUniqueDepartmentName(
        txn,
        department.propertyId,
        department.name,
        excludeId: department.id,
      );

      final count = await txn.update(
        'departments',
        {
          'name': _clean(department.name),
          'description': _clean(department.description),
        },
        where: 'id = ?',
        whereArgs: [department.id],
      );

      if (count == 0) {
        throw StateError('Department was not found.');
      }

      await _writeAudit(
        txn,
        action: 'UPDATE',
        entityType: 'department',
        entityId: department.id,
        description: 'Updated department: ${_clean(department.name)}',
      );
    });
  }

  @override
  Future<void> deleteDepartment(int id) async {
    await db.transaction((txn) async {
      final rows = await txn.query(
        'departments',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final count = await txn.delete(
        'departments',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (count == 0) {
        throw StateError('Department was not found.');
      }

      final departmentName = rows.isNotEmpty ? rows.first['name'] : 'ID $id';

      await _writeAudit(
        txn,
        action: 'DELETE',
        entityType: 'department',
        entityId: id,
        description: 'Deleted department: $departmentName',
      );
    });
  }

  @override
  Future<List<UnitEntity>> getUnits(int propertyId) async {
    final rows = await db.query(
      'units',
      where: 'property_id = ?',
      whereArgs: [propertyId],
      orderBy: 'id DESC',
    );

    return rows.map(UnitEntity.fromMap).toList();
  }

  @override
  Future<int> addUnit(UnitEntity unit) async {
    return db.transaction((txn) async {
      await _validateUnit(txn, unit);

      final unitId = await txn.insert('units', {
        'property_id': unit.propertyId,
        'department_id': unit.departmentId,
        'unit_number': _clean(unit.number),
        'unit_type': unit.type,
        'floor_number': unit.floor,
        'area': unit.area,
        'monthly_rent': unit.rent,
        'status': unit.status,
        'description': _clean(unit.description),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _writeAudit(
        txn,
        action: 'CREATE',
        entityType: 'unit',
        entityId: unitId,
        description:
            'Created unit ${_clean(unit.number)} '
            'in property ID ${unit.propertyId}',
      );

      return unitId;
    });
  }

  @override
  Future<void> updateUnit(UnitEntity unit) async {
    final unitId = unit.id;

    if (unitId == null) {
      throw StateError('Unit was not found.');
    }

    await db.transaction((txn) async {
      await _validateUnit(txn, unit);

      final count = await txn.update(
        'units',
        {
          'department_id': unit.departmentId,
          'unit_number': _clean(unit.number),
          'unit_type': unit.type,
          'floor_number': unit.floor,
          'area': unit.area,
          'monthly_rent': unit.rent,
          'status': unit.status,
          'description': _clean(unit.description),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [unitId],
      );

      if (count == 0) {
        throw StateError('Unit was not found.');
      }

      await _writeAudit(
        txn,
        action: 'UPDATE',
        entityType: 'unit',
        entityId: unitId,
        description: 'Updated unit: ${_clean(unit.number)}',
      );
    });
  }

  @override
  Future<void> deleteUnit(int id) async {
    await db.transaction((txn) async {
      final unitRows = await txn.query(
        'units',
        columns: ['unit_number'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      final contractRows = await txn.query(
        'contracts',
        columns: ['id'],
        where: 'unit_id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (contractRows.isNotEmpty) {
        throw StateError(
          'This unit has contract history and cannot be deleted.',
        );
      }

      final count = await txn.delete('units', where: 'id = ?', whereArgs: [id]);

      if (count == 0) {
        throw StateError('Unit was not found.');
      }

      final unitNumber = unitRows.isNotEmpty
          ? unitRows.first['unit_number']
          : 'ID $id';

      await _writeAudit(
        txn,
        action: 'DELETE',
        entityType: 'unit',
        entityId: id,
        description: 'Deleted unit: $unitNumber',
      );
    });
  }
}
