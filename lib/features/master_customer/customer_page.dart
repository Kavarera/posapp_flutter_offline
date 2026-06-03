import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_customer/customer_controller.dart';
import 'package:posapp_w6zxit6s/core/models/customer.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final CustomerController _controller = Get.put(CustomerController());

  void _showFormDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    
    // Status Dropdown
    String selectedStatus = customer?.status ?? 'Aktif';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(customer == null ? 'Tambah Customer' : 'Ubah Customer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Customer *'),
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
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    Get.snackbar('Validasi', 'Nama Customer wajib diisi!');
                    return;
                  }
                  
                  final newCustomer = Customer(
                    id: customer?.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    address: addressController.text.trim(),
                    status: selectedStatus,
                    receivableBalance: customer?.receivableBalance ?? 0, // Hidden in Phase 1 edit
                  );

                  if (customer == null) {
                    _controller.addCustomer(newCustomer);
                  } else {
                    _controller.updateCustomer(newCustomer);
                  }
                  Get.back();
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        }
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

              return Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Telepon')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Aksi')),
                      ],
                      rows: _controller.customers.map((cust) {
                        return DataRow(cells: [
                          DataCell(Text(cust.name)),
                          DataCell(Text(cust.phone ?? '-')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cust.status == 'Aktif' ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cust.status,
                                style: TextStyle(
                                  color: cust.status == 'Aktif' ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppColors.primary),
                                onPressed: () => _showFormDialog(customer: cust),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error),
                                onPressed: () {
                                  Get.defaultDialog(
                                    title: 'Hapus Customer',
                                    middleText: 'Apakah Anda yakin ingin menghapus ${cust.name}?',
                                    textConfirm: 'Hapus',
                                    textCancel: 'Batal',
                                    confirmTextColor: AppColors.white,
                                    buttonColor: AppColors.error,
                                    onConfirm: () {
                                      _controller.deleteCustomer(cust.id!);
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
