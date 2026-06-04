import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_customer/customer_controller.dart';
import 'package:posapp_w6zxit6s/core/models/customer.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerController _controller = Get.put(CustomerController());

  String _calculateDuration(String? createdAtStr) {
    if (createdAtStr == null) return '-';
    DateTime? createdAt = DateTime.tryParse(createdAtStr);
    if (createdAt == null) return '-';
    Duration diff = DateTime.now().difference(createdAt);
    if (diff.inDays >= 365) return '${(diff.inDays / 365).floor()} tahun';
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} bulan';
    if (diff.inDays > 0) return '${diff.inDays} hari';
    if (diff.inHours > 0) return '${diff.inHours} jam';
    return 'Baru terdaftar';
  }

  void _showFormDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(
      text: customer?.address ?? '',
    );

    // Status Dropdown
    String selectedStatus = customer?.status ?? 'Aktif';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return CustomDialog(
            title: customer == null ? 'Tambah Customer' : 'Ubah Customer',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Customer *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                    DropdownMenuItem(value: 'Blokir', child: Text('Blokir')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedStatus = val);
                    }
                  },
                ),
              ],
            ),
            onCancel: () => Get.back(),
            onConfirm: () {
              if (nameController.text.trim().isEmpty) {
                SnackbarHelper.show(
                  'Validasi',
                  'Nama Customer wajib diisi!',
                  isError: true,
                );
                return;
              }

              final newCustomer = Customer(
                id: customer?.id,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                address: addressController.text.trim(),
                status: selectedStatus,
                receivableBalance:
                    customer?.receivableBalance ?? 0, // Hidden in Phase 1 edit
                createdAt:
                    customer?.createdAt ?? DateTime.now().toIso8601String(),
              );

              if (customer == null) {
                _controller.addCustomer(newCustomer);
              } else {
                _controller.updateCustomer(newCustomer);
              }
              Get.back();
            },
          );
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
                'Master Customer',
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

              if (_controller.customers.isEmpty) {
                return const Center(child: Text('Data customer masih kosong.'));
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.4,
                ),
                itemCount: _controller.customers.length,
                itemBuilder: (context, index) {
                  final cust = _controller.customers[index];
                  return Card(
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
                                child: Text(
                                  cust.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                                        _showFormDialog(customer: cust),
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
                                          title: 'Hapus Customer',
                                          content: Text(
                                            'Apakah Anda yakin ingin menghapus ${cust.name}?',
                                          ),
                                          confirmText: 'Hapus',
                                          isDestructive: true,
                                          onCancel: () => Get.back(),
                                          onConfirm: () {
                                            _controller.deleteCustomer(
                                              cust.id!,
                                            );
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
                          Container(
                            margin: const EdgeInsets.only(top: 4, bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: cust.status == 'Aktif'
                                  ? AppColors.success.withOpacity(0.1)
                                  : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: cust.status == 'Aktif'
                                    ? AppColors.success.withOpacity(0.5)
                                    : AppColors.error.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              cust.status,
                              style: TextStyle(
                                fontSize: 12,
                                color: cust.status == 'Aktif'
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cust.phone?.isNotEmpty == true
                                    ? cust.phone!
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
                                Icons.location_on,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cust.address?.isNotEmpty == true
                                      ? cust.address!
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
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Terdaftar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _calculateDuration(cust.createdAt),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Saldo Piutang',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${cust.receivableBalance.toInt()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
