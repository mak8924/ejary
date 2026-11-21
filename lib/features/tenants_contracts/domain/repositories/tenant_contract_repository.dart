import '../entities/tenant_entities.dart';

abstract class TenantContractRepository {
  Future<List<TenantEntity>> getTenants();
  Future<void> saveTenant(TenantEntity tenant);
  Future<void> deleteTenant(int id);

  Future<List<UnitOption>> getUnits();
  Future<List<ContractEntity>> getContracts();
  Future<void> saveContract(ContractEntity contract);
  Future<void> changeContractStatus(int id, String status);
}
