import 'package:sqflite/sqflite.dart';

import '../../../../core/database/local_database.dart';
import '../../domain/entities/property_entities.dart';
import '../../domain/repositories/property_repository.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final LocalDatabase localDatabase;

  PropertyRepositoryImpl({required this.localDatabase});

  Database get db => localDatabase.database;

  @override
  Future<List<PropertyEntity>> getProperties() async {
    final rows = await db.query('properties', orderBy: 'id DESC');
    return rows.map(PropertyEntity.fromMap).toList();
  }

  @override
  Future<int> addProperty(PropertyEntity property) {
    final now = DateTime.now().toIso8601String();
    return db.insert('properties', {
      'name': property.name,
      'property_type': property.type,
      'address': property.address,
      'description': property.description,
      'created_at': now,
      'updated_at': now,
    });
  }

  @override
  Future<void> updateProperty(PropertyEntity property) async {
    await db.update(
      'properties',
      {
        'name': property.name,
        'property_type': property.type,
        'address': property.address,
        'description': property.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [property.id],
    );
  }

  @override
  Future<void> deleteProperty(int id) async {
    await db.delete('properties', where: 'id = ?', whereArgs: [id]);
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
  Future<int> addDepartment(DepartmentEntity department) {
    return db.insert('departments', {
      'property_id': department.propertyId,
      'name': department.name,
      'description': department.description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateDepartment(DepartmentEntity department) async {
    await db.update(
      'departments',
      {'name': department.name, 'description': department.description},
      where: 'id = ?',
      whereArgs: [department.id],
    );
  }

  @override
  Future<void> deleteDepartment(int id) async {
    await db.delete('departments', where: 'id = ?', whereArgs: [id]);
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
  Future<int> addUnit(UnitEntity unit) {
    return db.insert('units', {
      'property_id': unit.propertyId,
      'department_id': unit.departmentId,
      'unit_number': unit.number,
      'unit_type': unit.type,
      'floor_number': unit.floor,
      'area': unit.area,
      'monthly_rent': unit.rent,
      'status': unit.status,
      'description': unit.description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateUnit(UnitEntity unit) async {
    await db.update(
      'units',
      {
        'department_id': unit.departmentId,
        'unit_number': unit.number,
        'unit_type': unit.type,
        'floor_number': unit.floor,
        'area': unit.area,
        'monthly_rent': unit.rent,
        'status': unit.status,
        'description': unit.description,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  @override
  Future<void> deleteUnit(int id) async {
    await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }
}
