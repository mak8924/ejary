import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../../domain/usecases/check_startup.dart';

class SplashController extends GetxController {
  SplashController(this.checkStartup);

  final CheckStartup checkStartup;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    try {
      final configured = await checkStartup();
      Get.offAllNamed(configured ? AppRoutes.pinVerify : AppRoutes.pinSetup);
    } catch (_) {
      Get.offAllNamed(AppRoutes.pinSetup);
    }
  }
}
