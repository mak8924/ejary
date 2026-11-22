import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/audit_reports_controller.dart';

class ReportsScreen extends GetView<AuditReportsController> {
  const ReportsScreen({super.key});

  String _t(String key) => key.tr;

  Widget _metric(
    BuildContext context,
    String titleKey,
    String valueKey, {
    bool money = false,
  }) {
    final theme = Theme.of(context);

    return Obx(() {
      final value = controller.metric(valueKey);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleKey.tr, style: theme.textTheme.bodyMedium),
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

  pw.Widget _pdfSection({
    required String title,
    required List<MapEntry<String, String>> rows,
    required pw.Font regularFont,
    required pw.Font boldFont,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(9),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Text(
            title,
            style: pw.TextStyle(font: boldFont, fontSize: 13),
          ),
        ),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          ),
          child: pw.Column(
            children: [
              for (var i = 0; i < rows.length; i++)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: pw.BoxDecoration(
                    border: i == rows.length - 1
                        ? null
                        : const pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey300,
                              width: 0.5,
                            ),
                          ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          rows[i].key,
                          style: pw.TextStyle(font: regularFont, fontSize: 10),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Text(
                        rows[i].value,
                        style: pw.TextStyle(font: boldFont, fontSize: 10),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  Future<void> _printReport(BuildContext context) async {
    try {
      await controller.loadReports();

      final regularFontData = await rootBundle.load('assets/fonts/arial.ttf');
      final boldFontData = await rootBundle.load('assets/fonts/arialbd.ttf');

      final regularFont = pw.Font.ttf(regularFontData);
      final boldFont = pw.Font.ttf(boldFontData);

      final isArabic = Get.locale?.languageCode == 'ar';

      String amount(String key) {
        return controller.formatAmount(controller.metric(key));
      }

      String count(String key) {
        return controller.metric(key).toStringAsFixed(0);
      }

      final propertyRows = <MapEntry<String, String>>[
        MapEntry(_t('total_properties'), count('properties')),
        MapEntry(_t('total_departments'), count('departments')),
        MapEntry(_t('total_units'), count('units')),
        MapEntry(_t('available_units'), count('available')),
        MapEntry(_t('occupied_units'), count('occupied')),
      ];

      final contractRows = <MapEntry<String, String>>[
        MapEntry(_t('total_tenants'), count('tenants')),
        MapEntry(_t('total_contracts'), count('contracts')),
        MapEntry(_t('active_contracts'), count('activeContracts')),
        MapEntry(_t('total_dues'), count('dues')),
      ];

      final financialRows = <MapEntry<String, String>>[
        MapEntry(_t('payments_received'), amount('payments')),
        MapEntry(_t('allocated_payments'), amount('allocated')),
        MapEntry(_t('unallocated_payments'), amount('unallocated')),
        MapEntry(_t('outstanding_balance'), amount('outstanding')),
        MapEntry(_t('overdue_balance'), amount('overdue')),
      ];

      final now = DateTime.now();
      final dateText =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';

      final document = pw.Document();

      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          footer: (pdfContext) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 12),
              child: pw.Text(
                '${pdfContext.pageNumber} / ${pdfContext.pagesCount}',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
          build: (pdfContext) => [
            pw.Directionality(
              textDirection: isArabic
                  ? pw.TextDirection.rtl
                  : pw.TextDirection.ltr,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    _t('reports'),
                    style: pw.TextStyle(font: boldFont, fontSize: 22),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    '${isArabic ? 'تاريخ التقرير' : 'Report date'}: $dateText',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  _pdfSection(
                    title: _t('property_summary'),
                    rows: propertyRows,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  _pdfSection(
                    title: _t('contract_summary'),
                    rows: contractRows,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  _pdfSection(
                    title: _t('financial_summary'),
                    rows: financialRows,
                    regularFont: regularFont,
                    boldFont: boldFont,
                  ),
                  pw.Text(
                    _t('report_balance_note'),
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => document.save(),
        name: 'ejary_report.pdf',
      );
    } catch (error, stackTrace) {
      debugPrint('REPORT PRINT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  bool isArabicError(Object error) {
    return Get.locale?.languageCode == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('reports')),
        actions: [
          IconButton(
            tooltip: Get.locale?.languageCode == 'ar'
                ? 'طباعة التقرير'
                : 'Print report',
            onPressed: () => _printReport(context),
            icon: const Icon(Icons.print_outlined),
          ),
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
              _metric(context, 'total_properties', 'properties'),
              _metric(context, 'total_departments', 'departments'),
              _metric(context, 'total_units', 'units'),
              _metric(context, 'available_units', 'available'),
              _metric(context, 'occupied_units', 'occupied'),

              const SizedBox(height: 16),

              Text(_t('contract_summary'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _metric(context, 'total_tenants', 'tenants'),
              _metric(context, 'total_contracts', 'contracts'),
              _metric(context, 'active_contracts', 'activeContracts'),
              _metric(context, 'total_dues', 'dues'),

              const SizedBox(height: 16),

              Text(_t('financial_summary'), style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              _metric(context, 'payments_received', 'payments', money: true),
              _metric(context, 'allocated_payments', 'allocated', money: true),
              _metric(
                context,
                'unallocated_payments',
                'unallocated',
                money: true,
              ),
              _metric(
                context,
                'outstanding_balance',
                'outstanding',
                money: true,
              ),
              _metric(context, 'overdue_balance', 'overdue', money: true),

              const SizedBox(height: 12),
              Text(_t('report_balance_note'), style: theme.textTheme.bodySmall),
            ],
          ),
        );
      }),
    );
  }
}
