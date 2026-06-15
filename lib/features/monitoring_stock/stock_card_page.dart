import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'stock_card_controller.dart';

class StockCardPage extends StatelessWidget {
  StockCardPage({Key? key}) : super(key: key);

  final StockCardController _controller = Get.put(StockCardController());
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

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
                      fieldViewBuilder: (
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIn
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        child: Icon(
                          isIn ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isIn ? Colors.green : Colors.red,
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
                            '${isIn ? '+' : '-'}${item['qty']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIn ? Colors.green : Colors.red,
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
