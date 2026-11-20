import 'package:get/get.dart';
import '../features/splash/presentation/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/pin/presentation/bindings/pin_binding.dart';
import '../features/pin/presentation/screens/pin_setup_screen.dart';
import '../features/pin/presentation/screens/pin_verify_screen.dart';
import '../features/pin/presentation/screens/pin_change_screen.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/screens/home_screen.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.pinSetup,
      page: () => const PinSetupScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.pinVerify,
      page: () => const PinVerifyScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.pinChange,
      page: () => const PinChangeScreen(),
      binding: PinBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
  ];
}
