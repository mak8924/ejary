import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/audit_reports_controller.dart';

class AuditLogsScreen extends GetView<AuditReportsController> {
  const AuditLogsScreen({super.key});

  String _t(String key) => key.tr;

  String _translatedAction(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return _t('create');
      case 'UPDATE':
        return _t('update');
      case 'DELETE':
        return _t('delete_action');
      case 'ALLOCATE':
        return _t('allocate_action');
      case 'ACTIVATE':
        return _t('audit_activate');
      case 'DEACTIVATE':
        return _t('audit_deactivate');
      default:
        return action;
    }
  }

  String _translatedEntity(String entity) {
    final key = switch (entity.toLowerCase()) {
      'property' => 'audit_property',
      'department' => 'audit_department',
      'unit' => 'audit_unit',
      'tenant' => 'audit_tenant',
      'contract' => 'audit_contract',
      'service' => 'audit_service',
      'service_assignment' => 'audit_service_assignment',
      'due' => 'audit_due',
      'payment' => 'audit_payment',
      'payment_allocation' => 'audit_payment_allocation',
      _ => null,
    };

    return key == null ? entity : _t(key);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('audit_logs')),
        actions: [
          IconButton(
            tooltip: _t('refresh'),
            onPressed: controller.loadAuditLogs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: controller.updateSearch,
              decoration: InputDecoration(
                hintText: _t('audit_search'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedAction.value,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('audit_action'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(_t('all_actions')),
                        ),
                        DropdownMenuItem(
                          value: 'CREATE',
                          child: Text(_translatedAction('CREATE')),
                        ),
                        DropdownMenuItem(
                          value: 'UPDATE',
                          child: Text(_translatedAction('UPDATE')),
                        ),
                        DropdownMenuItem(
                          value: 'DELETE',
                          child: Text(_translatedAction('DELETE')),
                        ),
                        DropdownMenuItem(
                          value: 'ALLOCATE',
                          child: Text(_translatedAction('ALLOCATE')),
                        ),
                        DropdownMenuItem(
                          value: 'ACTIVATE',
                          child: Text(_translatedAction('ACTIVATE')),
                        ),
                        DropdownMenuItem(
                          value: 'DEACTIVATE',
                          child: Text(_translatedAction('DEACTIVATE')),
                        ),
                      ],
                      onChanged: controller.updateAction,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      initialValue: controller.selectedEntity.value,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _t('audit_entity'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(_t('all_entities')),
                        ),
                        ...[
                          'property',
                          'department',
                          'unit',
                          'tenant',
                          'contract',
                          'service',
                          'service_assignment',
                          'due',
                          'payment',
                          'payment_allocation',
                        ].map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(_translatedEntity(value)),
                          ),
                        ),
                      ],
                      onChanged: controller.updateEntity,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingLogs.value) {
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

              if (controller.auditLogs.isEmpty) {
                return Center(
                  child: Text(
                    _t('audit_empty'),
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.loadAuditLogs,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.auditLogs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.auditLogs[index];

                    final action = '${item['action'] ?? ''}';
                    final entity = '${item['entity_type'] ?? ''}';
                    final id = item['entity_id'];
                    final description = '${item['description'] ?? ''}';
                    final date = '${item['created_at'] ?? ''}';

                    final translatedAction = _translatedAction(action);
                    final translatedEntity = _translatedEntity(entity);

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            action.toUpperCase() == 'DELETE'
                                ? Icons.delete_outline
                                : action.toUpperCase() == 'CREATE'
                                ? Icons.add
                                : Icons.edit_outlined,
                          ),
                        ),
                        title: Text('$translatedAction • $translatedEntity'),
                        subtitle: Text(
                          [
                            if (id != null) '${_t('audit_id')}: $id',
                            if (description.isNotEmpty) description,
                            date,
                          ].join('\n'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(
                              '$translatedAction • $translatedEntity',
                            ),
                            content: SingleChildScrollView(
                              child: SelectableText(
                                '${_t('audit_record_id')}: '
                                '${id ?? '-'}\n\n'
                                '${_t('audit_details')}: '
                                '${description.isEmpty ? '-' : description}'
                                '\n\n'
                                '${_t('audit_date_time')}: $date',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(_t('audit_close')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
