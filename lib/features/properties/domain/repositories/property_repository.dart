import '../entities/property_entities.dart';

abstract class PropertyRepository {
  Future<List<PropertyEntity>> getProperties();
  Future<int> addProperty(PropertyEntity property);
  Future<void> updateProperty(PropertyEntity property);
  Future<void> deleteProperty(int id);

  Future<List<DepartmentEntity>> getDepartments(int propertyId);
  Future<int> addDepartment(DepartmentEntity department);
  Future<void> updateDepartment(DepartmentEntity department);
  Future<void> deleteDepartment(int id);

  Future<List<UnitEntity>> getUnits(int propertyId);
  Future<int> addUnit(UnitEntity unit);
  Future<void> updateUnit(UnitEntity unit);
  Future<void> deleteUnit(int id);
}
