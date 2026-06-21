import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'stock_card_controller.dart';
import 'stock_opname_dialog.dart';

class StockCardPage extends StatelessWidget {
  StockCardPage({Key? key}) : super(key: key);

  final StockCardController _controller = Get.put(StockCardController());
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  void _showMovementDetailDialog(Map<String, dynamic> item, Map<String, dynamic>? detail, List<Map<String, dynamic>> batchDetails, List<String> docPaths) {
    Get.defaultDialog(
      title: item['type'] == 'ADJUSTMENT' ? 'Detail Opname Stok' : 'Detail Pergerakan Stok',
      content: SizedBox(
        width: item['type'] == 'ADJUSTMENT' ? 600 : 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipe: ${item['type']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Tanggal: ${_dateFormat.format(DateTime.parse(item['created_at']))}'),
            
            if (item['type'] != 'ADJUSTMENT') ...[
              Text('Perubahan Qty: ${item['qty']}'),
              Text('Stok Setelahnya: ${item['balance_after']}'),
            ],

            if (detail != null) ...[
              const Divider(),
              const Text('Referensi Dokumen:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('No Ref: ${detail['reference_number'] ?? '-'}'),
              Text('Pihak Terkait: ${detail['related_party'] ?? '-'}'),
            ],

            if (item['type'] == 'ADJUSTMENT' && batchDetails.isNotEmpty) ...[
              const Divider(),
              const Text('Daftar Penyesuaian Barang:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: batchDetails.map((bd) {
                      int qty = bd['qty'] as int;
                      int after = bd['balance_after'] as int;
                      int before = after - qty;
                      return ListTile(
                        title: Text('${bd['barcode']} - ${bd['name']}'),
                        subtitle: Text('Sebelum: $before  |  Sesudah: $after  |  Selisih: ${qty > 0 ? '+' : ''}$qty'),
                      );
                    }).toList(),
                  ),
                ),
              )
            ],

            if (item['type'] == 'IN' && docPaths.isNotEmpty) ...[
              const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.file_open),
                label: const Text('Buka Dokumen Bukti (Aplikasi OS)'),
                onPressed: () {
                  try {
                    List<dynamic> paths = jsonDecode(docPaths.first);
                    if (paths.isNotEmpty) {
                      Process.run('cmd', ['/c', 'start', '""', paths.first.toString()]);
                    }
                  } catch (e) {
                    // Try parsing as raw string if not json
                    Process.run('cmd', ['/c', 'start', '""', docPaths.first]);
                  }
                },
              )
            ],
            if (item['type'] == 'IN' && docPaths.isEmpty) ...[
              const Divider(),
              const Text('Tidak ada lampiran dokumen pada transaksi ini.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
      textConfirm: 'Tutup',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
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
                Obx(
                  () => DropdownButton<String>(
                    value: _controller.selectedTypeFilter.value,
                    items: const [
                      DropdownMenuItem(value: 'Semua', child: Text('Semua Tipe')),
                      DropdownMenuItem(value: 'Masuk', child: Text('Masuk (IN)')),
                      DropdownMenuItem(value: 'Keluar', child: Text('Keluar (OUT)')),
                      DropdownMenuItem(value: 'Opname', child: Text('Opname (ADJ)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _controller.selectedTypeFilter.value = val;
                        _controller.loadStockMovements();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _controller.loadStockMovements,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Get.dialog(const StockOpnameDialog(), barrierDismissible: false);
                  },
                  icon: const Icon(Icons.balance),
                  label: const Text('Opname Stok'),
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
                      onTap: () async {
                        final detail = await _controller.getMovementDetail(item);
                        List<Map<String, dynamic>> batchDetails = [];
                        if (isAdjustment) {
                          batchDetails = await _controller.getOpnameBatchDetails(item['created_at']);
                        }
                        List<String> docPaths = [];
                        if (isIn) {
                          docPaths = await _controller.getDocumentPaths(item);
                        }
                        _showMovementDetailDialog(item, detail, batchDetails, docPaths);
                      },
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
