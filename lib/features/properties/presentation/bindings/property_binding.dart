import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/property_repository_impl.dart';
import '../../domain/repositories/property_repository.dart';
import '../../domain/usecases/property_use_cases.dart';
import '../controllers/property_controller.dart';

class PropertyBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PropertyRepository>(
      () => PropertyRepositoryImpl(localDatabase: Get.find<LocalDatabase>()),
    );
    Get.lazyPut<PropertyUseCases>(
      () => PropertyUseCases(Get.find<PropertyRepository>()),
    );
    Get.lazyPut<PropertyController>(
      () => PropertyController(useCases: Get.find<PropertyUseCases>()),
    );
  }
}
