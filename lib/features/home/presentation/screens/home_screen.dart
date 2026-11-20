import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          Text('welcome'.tr, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('starter_message'.tr),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.shield_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('security_message'.tr)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('settings'.tr, style: Theme.of(context).textTheme.titleLarge),
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
