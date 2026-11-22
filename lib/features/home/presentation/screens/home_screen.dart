import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  Widget _metricCard(BuildContext context, String titleKey, String metricKey) {
    final theme = Theme.of(context);

    return Obx(() {
      final value = controller.dashboardMetrics[metricKey] ?? 0;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(titleKey.tr, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    });
  }

  Widget _navigationCard(
    BuildContext context, {
    required String titleKey,
    required String descriptionKey,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primaryContainer,
                child: Icon(icon, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(descriptionKey.tr, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    var selectedTheme = controller.preferences.themeMode;
    var selectedLanguage = controller.preferences.locale.languageCode;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('settings'.tr),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.palette_outlined),
                      title: Text('appearance'.tr),
                      subtitle: DropdownButton<ThemeMode>(
                        value: selectedTheme,
                        isExpanded: true,
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
                          if (value == null) return;

                          setDialogState(() {
                            selectedTheme = value;
                          });

                          controller.setTheme(value);
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.language),
                      title: Text('language'.tr),
                      subtitle: DropdownButton<String>(
                        value: selectedLanguage,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Text('english'.tr),
                          ),
                          DropdownMenuItem(
                            value: 'ar',
                            child: Text('arabic'.tr),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedLanguage = value;
                          });

                          controller.setLanguage(value);
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.password),
                      title: Text('change_pin'.tr),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        controller.openChangePin();
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('audit_close'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _financialCard(
    BuildContext context,
    String titleKey,
    num amount,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(titleKey.tr),
        trailing: Text(
          amount.toStringAsFixed(2),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard'.tr),
        actions: [
          IconButton(
            tooltip: 'settings'.tr,
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            tooltip: 'logout'.tr,
            onPressed: controller.lockApp,
            icon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('welcome'.tr, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('starter_message'.tr),
            const SizedBox(height: 20),

            Text('dashboard'.tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),

            Obx(() {
              if (controller.isLoadingDashboard.value &&
                  controller.dashboardMetrics.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (controller.dashboardError.value.isNotEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(controller.dashboardError.value),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: controller.loadDashboard,
                          icon: const Icon(Icons.refresh),
                          label: Text('refresh'.tr),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  _metricCard(context, 'total_properties', 'properties'),
                  _metricCard(context, 'total_units', 'units'),
                  _metricCard(context, 'total_tenants', 'tenants'),
                  _metricCard(context, 'active_contracts', 'activeContracts'),
                ],
              );
            }),

            const SizedBox(height: 20),
            Text('financial_summary'.tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),

            Obx(() {
              if (controller.dashboardMetrics.isEmpty) {
                return const SizedBox.shrink();
              }

              final payments = controller.dashboardMetrics['payments'] ?? 0;
              final outstanding =
                  controller.dashboardMetrics['outstanding'] ?? 0;
              final overdue = controller.dashboardMetrics['overdue'] ?? 0;

              return Column(
                children: [
                  _financialCard(
                    context,
                    'payments_received',
                    payments,
                    Icons.payments_outlined,
                  ),
                  _financialCard(
                    context,
                    'outstanding_balance',
                    outstanding,
                    Icons.account_balance_wallet_outlined,
                  ),
                  _financialCard(
                    context,
                    'overdue_balance',
                    overdue,
                    Icons.warning_amber_outlined,
                  ),
                ],
              );
            }),

            const SizedBox(height: 20),
            Text('quick_access'.tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),

            _navigationCard(
              context,
              titleKey: 'property_management',
              descriptionKey: 'property_management_desc',
              icon: Icons.apartment,
              onTap: controller.openProperties,
            ),
            _navigationCard(
              context,
              titleKey: 'tenant_contract_management',
              descriptionKey: 'tenant_contract_management_desc',
              icon: Icons.people_alt_outlined,
              onTap: controller.openTenantContracts,
            ),
            _navigationCard(
              context,
              titleKey: 'services_management',
              descriptionKey: 'services_management_desc',
              icon: Icons.miscellaneous_services_outlined,
              onTap: controller.openServices,
            ),
            _navigationCard(
              context,
              titleKey: 'audit_logs',
              descriptionKey: 'audit_logs_desc',
              icon: Icons.history,
              onTap: controller.openAuditLogs,
            ),
            _navigationCard(
              context,
              titleKey: 'reports',
              descriptionKey: 'reports_desc',
              icon: Icons.bar_chart_outlined,
              onTap: controller.openReports,
            ),
          ],
        ),
      ),
    );
  }
}
