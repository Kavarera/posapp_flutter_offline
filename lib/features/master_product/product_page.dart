import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart';
import 'package:posapp_w6zxit6s/core/models/unit.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_product/product_controller.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/models/product_unit.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class _TempProductUnit {
  int? unitId;
  int? parentUnitId;
  TextEditingController multiplierController;

  _TempProductUnit({this.unitId, this.parentUnitId, String multiplier = ''})
    : multiplierController = TextEditingController(text: multiplier);
}

class ProductPage extends StatefulWidget {
  final bool autoOpenAddDialog;
  const ProductPage({super.key, this.autoOpenAddDialog = false});

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

    if (widget.autoOpenAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFormDialog(product: null);
      });
    }
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
    final buyController = TextEditingController(
      text: product?.buyPrice.toString() ?? '0',
    );
    final sellController = TextEditingController(
      text: product?.sellPrice.toString() ?? '0',
    );
    final minStockController = TextEditingController(
      text: product?.minStock.toString() ?? '0',
    );

    int? selectedCategoryId = product?.categoryId;
    int? selectedUnitId = product?.unitId; // Base Unit
    List<int> selectedSuppliers = List<int>.from(product?.supplierIds ?? []);

    // Dynamic derived units
    List<_TempProductUnit> tempDerivedUnits = [];
    if (product != null && product.productUnits.isNotEmpty) {
      for (var pu in product.productUnits) {
        if (!pu.isBase) {
          tempDerivedUnits.add(
            _TempProductUnit(
              unitId: pu.unitId,
              parentUnitId: pu.parentUnitId,
              multiplier: pu.multiplierToParent?.toString() ?? '',
            ),
          );
        }
      }
    }

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return CustomDialog(
            title: product == null ? 'Tambah Barang' : 'Ubah Barang',
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: 600,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Barang *',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode/SKU *',
                      ),
                      enabled: product == null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Tidak ada'),
                        ),
                        ..._controller.categories.map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) =>
                          setDialogState(() => selectedCategoryId = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: selectedUnitId,
                            decoration: const InputDecoration(
                              labelText: 'Satuan Utama (Dasar) *',
                            ),
                            items: _controller.units
                                .map(
                                  (u) => DropdownMenuItem<int>(
                                    value: u.id,
                                    child: Text(u.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedUnitId = val),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          message:
                              'Info Satuan Utama:\\n• Menjadi satuan dasar stok.\\n• Semua transaksi mengacu kesini.',
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text(
                      'Satuan Turunan (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...tempDerivedUnits.asMap().entries.map((entry) {
                      int idx = entry.key;
                      _TempProductUnit tempUnit = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: tempUnit.unitId,
                                decoration: const InputDecoration(
                                  labelText: 'Pilih Satuan',
                                ),
                                items: _controller.units
                                    .where((u) => u.id != selectedUnitId)
                                    .map(
                                      (u) => DropdownMenuItem<int>(
                                        value: u.id,
                                        child: Text(u.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) =>
                                    setDialogState(() => tempUnit.unitId = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('='),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: tempUnit.multiplierController,
                                decoration: const InputDecoration(
                                  labelText: 'Jumlah',
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<int>(
                                value: tempUnit.parentUnitId,
                                decoration: const InputDecoration(
                                  labelText: 'Terhadap Satuan',
                                ),
                                items: _controller.units
                                    .map(
                                      (u) => DropdownMenuItem<int>(
                                        value: u.id,
                                        child: Text(u.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) => setDialogState(
                                  () => tempUnit.parentUnitId = val,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                              ),
                              onPressed: () => setDialogState(
                                () => tempDerivedUnits.removeAt(idx),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    TextButton.icon(
                      onPressed: () {
                        if (selectedUnitId == null) {
                          SnackbarHelper.show(
                            'Validasi',
                            'Pilih Satuan Utama terlebih dahulu!',
                            isError: true,
                          );
                          return;
                        }
                        setDialogState(
                          () => tempDerivedUnits.add(
                            _TempProductUnit(parentUnitId: selectedUnitId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Satuan Turunan'),
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: buyController,
                            decoration: const InputDecoration(
                              labelText: 'Harga Beli (Satuan Dasar)',
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: minStockController,
                      decoration: const InputDecoration(
                        labelText: 'Batas Stok Minimum',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Supplier',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _controller.suppliers.map((sup) {
                        return FilterChip(
                          label: Text(sup.name),
                          selected: selectedSuppliers.contains(sup.id),
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected)
                                selectedSuppliers.add(sup.id!);
                              else
                                selectedSuppliers.remove(sup.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            onCancel: () => Get.back(),
            onConfirm: () {
              if (nameController.text.trim().isEmpty ||
                  barcodeController.text.trim().isEmpty) {
                SnackbarHelper.show(
                  'Validasi',
                  'Nama dan Barcode wajib diisi!',
                  isError: true,
                );
                return;
              }
              if (selectedUnitId == null) {
                SnackbarHelper.show(
                  'Validasi',
                  'Satuan Utama wajib dipilih!',
                  isError: true,
                );
                return;
              }

              // Build Product Units array and calculate base multiplier
              List<ProductUnit> finalProductUnits = [];
              finalProductUnits.add(
                ProductUnit(
                  productId: product?.id ?? 0,
                  unitId: selectedUnitId!,
                  isBase: true,
                  multiplierToBase: 1,
                ),
              );

              int calcMult(int targetUnitId) {
                if (targetUnitId == selectedUnitId) return 1;
                var tpu = tempDerivedUnits.firstWhereOrNull(
                  (e) => e.unitId == targetUnitId,
                );
                if (tpu == null || tpu.parentUnitId == null) return 1;
                int parentM = calcMult(tpu.parentUnitId!);
                int myM = int.tryParse(tpu.multiplierController.text) ?? 1;
                return myM * parentM;
              }

              for (var tpu in tempDerivedUnits) {
                if (tpu.unitId == null || tpu.parentUnitId == null) {
                  SnackbarHelper.show(
                    'Validasi',
                    'Mohon lengkapi pilihan Satuan Turunan',
                    isError: true,
                  );
                  return;
                }
                int myMult = int.tryParse(tpu.multiplierController.text) ?? 0;
                if (myMult <= 0) {
                  SnackbarHelper.show(
                    'Validasi',
                    'Multiplier harus > 0',
                    isError: true,
                  );
                  return;
                }
                finalProductUnits.add(
                  ProductUnit(
                    productId: product?.id ?? 0,
                    unitId: tpu.unitId!,
                    isBase: false,
                    parentUnitId: tpu.parentUnitId,
                    multiplierToParent: myMult,
                    multiplierToBase: calcMult(tpu.unitId!),
                  ),
                );
              }

              final newProduct = Product(
                id: product?.id,
                name: nameController.text.trim(),
                barcode: barcodeController.text.trim(),
                categoryId: selectedCategoryId,
                unitId: selectedUnitId,
                buyPrice: double.tryParse(buyController.text) ?? 0,
                sellPrice: double.tryParse(sellController.text) ?? 0,
                minStock: int.tryParse(minStockController.text) ?? 0,
                stock: product?.stock ?? 0,
                supplierIds: selectedSuppliers,
                productUnits: finalProductUnits,
              );

              if (product == null) {
                _controller.addProduct(newProduct);
              } else {
                _controller.updateProduct(newProduct);
              }
              Get.back();
            },
          );
        },
      ),
    );
  }

  void _showImportDialog() {
    final pathController = TextEditingController();
    Get.dialog(
      CustomDialog(
        title: 'Import CSV',
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
        confirmText: 'Import',
        onCancel: () => Get.back(),
        onConfirm: () {
          if (pathController.text.isNotEmpty) {
            _controller.importCsv(pathController.text);
            Get.back();
          }
        },
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
                      String dir = PathService.templatesDir;
                      _controller.exportCsvTemplate(
                        "$dir\\template_barang.csv",
                      );
                    },
                    icon: const Icon(Icons.download, color: Colors.black),
                    label: const Text(
                      'Template CSV',
                      style: TextStyle(color: Colors.black),
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
                    onPressed: () {
                      if (_controller.units.isEmpty) {
                        SnackbarHelper.show(
                          'Perhatian',
                          'Harap isi Master Satuan terlebih dahulu sebelum menambah barang.',
                          isError: true,
                        );
                        return;
                      }
                      _showFormDialog();
                    },
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      title: Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "SKU: ${p.barcode}",
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  p.categoryName ?? 'Tanpa Kategori',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Harga: Rp ${p.sellPrice} | Stok: ${p.stock} ${p.unitName ?? '-'} (Min: ${p.minStock})",
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (p.supplierNames != null &&
                              p.supplierNames!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              "Supplier: ${p.supplierNames}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
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
                              Get.dialog(
                                CustomDialog(
                                  title: 'Hapus Barang',
                                  content: Text(
                                    'Apakah Anda yakin ingin menghapus ${p.name}?',
                                  ),
                                  confirmText: 'Hapus',
                                  isDestructive: true,
                                  onCancel: () => Get.back(),
                                  onConfirm: () {
                                    _controller.deleteProduct(p.id!);
                                    Get.back();
                                  },
                                ),
                              );
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
