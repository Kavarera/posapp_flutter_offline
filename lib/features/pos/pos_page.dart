import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'pos_controller.dart';

class PosPage extends StatelessWidget {
  PosPage({Key? key}) : super(key: key);

  final POSController _controller = Get.put(POSController());
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Transaksi Kasir (POS)',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
      ),
      body: Row(
        children: [
          // Left: Product Search & Search Results
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    onChanged: _controller.searchProducts,
                    decoration: InputDecoration(
                      hintText: 'Cari barang atau scan barcode...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      if (_controller.searchResults.isEmpty) {
                        return const Center(
                          child: Text('Barang tidak ditemukan.'),
                        );
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _controller.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _controller.searchResults[index];
                          return InkWell(
                            onTap: () => _controller.addToCart(item),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _currencyFormat.format(
                                        item['sell_price'],
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stok: ${item['stock']} ${item['base_unit_name']}',
                                      style: const TextStyle(fontSize: 12),
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
            ),
          ),

          // Right: Cart & Checkout
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Keranjang Belanja',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Expanded(
                    child: Obx(
                      () => ListView.builder(
                        itemCount: _controller.cartItems.length,
                        itemBuilder: (context, index) {
                          final item = _controller.cartItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              title: Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 20),
                                  onPressed: () => _controller.updateQty(
                                    index,
                                    item['qty'] - 1,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                InkWell(
                                  onTap: () {
                                    TextEditingController qtyCtrl =
                                        TextEditingController(
                                          text: item['qty'].toString(),
                                        );
                                    Get.defaultDialog(
                                      title: 'Ubah Jumlah',
                                      content: TextField(
                                        controller: qtyCtrl,
                                        keyboardType: TextInputType.number,
                                        autofocus: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Jumlah',
                                        ),
                                      ),
                                      onConfirm: () {
                                        _controller.updateQty(
                                          index,
                                          int.tryParse(qtyCtrl.text) ?? 1,
                                        );
                                        Get.back();
                                      },
                                      textConfirm: 'Simpan',
                                      textCancel: 'Batal',
                                      confirmTextColor: Colors.white,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item['qty']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 20),
                                  onPressed: () => _controller.updateQty(
                                    index,
                                    item['qty'] + 1,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'x ${_currencyFormat.format(item['unit_price'])}',
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currencyFormat.format(item['total_price']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _controller.removeCartItem(index),
                                ),
                              ],
                            ),
                          ),
                        );
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  // Customer Selection
                  Obx(
                    () => DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Pelanggan'),
                      value: _controller.selectedCustomerId.value,
                      items: _controller.customers
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c['id'] as int,
                              child: Text(c['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          _controller.selectedCustomerId.value = val,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method
                  Obx(
                    () => DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Metode Pembayaran',
                      ),
                      value: _controller.paymentMethod.value,
                      items: const [
                        DropdownMenuItem(value: 'Tunai', child: Text('Tunai')),
                        DropdownMenuItem(
                          value: 'Hutang',
                          child: Text('Hutang / Tempo'),
                        ),
                      ],
                      onChanged: (val) =>
                          _controller.paymentMethod.value = val ?? 'Tunai',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Paid if Tunai
                  Obx(
                    () => _controller.paymentMethod.value == 'Tunai'
                        ? TextField(
                            decoration: const InputDecoration(
                              labelText: 'Uang Diterima',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: _controller.setAmountPaid,
                            controller: _controller.uangDiterimaController,
                          )
                        : const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 24),

                  // Total
                  Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(_controller.totalNominal),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      await _controller.processCheckout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'BAYAR SEKARANG',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
