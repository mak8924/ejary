import '../entities/property_entities.dart';
import '../repositories/property_repository.dart';

class PropertyUseCases {
  final PropertyRepository repository;

  PropertyUseCases(this.repository);

  Future<List<PropertyEntity>> properties() => repository.getProperties();
  Future<int> addProperty(PropertyEntity value) =>
      repository.addProperty(value);
  Future<void> updateProperty(PropertyEntity value) =>
      repository.updateProperty(value);
  Future<void> deleteProperty(int id) => repository.deleteProperty(id);

  Future<List<DepartmentEntity>> departments(int id) =>
      repository.getDepartments(id);
  Future<int> addDepartment(DepartmentEntity value) =>
      repository.addDepartment(value);
  Future<void> updateDepartment(DepartmentEntity value) =>
      repository.updateDepartment(value);
  Future<void> deleteDepartment(int id) => repository.deleteDepartment(id);

  Future<List<UnitEntity>> units(int id) => repository.getUnits(id);
  Future<int> addUnit(UnitEntity value) => repository.addUnit(value);
  Future<void> updateUnit(UnitEntity value) => repository.updateUnit(value);
  Future<void> deleteUnit(int id) => repository.deleteUnit(id);
}
