import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/tenant_contract_repository_impl.dart';
import '../../domain/repositories/tenant_contract_repository.dart';
import '../../domain/usecases/tenant_contract_use_cases.dart';
import '../controllers/tenant_contract_controller.dart';

class TenantContractBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TenantContractRepository>(
      () => TenantContractRepositoryImpl(
        localDatabase: Get.find<LocalDatabase>(),
      ),
    );

    Get.lazyPut<TenantContractUseCases>(
      () => TenantContractUseCases(Get.find<TenantContractRepository>()),
    );

    Get.lazyPut<TenantContractController>(
      () => TenantContractController(
        useCases: Get.find<TenantContractUseCases>(),
      ),
    );
  }
}
