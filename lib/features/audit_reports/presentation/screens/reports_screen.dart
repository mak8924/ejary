import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/audit_reports_controller.dart';

class ReportsScreen extends GetView<AuditReportsController> {
  const ReportsScreen({super.key});

  String _t(String key) => key.tr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget metric(
      String titleKey,
      String valueKey, {
      bool money = false,
      IconData? icon,
    }) {
      return Obx(() {
        final value = controller.metric(valueKey);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    icon ?? Icons.analytics_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_t(titleKey), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text(
                        money
                            ? controller.formatAmount(value)
                            : value.toStringAsFixed(0),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('reports')),
        actions: [
          IconButton(
            tooltip: _t('refresh'),
            onPressed: controller.loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingReports.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(controller.errorMessage.value),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadReports,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(_t('property_summary'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),

              metric('total_properties', 'properties', icon: Icons.apartment),
              metric('total_departments', 'departments', icon: Icons.domain),
              metric('total_units', 'units', icon: Icons.meeting_room),
              metric(
                'available_units',
                'available',
                icon: Icons.check_circle_outline,
              ),
              metric('occupied_units', 'occupied', icon: Icons.people_outline),

              const SizedBox(height: 16),

              Text(_t('contract_summary'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),

              metric(
                'total_tenants',
                'tenants',
                icon: Icons.people_alt_outlined,
              ),
              metric(
                'total_contracts',
                'contracts',
                icon: Icons.description_outlined,
              ),
              metric(
                'active_contracts',
                'activeContracts',
                icon: Icons.verified_outlined,
              ),
              metric('total_dues', 'dues', icon: Icons.receipt_long_outlined),

              const SizedBox(height: 16),

              Text(_t('financial_summary'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),

              metric(
                'payments_received',
                'payments',
                money: true,
                icon: Icons.payments_outlined,
              ),
              metric(
                'allocated_payments',
                'allocated',
                money: true,
                icon: Icons.call_split,
              ),
              metric(
                'unallocated_payments',
                'unallocated',
                money: true,
                icon: Icons.account_balance_wallet_outlined,
              ),
              metric(
                'outstanding_balance',
                'outstanding',
                money: true,
                icon: Icons.pending_actions,
              ),
              metric(
                'overdue_balance',
                'overdue',
                money: true,
                icon: Icons.warning_amber_outlined,
              ),

              const SizedBox(height: 12),

              Text(_t('report_balance_note'), style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }),
    );
  }
}
