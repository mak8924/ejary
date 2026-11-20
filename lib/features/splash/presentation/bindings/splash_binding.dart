import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../pin/data/datasources/pin_local_data_source.dart';
import '../../../pin/data/repositories/pin_repository_impl.dart';
import '../../../pin/domain/repositories/pin_repository.dart';
import '../../data/repositories/startup_repository_impl.dart';
import '../../domain/repositories/startup_repository.dart';
import '../../domain/usecases/check_startup.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PinRepository>()) {
      Get.lazyPut<PinRepository>(
        () =>
            PinRepositoryImpl(PinLocalDataSource(const FlutterSecureStorage())),
      );
    }
    Get.lazyPut<StartupRepository>(
      () => StartupRepositoryImpl(Get.find<PinRepository>()),
    );
    Get.lazyPut(() => CheckStartup(Get.find<StartupRepository>()));
    Get.lazyPut(() => SplashController(Get.find<CheckStartup>()));
  }
}
