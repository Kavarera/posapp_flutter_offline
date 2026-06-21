import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'stock_card_controller.dart';

class StockOpnameDialog extends StatefulWidget {
  const StockOpnameDialog({Key? key}) : super(key: key);

  @override
  State<StockOpnameDialog> createState() => _StockOpnameDialogState();
}

class _StockOpnameDialogState extends State<StockOpnameDialog> {
  final StockCardController _controller = Get.find<StockCardController>();
  
  // List to hold items being rebalanced
  // Structure: { 'product_id': int, 'name': String, 'system_stock': int, 'actual_stock': int, 'diff': int }
  List<Map<String, dynamic>> _allOpnameItems = [];
  List<Map<String, dynamic>> _filteredOpnameItems = [];
  bool _isProcessing = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load all products automatically
    for (var product in _controller.products) {
      _allOpnameItems.add({
        'product_id': product['id'],
        'name': '${product['barcode']} - ${product['name']}',
        'system_stock': product['stock'],
        'actual_stock': product['stock'],
        'diff': 0,
      });
    }
    _filteredOpnameItems = List.from(_allOpnameItems);
    
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredOpnameItems = List.from(_allOpnameItems);
      } else {
        _filteredOpnameItems = _allOpnameItems.where((item) {
          return item['name'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _updateActualStock(Map<String, dynamic> item, String value) {
    int? actual = int.tryParse(value);
    if (actual != null) {
      setState(() {
        item['actual_stock'] = actual;
        item['diff'] = actual - (item['system_stock'] as int);
      });
    }
  }

  void _submit() async {
    if (_allOpnameItems.isEmpty) {
      SnackbarHelper.show('Peringatan', 'Tidak ada barang di sistem', isError: true);
      return;
    }

    setState(() => _isProcessing = true);
    
    bool success = await _controller.processStockOpname(_allOpnameItems);
    
    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (success) {
      Get.back();
      SnackbarHelper.show('Sukses', 'Berhasil melakukan penyesuaian stok fisik (Opname)', isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Opname Stok Fisik'),
      content: SizedBox(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Barang (Nama/SKU)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 1, child: Text('Sistem', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('Fisik Aktual', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  Expanded(flex: 1, child: Text('Selisih', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                ],
              ),
            ),
            
            // Table Body
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: _filteredOpnameItems.isEmpty
                    ? const Center(child: Text('Barang tidak ditemukan', style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        itemCount: _filteredOpnameItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _filteredOpnameItems[index];
                          final diff = item['diff'] as int;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3, 
                                  child: Text(item['name'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                ),
                                Expanded(
                                  flex: 1, 
                                  child: Text('${item['system_stock']}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                                ),
                                Expanded(
                                  flex: 2, 
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: TextFormField(
                                      initialValue: '${item['actual_stock']}',
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (val) => _updateActualStock(item, val),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1, 
                                  child: Text(
                                    '${diff > 0 ? '+' : ''}$diff', 
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: diff > 0 ? Colors.green : (diff < 0 ? Colors.red : Colors.grey),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isProcessing ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: _isProcessing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Simpan Opname'),
        ),
      ],
    );
  }
}
