import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_supplier/supplier_controller.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  State<SupplierPage> createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final SupplierController _controller = Get.put(SupplierController());

  void _showFormDialog({Supplier? supplier}) {
    final nameController = TextEditingController(text: supplier?.name ?? '');
    final contactController = TextEditingController(
      text: supplier?.contact ?? '',
    );
    final npwpController = TextEditingController(text: supplier?.npwp ?? '');
    final bankController = TextEditingController(
      text: supplier?.bankAccount ?? '',
    );
    final addressController = TextEditingController(
      text: supplier?.address ?? '',
    );

    Get.dialog(
      CustomDialog(
        title: supplier == null ? 'Tambah Supplier' : 'Ubah Supplier',
        content: Column(
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
        onCancel: () => Get.back(),
        onConfirm: () {
          if (nameController.text.trim().isEmpty) {
            SnackbarHelper.show(
              'Validasi',
              'Nama Supplier wajib diisi!',
              isError: true,
            );
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

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
                itemCount: _controller.suppliers.length,
                itemBuilder: (context, index) {
                  final sup = _controller.suppliers[index];
                  return Card(
                    child: InkWell(
                      onTap: () => _controller.showSupplierProducts(sup),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '#${sup.id} - ${sup.name.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text(
                                      sup.npwp?.isNotEmpty == true
                                          ? sup.npwp!
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showFormDialog(supplier: sup),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Get.dialog(
                                        CustomDialog(
                                          title: 'Hapus Supplier',
                                          content: Text(
                                            'Apakah Anda yakin ingin menghapus ${sup.name}?',
                                          ),
                                          confirmText: 'Hapus',
                                          isDestructive: true,
                                          onCancel: () => Get.back(),
                                          onConfirm: () {
                                            _controller.deleteSupplier(sup.id!);
                                            Get.back();
                                          },
                                        ),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                sup.contact?.isNotEmpty == true
                                    ? sup.contact!
                                    : '-',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_balance,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sup.bankAccount?.isNotEmpty == true
                                      ? sup.bankAccount!
                                      : '-',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sup.address?.isNotEmpty == true
                                        ? sup.address!
                                        : '-',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }
}
