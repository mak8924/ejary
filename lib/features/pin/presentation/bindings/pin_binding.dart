import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../data/datasources/pin_local_data_source.dart';
import '../../data/repositories/pin_repository_impl.dart';
import '../../domain/repositories/pin_repository.dart';
import '../../domain/usecases/change_pin.dart';
import '../../domain/usecases/setup_pin.dart';
import '../../domain/usecases/verify_pin.dart';
import '../controllers/pin_controller.dart';

class PinBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PinRepository>()) {
      Get.lazyPut<PinRepository>(
        () =>
            PinRepositoryImpl(PinLocalDataSource(const FlutterSecureStorage())),
      );
    }
    Get.lazyPut(() => SetupPin(Get.find<PinRepository>()));
    Get.lazyPut(() => VerifyPin(Get.find<PinRepository>()));
    Get.lazyPut(() => ChangePin(Get.find<PinRepository>()));
    Get.lazyPut(
      () => PinController(
        setupPin: Get.find<SetupPin>(),
        verifyPin: Get.find<VerifyPin>(),
        changePin: Get.find<ChangePin>(),
      ),
    );
  }
}
