import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'stock_card_controller.dart';

class StockCardPage extends StatelessWidget {
  StockCardPage({Key? key}) : super(key: key);

  final StockCardController _controller = Get.put(StockCardController());
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  void _showRebalanceDialog() {
    if (_controller.selectedProductId.value == null) {
      SnackbarHelper.show(
        'Peringatan',
        'Pilih barang terlebih dahulu',
        isError: true,
      );
      return;
    }

    final qtyCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Penyesuaian Stok Fisik',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Masukkan jumlah stok fisik aktual yang ada di toko/gudang:',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            decoration: const InputDecoration(labelText: 'Stok Fisik Aktual'),
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
        ],
      ),
      textConfirm: 'Sesuaikan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final qty = int.tryParse(qtyCtrl.text);
        if (qty != null) {
          _controller.rebalanceStock(qty);
        }
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Kartu Stok (Audit Trail)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Pilih Barang: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() {
                    if (_controller.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) =>
                          '${option['barcode']} - ${option['name']} (Stok: ${option['stock']})',
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return _controller.products.where((option) {
                          final query = textEditingValue.text.toLowerCase();
                          return option['name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query) ||
                              option['barcode']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query);
                        });
                      },
                      onSelected: (Map<String, dynamic> selection) {
                        _controller.onProductChanged(selection['id'] as int);
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: 'Cari Barang (Nama/SKU)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                prefixIcon: const Icon(Icons.search),
                              ),
                            );
                          },
                    );
                  }),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _controller.loadStockMovements,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showRebalanceDialog,
                  icon: const Icon(Icons.balance),
                  label: const Text('Rebalance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value)
                return const Center(child: CircularProgressIndicator());
              if (_controller.stockMovements.isEmpty)
                return const Center(
                  child: Text(
                    'Tidak ada histori pergerakan stok untuk barang ini.',
                  ),
                );

              return Card(
                margin: const EdgeInsets.all(16),
                child: ListView.separated(
                  itemCount: _controller.stockMovements.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _controller.stockMovements[index];
                    bool isIn = item['type'] == 'IN';
                    bool isAdjustment = item['type'] == 'ADJUSTMENT';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAdjustment
                            ? Colors.orange.withOpacity(0.2)
                            : (isIn
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2)),
                        child: Icon(
                          isAdjustment
                              ? Icons.balance
                              : (isIn
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward),
                          color: isAdjustment
                              ? Colors.orange
                              : (isIn ? Colors.green : Colors.red),
                        ),
                      ),
                      title: Text(item['note'] ?? 'Penyesuaian Stok'),
                      subtitle: Text(
                        _dateFormat.format(DateTime.parse(item['created_at'])),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isAdjustment ? (item['qty'] > 0 ? '+' : '') : (isIn ? '+' : '-')}${item['qty']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isAdjustment
                                  ? (item['qty'] > 0
                                        ? Colors.green
                                        : Colors.red)
                                  : (isIn ? Colors.green : Colors.red),
                            ),
                          ),
                          // Optional: Text('Sisa: ${item['balance_after']}'),
                        ],
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
