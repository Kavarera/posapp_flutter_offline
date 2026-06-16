import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:window_manager/window_manager.dart';
import 'pos_controller.dart';

class PosPage extends StatelessWidget {
  PosPage({Key? key}) : super(key: key);

  final POSController _controller = Get.put(POSController());
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  Future<void> _setupWindow() async {
    await windowManager.setFullScreen(true);
    await windowManager.setResizable(false);
    await windowManager.setMinimizable(false);
  }

  @override
  Widget build(BuildContext context) {
    _setupWindow();
    TextEditingController? localSearchController;
    FocusNode? localFocusNode;

    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Scaffold(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Search & Cart Items
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Autocomplete<Map<String, dynamic>>(
                      displayStringForOption: (option) =>
                          '${option['barcode']} - ${option['name']} (Stok: ${option['stock']})',
                      optionsBuilder: (textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        return await _controller.searchProductsAsync(
                          textEditingValue.text,
                        );
                      },
                      onSelected: (selection) {
                        _controller.addToCart(selection);
                        localSearchController?.clear();
                        localFocusNode?.requestFocus();
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            localSearchController = textEditingController;
                            localFocusNode = focusNode;
                            return TextField(
                              controller: textEditingController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText:
                                    'Ketik nama barang atau SKU / Scan Barcode...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onSubmitted: (value) {
                                onFieldSubmitted();
                              },
                            );
                          },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              constraints: const BoxConstraints(maxHeight: 300),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return Builder(
                                    builder: (BuildContext context) {
                                      final bool highlight =
                                          AutocompleteHighlightedOption.of(
                                            context,
                                          ) ==
                                          index;
                                      return Container(
                                        color: highlight
                                            ? AppColors.primary.withOpacity(0.1)
                                            : null,
                                        child: InkWell(
                                          onTap: () {
                                            onSelected(option);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(16.0),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: Colors.grey.shade200,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${option['barcode']} - ${option['name']}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Stok: ${option['stock']}',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Daftar Belanjaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Cart List
                    Expanded(
                      child: Obx(
                        () => ListView.builder(
                          itemCount: _controller.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _controller.cartItems[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(14),
                                title: Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Row(
                                    children: [
                                      // Qty Control
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  _controller.updateQty(
                                                    index,
                                                    item['qty'] - 1,
                                                  ),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                TextEditingController qtyCtrl =
                                                    TextEditingController(
                                                      text: item['qty']
                                                          .toString(),
                                                    );
                                                Get.defaultDialog(
                                                  title: 'Ubah Jumlah',
                                                  content: TextField(
                                                    controller: qtyCtrl,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    autofocus: true,
                                                    decoration:
                                                        const InputDecoration(
                                                          labelText: 'Jumlah',
                                                        ),
                                                  ),
                                                  onConfirm: () {
                                                    _controller.updateQty(
                                                      index,
                                                      int.tryParse(
                                                            qtyCtrl.text,
                                                          ) ??
                                                          1,
                                                    );
                                                    Get.back();
                                                  },
                                                  textConfirm: 'Simpan',
                                                  textCancel: 'Batal',
                                                  confirmTextColor:
                                                      Colors.white,
                                                );
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                color: Colors.grey.shade50,
                                                child: Text(
                                                  '${item['qty']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                              onPressed: () =>
                                                  _controller.updateQty(
                                                    index,
                                                    item['qty'] + 1,
                                                  ),
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        '@ ${_currencyFormat.format(item['unit_price'])}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _currencyFormat.format(
                                        item['total_price'],
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    InkWell(
                                      onTap: () =>
                                          _controller.removeCartItem(index),
                                      child: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Right: Checkout & Payment Summary
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Ringkasan Transaksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Customer Selection
                    const Text(
                      'Pelanggan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
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
                    const SizedBox(height: 20),

                    // Payment Method
                    const Text(
                      'Metode Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        value: _controller.paymentMethod.value,
                        items: const [
                          DropdownMenuItem(
                            value: 'Tunai',
                            child: Text('Tunai'),
                          ),
                          DropdownMenuItem(
                            value: 'Digital',
                            child: Text('Digital'),
                          ),
                          DropdownMenuItem(
                            value: 'Hutang',
                            child: Text('Hutang / Tempo'),
                          ),
                        ],
                        onChanged: (val) =>
                            _controller.paymentMethod.value = val ?? 'Tunai',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Amount Paid if Tunai
                    Obx(
                      () => _controller.paymentMethod.value == 'Tunai'
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Uang Diterima',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    prefixText: 'Rp ',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: _controller.setAmountPaid,
                                  controller:
                                      _controller.uangDiterimaController,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    const Spacer(),
                    const Divider(thickness: 2),
                    const SizedBox(height: 16),

                    // Total
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL:',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currencyFormat.format(_controller.totalNominal),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Kembalian
                    Obx(() {
                      if (_controller.paymentMethod.value == 'Tunai' &&
                          _controller.amountPaid.value > 0) {
                        double change =
                            _controller.amountPaid.value -
                            _controller.totalNominal;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kembalian:',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                _currencyFormat.format(change > 0 ? change : 0),
                                style: TextStyle(
                                  color: change >= 0
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () async {
                        await _controller.processCheckout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'BAYAR SEKARANG',
                        style: TextStyle(
                          fontSize: 20,
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
      ),
    );
  }
}
