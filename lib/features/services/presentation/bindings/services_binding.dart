import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/services_repository.dart';
import '../controllers/services_controller.dart';

class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServicesRepository>(
      () => ServicesRepository(localDatabase: Get.find<LocalDatabase>()),
    );
    Get.lazyPut<ServicesController>(
      () => ServicesController(repository: Get.find<ServicesRepository>()),
    );
  }
}
