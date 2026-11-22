import 'package:get/get.dart';

import '../features/splash/presentation/bindings/splash_binding.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/pin/presentation/bindings/pin_binding.dart';
import '../features/pin/presentation/screens/pin_setup_screen.dart';
import '../features/pin/presentation/screens/pin_verify_screen.dart';
import '../features/pin/presentation/screens/pin_change_screen.dart';
import '../features/home/presentation/bindings/home_binding.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/properties/presentation/bindings/property_binding.dart';
import '../features/properties/presentation/screens/property_screen.dart';
import '../features/tenants_contracts/presentation/bindings/tenant_contract_binding.dart';
import '../features/tenants_contracts/presentation/screens/tenant_contract_screen.dart';
import '../features/services/presentation/bindings/services_binding.dart';
import '../features/services/presentation/screens/services_screen.dart';
import '../features/dues_payments/presentation/bindings/dues_payments_binding.dart';
import '../features/dues_payments/presentation/screens/dues_payments_screen.dart';
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
    GetPage(
      name: AppRoutes.properties,
      page: () => const PropertyScreen(),
      binding: PropertyBinding(),
    ),
    GetPage(
      name: AppRoutes.tenantContracts,
      page: () => const TenantContractScreen(),
      binding: TenantContractBinding(),
    ),
    GetPage(
      name: AppRoutes.services,
      page: () => const ServicesScreen(),
      binding: ServicesBinding(),
    ),
    GetPage(
      name: AppRoutes.duesPayments,
      page: () => const DuesPaymentsScreen(),
      binding: DuesPaymentsBinding(),
    ),
  ];
}
