import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_category/category_controller.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final CategoryController _controller = Get.put(CategoryController());

  void _showFormDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');

    Get.dialog(
      AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Ubah Kategori'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                if (category == null) {
                  _controller.addCategory(nameController.text.trim());
                } else {
                  _controller.updateCategory(category.id!, nameController.text.trim());
                }
                Get.back();
              }
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
                'Master Kategori',
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

              if (_controller.categories.isEmpty) {
                return const Center(child: Text('Data kategori masih kosong.'));
              }

              return Card(
                child: ListView.separated(
                  itemCount: _controller.categories.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = _controller.categories[index];
                    return ListTile(
                      title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () => _showFormDialog(category: cat),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () {
                              Get.defaultDialog(
                                title: 'Hapus Kategori',
                                middleText: 'Apakah Anda yakin ingin menghapus kategori ini?',
                                textConfirm: 'Hapus',
                                textCancel: 'Batal',
                                confirmTextColor: AppColors.white,
                                buttonColor: AppColors.error,
                                onConfirm: () {
                                  _controller.deleteCategory(cat.id!);
                                  Get.back();
                                },
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
