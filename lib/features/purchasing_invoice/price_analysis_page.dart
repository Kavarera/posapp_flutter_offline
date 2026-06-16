import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/price_analysis_controller.dart';
import 'package:intl/intl.dart';

class PriceAnalysisPage extends StatelessWidget {
  PriceAnalysisPage({super.key});

  final PriceAnalysisController _controller = Get.put(
    PriceAnalysisController(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withOpacity(0.3),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis Harga Pembelian',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Barang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      Widget productSelectionWidget;
                      if (_controller.selectedProduct.value != null) {
                        productSelectionWidget = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_controller.selectedProduct.value!.name} (${_controller.selectedProduct.value!.barcode ?? "-"})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _showAddPriceDialog(context),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Harga'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: AppColors.error,
                                    ),
                                    onPressed: () =>
                                        _controller.clearSelection(),
                                    tooltip: 'Ganti Barang',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        productSelectionWidget = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              onChanged: (val) =>
                                  _controller.searchQuery.value = val,
                              decoration: InputDecoration(
                                hintText: 'Ketik nama barang atau SKU...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            if (_controller.searchResults.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _controller.searchResults.length,
                                  itemBuilder: (context, index) {
                                    final product =
                                        _controller.searchResults[index];
                                    return ListTile(
                                      title: Text(product.name),
                                      subtitle: Text(product.barcode ?? '-'),
                                      onTap: () =>
                                          _controller.selectProduct(product),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      }

                      final months = [
                        'Januari',
                        'Februari',
                        'Maret',
                        'April',
                        'Mei',
                        'Juni',
                        'Juli',
                        'Agustus',
                        'September',
                        'Oktober',
                        'November',
                        'Desember',
                      ];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          productSelectionWidget,
                          const SizedBox(height: 24),
                          const Text(
                            'Periode Analisis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  decoration: const InputDecoration(),
                                  value: _controller.selectedMonth.value,
                                  items: [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('Semua Bulan'),
                                    ),
                                    for (int i = 1; i <= 12; i++)
                                      DropdownMenuItem(
                                        value: i,
                                        child: Text(months[i - 1]),
                                      ),
                                  ],
                                  onChanged: (val) => _controller.applyFilter(
                                    month: val,
                                    year: _controller.selectedYear.value,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Tahun',
                                    hintText: 'Contoh: 2024',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    int? year = int.tryParse(val);
                                    if (val.isEmpty) year = null;
                                    _controller.applyFilter(
                                      month: _controller.selectedMonth.value,
                                      year: year,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Obx(() {
                if (_controller.selectedProduct.value == null) {
                  return const Center(
                    child: Text(
                      'Silakan cari dan pilih barang terlebih dahulu untuk melihat riwayat harga.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (_controller.priceHistory.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada riwayat pembelian untuk barang ini.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final formatter = NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                );

                final cheapestItem = _controller.cheapestHistoryItem;
                DateTime? cheapestDate;
                if (cheapestItem != null) {
                  try {
                    cheapestDate = DateTime.parse(cheapestItem.invoiceDate);
                  } catch (_) {}
                }
                String cheapestDateStr = cheapestDate != null
                    ? DateFormat('dd MMM yyyy').format(cheapestDate)
                    : (cheapestItem?.invoiceDate ?? '');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (cheapestItem != null) ...[
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: AppColors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.star, color: AppColors.success),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supplier Termurah',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                cheapestItem.supplierName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Harga Dasar: ${formatter.format(cheapestItem.baseUnitPrice)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tanggal Pembelian: $cheapestDateStr',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey.shade100,
                              ),
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Tanggal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Supplier',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Harga Dasar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Perbandingan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: _controller.priceHistory.map((item) {
                                DateTime? date;
                                try {
                                  date = DateTime.parse(item.invoiceDate);
                                } catch (_) {}
                                String dateStr = date != null
                                    ? DateFormat('dd MMM yyyy').format(date)
                                    : item.invoiceDate;

                                bool isCheapest = item.percentageDiff == 0;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(dateStr)),
                                    DataCell(Text(item.supplierName)),
                                    DataCell(
                                      Text(
                                        formatter.format(item.baseUnitPrice),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isCheapest
                                              ? AppColors.success.withOpacity(
                                                  0.1,
                                                )
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          isCheapest
                                              ? 'Termurah'
                                              : '+${item.percentageDiff.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: isCheapest
                                                ? AppColors.success
                                                : Colors.orange.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPriceDialog(BuildContext context) {
    final supplierIdController = Rxn<int>();
    final priceController = TextEditingController();
    final dateController = Rxn<DateTime>(DateTime.now());

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Harga Manual',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(labelText: 'Supplier'),
                  value: supplierIdController.value,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Pilih Supplier'),
                    ),
                    ..._controller.productSuppliers.map((s) {
                      return DropdownMenuItem(value: s.id, child: Text(s.name));
                    }),
                  ],
                  onChanged: (val) => supplierIdController.value = val,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga Dasar (Satuan)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Obx(
                () => InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateController.value ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) dateController.value = date;
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal Pembelian',
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(dateController.value!),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (supplierIdController.value == null ||
                  priceController.text.isEmpty) {
                SnackbarHelper.show(
                  'Validasi',
                  'Supplier dan Harga wajib diisi',
                  isError: true,
                );

                return;
              }
              final price = double.tryParse(priceController.text);
              if (price == null) {
                SnackbarHelper.show(
                  'Validasi',
                  'Harga tidak valid',
                  isError: true,
                );
                return;
              }
              _controller.insertManualPrice(
                supplierId: supplierIdController.value!,
                price: price,
                date: dateController.value!,
              );
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
