import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/dues_payments_repository.dart';
import '../controllers/dues_payments_controller.dart';

class DuesPaymentsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DuesPaymentsRepository>(
      () => DuesPaymentsRepository(localDatabase: Get.find<LocalDatabase>()),
    );

    Get.lazyPut<DuesPaymentsController>(
      () => DuesPaymentsController(
        repository: Get.find<DuesPaymentsRepository>(),
      ),
    );
  }
}
