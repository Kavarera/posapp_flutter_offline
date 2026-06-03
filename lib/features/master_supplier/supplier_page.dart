import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_supplier/supplier_controller.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final SupplierController _controller = Get.put(SupplierController());

  void _showFormDialog({Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController = TextEditingController(text: supplier?.contact ?? '');
    final npwpController = TextEditingController(text: supplier?.npwp ?? '');
    final bankController = TextEditingController(text: supplier?.bankAccount ?? '');
    final addressController = TextEditingController(text: supplier?.address ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Ubah Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Supplier *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Kontak / Telepon'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: npwpController,
                decoration: const InputDecoration(labelText: 'NPWP'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bankController,
                decoration: const InputDecoration(labelText: 'Rekening Bank'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                Get.snackbar('Validasi', 'Nama Supplier wajib diisi!');
                return;
              }
              
              final newSupplier = Supplier(
                id: supplier?.id,
                name: nameController.text.trim(),
                contact: contactController.text.trim(),
                npwp: npwpController.text.trim(),
                bankAccount: bankController.text.trim(),
                address: addressController.text.trim(),
              );

              if (supplier == null) {
                _controller.addSupplier(newSupplier);
              } else {
                _controller.updateSupplier(newSupplier);
              }
              Get.back();
            },
            child: const Text('Simpan'),
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
                'Master Supplier',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Data'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.suppliers.isEmpty) {
                return const Center(child: Text('Data supplier masih kosong.'));
              }

              return Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Kontak')),
                        DataColumn(label: Text('Bank')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: _controller.suppliers.map((sup) {
                        return DataRow(cells: [
                          DataCell(Text(sup.name)),
                          DataCell(Text(sup.contact ?? '-')),
                          DataCell(Text(sup.bankAccount ?? '-')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () => _showFormDialog(supplier: sup),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Hapus Supplier',
                                    middleText: 'Apakah Anda yakin ingin menghapus ${sup.name}?',
                                    textConfirm: 'Hapus',
                                    textCancel: 'Batal',
                                    confirmTextColor: AppColors.white,
                                    buttonColor: AppColors.error,
                                    onConfirm: () {
                                      _controller.deleteSupplier(sup.id!);
                                      Get.back();
                                    },
                                  );
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
