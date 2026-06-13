import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_controller.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_form_page.dart';
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

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                                  'Supplier Inv: ${invoice.supplierInvoiceNumber ?? '-'}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
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
                                  invoice.invoiceDate,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: invoice.paymentMethod == 'Tunai'
                                        ? AppColors.success.withOpacity(0.1)
                                        : (invoice.paymentMethod == 'Hutang'
                                              ? AppColors.error.withOpacity(0.1)
                                              : AppColors.accent.withOpacity(
                                                  0.1,
                                                )),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    invoice.paymentMethod,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: invoice.paymentMethod == 'Tunai'
                                          ? AppColors.success
                                          : (invoice.paymentMethod == 'Hutang'
                                                ? AppColors.error
                                                : AppColors.accent),
                                    ),
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
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
