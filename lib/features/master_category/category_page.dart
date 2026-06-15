import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/master_category/category_controller.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart';
import 'package:posapp_w6zxit6s/core/widgets/custom_dialog.dart';

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
      CustomDialog(
        title: category == null ? 'Tambah Kategori' : 'Ubah Kategori',
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        onCancel: () => Get.back(),
        onConfirm: () {
          if (nameController.text.trim().isNotEmpty) {
            if (category == null) {
              _controller.addCategory(nameController.text.trim());
            } else {
              _controller.updateCategory(
                category.id!,
                nameController.text.trim(),
              );
            }
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

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 250,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: _controller.categories.length,
                itemBuilder: (context, index) {
                  final cat = _controller.categories[index];
                  return Card(
                    child: InkWell(
                      onTap: () => _controller.showCategoryProducts(cat),
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
                                  child: Text(
                                    '#${cat.id} - ${cat.name}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 2,
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
                                          _showFormDialog(category: cat),
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
                                            title: 'Hapus Kategori',
                                            content: const Text(
                                              'Apakah Anda yakin ingin menghapus kategori ini?',
                                            ),
                                            confirmText: 'Hapus',
                                            isDestructive: true,
                                            onCancel: () => Get.back(),
                                            onConfirm: () {
                                              _controller.deleteCategory(
                                                cat.id!,
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
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${cat.productCount} Barang',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
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
