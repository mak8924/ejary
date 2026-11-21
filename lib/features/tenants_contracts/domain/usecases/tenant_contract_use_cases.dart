import '../entities/tenant_entities.dart';
import '../repositories/tenant_contract_repository.dart';

class TenantContractUseCases {
  TenantContractUseCases(this.repository);

  final TenantContractRepository repository;

  Future<List<TenantEntity>> tenants() => repository.getTenants();
  Future<void> saveTenant(TenantEntity value) => repository.saveTenant(value);
  Future<void> deleteTenant(int id) => repository.deleteTenant(id);

  Future<List<UnitOption>> units() => repository.getUnits();
  Future<List<ContractEntity>> contracts() => repository.getContracts();
  Future<void> saveContract(ContractEntity value) =>
      repository.saveContract(value);
  Future<void> changeContractStatus(int id, String status) =>
      repository.changeContractStatus(id, status);
}
