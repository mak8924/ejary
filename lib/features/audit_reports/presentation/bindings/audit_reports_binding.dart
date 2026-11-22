import 'package:get/get.dart';

import '../../../../core/database/local_database.dart';
import '../../data/repositories/audit_reports_repository.dart';
import '../controllers/audit_reports_controller.dart';

class AuditReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(
      () => AuditReportsRepository(
        localDatabase: Get.find<LocalDatabase>(),
      ),
    );
    Get.lazyPut(
      () => AuditReportsController(
        repository: Get.find<AuditReportsRepository>(),
      ),
    );
  }
}