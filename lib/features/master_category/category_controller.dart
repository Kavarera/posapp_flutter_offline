import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart';

class CategoryController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var categories = <Category>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT c.*, COUNT(p.id) as product_count
        FROM categories c
        LEFT JOIN products p ON c.id = p.category_id
        GROUP BY c.id
      ''');
      categories.value = maps.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching categories", error: e);
      Get.snackbar('Error', 'Gagal memuat kategori');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCategory(String name) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('categories', {'name': name});
      _logger.i("Category $name added");
      await fetchCategories();
    } catch (e) {
      _logger.e("Error adding category", error: e);
      Get.snackbar('Error', 'Kategori mungkin sudah ada.');
    }
  }

  Future<void> updateCategory(int id, String name) async {
    try {
      Database db = await _dbHelper.database;
      await db.update('categories', {'name': name}, where: 'id = ?', whereArgs: [id]);
      _logger.i("Category $id updated");
      await fetchCategories();
    } catch (e) {
      _logger.e("Error updating category", error: e);
      Get.snackbar('Error', 'Gagal memperbarui kategori.');
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete('categories', where: 'id = ?', whereArgs: [id]);
      _logger.i("Category $id deleted");
      await fetchCategories();
    } catch (e) {
      _logger.e("Error deleting category", error: e);
      Get.snackbar('Error', 'Gagal menghapus kategori.');
    }
  }
}
