import 'package:flutter_test/flutter_test.dart';
import 'package:ejary/routes/app_routes.dart';

void main() {
  group('EJARY route configuration', () {
    test('all main application routes are defined', () {
      final routes = <String>[
        AppRoutes.splash,
        AppRoutes.pinSetup,
        AppRoutes.pinVerify,
        AppRoutes.pinChange,
        AppRoutes.home,
        AppRoutes.properties,
        AppRoutes.tenantContracts,
      ];

      expect(routes, hasLength(7));

      for (final route in routes) {
        expect(route, isNotEmpty);
        expect(route.startsWith('/'), isTrue);
      }
    });

    test('application routes do not contain duplicates', () {
      final routes = <String>[
        AppRoutes.splash,
        AppRoutes.pinSetup,
        AppRoutes.pinVerify,
        AppRoutes.pinChange,
        AppRoutes.home,
        AppRoutes.properties,
        AppRoutes.tenantContracts,
      ];

      expect(routes.toSet().length, routes.length);
    });
  });
}
