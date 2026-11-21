import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../routes/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            tooltip: 'logout'.tr,
            onPressed: controller.lockApp,
            icon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('welcome'.tr, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('starter_message'.tr),
          const SizedBox(height: 24),

          // PROPERTY MANAGEMENT
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.properties),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colors.primaryContainer,
                      child: Icon(
                        Icons.apartment,
                        size: 32,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Property Management',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage properties, departments and rental units.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TENANTS AND CONTRACTS
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Get.toNamed(AppRoutes.tenantContracts),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Icon(Icons.people_alt_outlined, size: 30),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tenant & Contract Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Manage tenants, rental contracts and renewals.',
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // SECURITY MESSAGE
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primaryContainer,
                    child: Icon(
                      Icons.shield_outlined,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('security_message'.tr)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // SETTINGS
          Text('settings'.tr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text('appearance'.tr),
                  trailing: DropdownButton<ThemeMode>(
                    value: controller.preferences.themeMode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('system'.tr),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('light'.tr),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('dark'.tr),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setTheme(value);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text('language'.tr),
                  trailing: DropdownButton<String>(
                    value: controller.preferences.locale.languageCode,
                    underline: const SizedBox.shrink(),
                    items: [
                      DropdownMenuItem(value: 'en', child: Text('english'.tr)),
                      DropdownMenuItem(value: 'ar', child: Text('arabic'.tr)),
                    ],
                    onChanged: (value) {
                      if (value != null) controller.setLanguage(value);
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.password),
                  title: Text('change_pin'.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: controller.openChangePin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
