import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_product/product_controller.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductController _controller = Get.put(ProductController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _controller.fetchProducts(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showFormDialog({Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final barcodeController = TextEditingController(
      text: product?.barcode ?? '',
    );
    final baseUnitController = TextEditingController(
      text: product?.baseUnit ?? 'Pcs',
    );
    final buyController = TextEditingController(
      text: product?.buyPrice.toString() ?? '0',
    );
    final sellController = TextEditingController(
      text: product?.sellPrice.toString() ?? '0',
    );

    Get.dialog(
      AlertDialog(
        title: Text(product == null ? 'Tambah Barang' : 'Ubah Barang'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode *'),
                enabled:
                    product ==
                    null, // Prevent editing barcode for simplicity in Phase 1
              ),
              const SizedBox(height: 12),
              TextField(
                controller: baseUnitController,
                decoration: const InputDecoration(labelText: 'Satuan Dasar'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: buyController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: sellController,
                      decoration: const InputDecoration(
                        labelText: 'Harga Jual',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  barcodeController.text.trim().isEmpty) {
                Get.snackbar('Validasi', 'Nama dan Barcode wajib diisi!');
                return;
              }

              final newProduct = Product(
                id: product?.id,
                name: nameController.text.trim(),
                barcode: barcodeController.text.trim(),
                baseUnit: baseUnitController.text.trim(),
                buyPrice: double.tryParse(buyController.text) ?? 0,
                sellPrice: double.tryParse(sellController.text) ?? 0,
              );

              if (product == null) {
                _controller.addProduct(newProduct);
              } else {
                _controller.updateProduct(newProduct);
              }
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final pathController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Import CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan path file CSV (misal: C:\\data\\barang.csv)'),
            const SizedBox(height: 12),
            TextField(
              controller: pathController,
              decoration: const InputDecoration(labelText: 'Path File CSV'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (pathController.text.isNotEmpty) {
                _controller.importCsv(pathController.text);
                Get.back();
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

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
                'Master Barang',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      var dir = await getApplicationDocumentsDirectory();
                      _controller.exportCsvTemplate(
                        "${dir.path}\\template_barang.csv",
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.black),
                    label: const Text(
                      'Template CSV',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showImportDialog(),
                    icon: const Icon(Icons.upload_file),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                    ),
                    label: const Text('Import CSV'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Data'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Cari Nama / Barcode...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _controller.onSearchChanged,
          ),
          const SizedBox(height: 16),

          Obx(() {
            if (_controller.isImporting.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Sedang mengimpor data CSV di background..."),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value && _controller.products.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.products.isEmpty) {
                return const Center(
                  child: Text('Data barang tidak ditemukan.'),
                );
              }

              return Card(
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount:
                      _controller.products.length +
                      (_controller.hasMoreData.value ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == _controller.products.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final p = _controller.products[index];
                    return ListTile(
                      title: Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Barcode: ${p.barcode} | Harga: Rp ${p.sellPrice} | Stok: ${p.stock} ${p.baseUnit}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _showFormDialog(product: p),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.error,
                            ),
                            onPressed: () {
                              _controller.deleteProduct(p.id!);
                            },
                          ),
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
