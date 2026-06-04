import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/core/models/unit.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'unit_controller.dart';

class UnitPage extends StatefulWidget {
  const UnitPage({super.key});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  final UnitController _controller = Get.put(UnitController());

  void _showFormDialog({Unit? unit}) {
    final nameController = TextEditingController(text: unit?.name ?? '');
    final multiplierController = TextEditingController(
      text: unit?.multiplierToDerived?.toString() ?? '',
    );
    bool hasDerived = unit?.hasDerived ?? false;
    int? selectedDerivedId = unit?.derivedUnitId;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return CustomDialog(
            title: unit == null ? 'Tambah Satuan' : 'Ubah Satuan',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Satuan *'),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Memiliki Turunan Satuan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Ceklis jika satuan ini memiliki turunan (Misal: 1 Karton = 10 Dus)',
                  ),
                  value: hasDerived,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setDialogState(() {
                      hasDerived = val ?? false;
                      if (!hasDerived) {
                        selectedDerivedId = null;
                        multiplierController.clear();
                      }
                    });
                  },
                ),
                if (hasDerived) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedDerivedId,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Satuan Turunan *',
                    ),
                    items: _controller.units
                        .where(
                          (u) => u.id != unit?.id,
                        ) // Prevent self-reference
                        .map(
                          (u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(u.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedDerivedId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: multiplierController,
                    decoration: const InputDecoration(
                      labelText: 'Nilai Turunan (Kalkulasi) *',
                      helperText:
                          'Contoh: Jika 1 Karton = 10 Dus, isi dengan 10',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ),
            onCancel: () => Get.back(),
            onConfirm: () {
              if (nameController.text.trim().isEmpty) {
                SnackbarHelper.show(
                  'Validasi',
                  'Nama Satuan wajib diisi!',
                  isError: true,
                );
                return;
              }
              if (hasDerived) {
                if (selectedDerivedId == null) {
                  SnackbarHelper.show(
                    'Validasi',
                    'Satuan Turunan harus dipilih!',
                    isError: true,
                  );
                  return;
                }
                if (multiplierController.text.trim().isEmpty ||
                    (int.tryParse(multiplierController.text) ?? 0) <= 0) {
                  SnackbarHelper.show(
                    'Validasi',
                    'Nilai Turunan harus berupa angka lebih dari 0!',
                    isError: true,
                  );
                  return;
                }
              }

              final newUnit = Unit(
                id: unit?.id,
                name: nameController.text.trim(),
                hasDerived: hasDerived,
                derivedUnitId: hasDerived ? selectedDerivedId : null,
                multiplierToDerived: hasDerived
                    ? int.tryParse(multiplierController.text)
                    : null,
              );

              if (unit == null) {
                _controller.addUnit(newUnit);
              } else {
                _controller.updateUnit(newUnit);
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
                'Master Satuan',
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

              if (_controller.units.isEmpty) {
                return const Center(child: Text('Data satuan masih kosong.'));
              }

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: 140,
                ),
                itemCount: _controller.units.length,
                itemBuilder: (context, index) {
                  final unit = _controller.units[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                unit.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
                                        _showFormDialog(unit: unit),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppColors.error,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Get.dialog(
                                        CustomDialog(
                                          title: 'Hapus Satuan',
                                          content: Text(
                                            'Hapus ${unit.name}? Jika dihapus, stok dan harga pada barang akan disesuaikan otomatis.',
                                          ),
                                          confirmText: 'Hapus',
                                          isDestructive: true,
                                          onCancel: () => Get.back(),
                                          onConfirm: () {
                                            _controller.deleteUnit(unit.id!);
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
                          const Spacer(),
                          if (unit.hasDerived) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calculate_outlined,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '1 ${unit.name} = ${unit.multiplierToDerived} ${unit.derivedUnitName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Satuan Utama Dasar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
