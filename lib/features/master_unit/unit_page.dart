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

              final newUnit = Unit(
                id: unit?.id,
                name: nameController.text.trim(),
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
                  mainAxisExtent: 100,
                ),
                itemCount: _controller.units.length,
                itemBuilder: (context, index) {
                  final unit = _controller.units[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                                          content: Text('Hapus ${unit.name}?'),
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
