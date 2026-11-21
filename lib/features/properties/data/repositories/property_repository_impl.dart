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

  Future<void> _ensurePropertyExists(int propertyId) async {
    final rows = await db.query(
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

  Future<void> _ensureUniquePropertyName(String name, {int? excludeId}) async {
    final rows = await db.query(
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
    int propertyId,
    String name, {
    int? excludeId,
  }) async {
    final rows = await db.query(
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

  Future<void> _validateUnit(UnitEntity unit) async {
    _requireText(unit.number, 'Unit number');
    _requireText(unit.type, 'Unit type');

    await _ensurePropertyExists(unit.propertyId);

    // floor and area are non-nullable fields in UnitEntity.
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
      final departmentRows = await db.query(
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

    final duplicateRows = await db.query(
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

    await _ensureUniquePropertyName(property.name);

    final now = DateTime.now().toIso8601String();

    return db.insert('properties', {
      'name': _clean(property.name),
      'property_type': property.type,
      'address': _clean(property.address),
      'description': _clean(property.description),
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateProperty(PropertyEntity property) async {
    _requireText(property.name, 'Property name');
    _requireText(property.type, 'Property type');

    await _ensureUniquePropertyName(property.name, excludeId: property.id);

    final count = await db.update(
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
  }

  @override
  Future<void> deleteProperty(int id) async {
    final unitRows = await db.query(
      'units',
      columns: ['id'],
      where: 'property_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    final departmentRows = await db.query(
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

    final count = await db.delete(
      'properties',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw StateError('Property was not found.');
    }
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

    await _ensurePropertyExists(department.propertyId);
    await _ensureUniqueDepartmentName(department.propertyId, department.name);

    return db.insert('departments', {
      'property_id': department.propertyId,
      'name': _clean(department.name),
      'description': _clean(department.description),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateDepartment(DepartmentEntity department) async {
    _requireText(department.name, 'Department name');

    await _ensureUniqueDepartmentName(
      department.propertyId,
      department.name,
      excludeId: department.id,
    );

    final count = await db.update(
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
  }

  @override
  Future<void> deleteDepartment(int id) async {
    final count = await db.delete(
      'departments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0) {
      throw StateError('Department was not found.');
    }
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
    await _validateUnit(unit);

    return db.insert('units', {
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
  }

  @override
  Future<void> updateUnit(UnitEntity unit) async {
    await _validateUnit(unit);

    final count = await db.update(
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
      whereArgs: [unit.id],
    );

    if (count == 0) {
      throw StateError('Unit was not found.');
    }
  }

  @override
  Future<void> deleteUnit(int id) async {
    final contractRows = await db.query(
      'contracts',
      columns: ['id'],
      where: 'unit_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (contractRows.isNotEmpty) {
      throw StateError('This unit has contract history and cannot be deleted.');
    }

    final count = await db.delete('units', where: 'id = ?', whereArgs: [id]);

    if (count == 0) {
      throw StateError('Unit was not found.');
    }
  }
}
