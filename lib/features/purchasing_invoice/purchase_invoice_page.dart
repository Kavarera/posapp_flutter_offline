import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_controller.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_form_page.dart';
import 'package:posapp_w6zxit6s/core/models/purchase_invoice.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';
import 'package:intl/intl.dart';

class PurchaseInvoicePage extends StatelessWidget {
  PurchaseInvoicePage({super.key});

  final PurchaseInvoiceController _controller = Get.put(
    PurchaseInvoiceController(),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoice Pembelian',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => PurchaseInvoiceFormPage()),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Buat Invoice',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(),
                    value: _controller.selectedStatus.value,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Semua Status'),
                      ),
                      DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                      DropdownMenuItem(
                        value: 'Belum Lunas',
                        child: Text('Belum Lunas'),
                      ),
                    ],
                    onChanged: (val) => _controller.applyFilter(
                      status: val,
                      supplierId: _controller.selectedSupplierId.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<int?>(
                    decoration: const InputDecoration(),
                    value: _controller.selectedSupplierId.value,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Semua Supplier'),
                      ),
                      ..._controller.suppliers.map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      ),
                    ],
                    onChanged: (val) => _controller.applyFilter(
                      status: _controller.selectedStatus.value,
                      supplierId: val,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    decoration: const InputDecoration(),
                    value: _controller.sortBy.value,
                    items: const [
                      DropdownMenuItem(
                        value: 'created_at',
                        child: Text('Tanggal Dibuat'),
                      ),
                      DropdownMenuItem(
                        value: 'total_nominal',
                        child: Text('Total Nominal'),
                      ),
                      DropdownMenuItem(
                        value: 'due_date',
                        child: Text('Jatuh Tempo'),
                      ),
                    ],
                    onChanged: (val) =>
                        _controller.applySort(val ?? 'created_at'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(
                () => IconButton(
                  icon: Icon(
                    _controller.sortAscending.value
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                  ),
                  onPressed: () => _controller.toggleSortDirection(),
                  tooltip: _controller.sortAscending.value
                      ? 'Menaik (Ascending)'
                      : 'Menurun (Descending)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (_controller.selectedSupplierId.value != null) {
              final formatter = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp ',
                decimalDigits: 0,
              );
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Total Invoices',
                        _controller.totalInvoicesCount,
                        _controller.totalInvoicesAmount,
                        formatter,
                        AppColors.primary,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Lunas',
                        _controller.totalLunasCount,
                        _controller.totalLunasAmount,
                        formatter,
                        AppColors.success,
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Belum Lunas',
                        _controller.totalBelumLunasCount,
                        _controller.totalBelumLunasAmount,
                        formatter,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (_controller.invoices.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada data Invoice Pembelian.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: _controller.invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _controller.invoices[index];
                  final formatter = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  );

                  DateTime? date;
                  try {
                    date = DateTime.parse(invoice.invoiceDate);
                  } catch (e) {
                    date = null;
                  }
                  String formattedDate = date != null
                      ? DateFormat('dd MMM yyyy').format(date)
                      : invoice.invoiceDate;

                  DateTime? dueDate;
                  try {
                    if (invoice.dueDate != null) {
                      dueDate = DateTime.parse(invoice.dueDate!);
                    }
                  } catch (e) {
                    dueDate = null;
                  }
                  String formattedDueDate = dueDate != null
                      ? DateFormat('dd MMM yyyy').format(dueDate)
                      : (invoice.dueDate ?? '-');

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _showDetailDialog(invoice, formatter),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoice.invoiceNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ref: ${invoice.supplierInvoiceNumber ?? '-'}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Supplier',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    invoice.supplierName ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tanggal',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pembayaran',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    invoice.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: invoice.paymentMethod == 'Tunai'
                                          ? AppColors.success
                                          : (invoice.paymentMethod == 'Hutang'
                                                ? AppColors.error
                                                : AppColors.accent),
                                    ),
                                  ),
                                  if (invoice.paymentMethod == 'Hutang')
                                    Text(
                                      'JT: $formattedDueDate',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    formatter.format(invoice.totalNominal),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(PurchaseInvoice invoice, NumberFormat formatter) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detail Invoice ${invoice.invoiceNumber}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Supplier: ${invoice.supplierName ?? '-'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Tipe Pembayaran: ${invoice.paymentMethod}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nama Barang',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Qty (Satuan)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Masuk (Dasar)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Harga Beli',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: invoice.details.map((d) {
                      double mult = d.baseUnitPrice > 0
                          ? (d.unitPrice / d.baseUnitPrice)
                          : 1;
                      int baseQty = (d.qty * mult).round();
                      return DataRow(
                        cells: [
                          DataCell(Text(d.productName ?? '-')),
                          DataCell(Text('${d.qty} ${d.unitName ?? '-'}')),
                          DataCell(Text('$baseQty')),
                          DataCell(Text(formatter.format(d.unitPrice))),
                          DataCell(Text(formatter.format(d.totalPrice))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    int count,
    double amount,
    NumberFormat formatter,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatter.format(amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
