import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart';
import 'package:posapp_w6zxit6s/core/services/csv_service.dart';

class CategoryController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var categories = <Category>[].obs;
  var isLoading = false.obs;
  var isImporting = false.obs;

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
      SnackbarHelper.show('Error', 'Gagal memuat kategori', isError: true);
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
      SnackbarHelper.show(
        'Error',
        'Kategori mungkin sudah ada.',
        isError: true,
      );
    }
  }

  Future<void> updateCategory(int id, String name) async {
    try {
      Database db = await _dbHelper.database;
      await db.update(
        'categories',
        {'name': name},
        where: 'id = ?',
        whereArgs: [id],
      );
      _logger.i("Category $id updated");
      await fetchCategories();
    } catch (e) {
      _logger.e("Error updating category", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memperbarui kategori.',
        isError: true,
      );
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
      SnackbarHelper.show('Error', 'Gagal menghapus kategori.', isError: true);
    }
  }

  Future<void> showCategoryProducts(Category category) async {
    try {
      Database db = await _dbHelper.database;
      var products = await db.rawQuery(
        '''
        SELECT name, stock
        FROM products
        WHERE category_id = ?
      ''',
        [category.id],
      );

      Get.dialog(
        AlertDialog(
          title: Text('Produk Kategori ${category.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: products.isEmpty
                ? const Center(
                    child: Text('Tidak ada produk dalam kategori ini.'),
                  )
                : ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      var p = products[index];
                      return ListTile(
                        leading: const Icon(Icons.inventory_2),
                        title: Text(p['name'].toString()),
                        trailing: Text('Stok: ${p['stock']}'),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Tutup')),
          ],
        ),
      );
    } catch (e) {
      _logger.e("Error fetching products for category", error: e);
    }
  }

  Future<void> downloadTemplate() async {
    try {
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan Template CSV Kategori',
        fileName: 'template_kategori.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        String csvData = CsvService.generateTemplate('categories');
        await File(outputPath).writeAsString(csvData);
        SnackbarHelper.show(
          'Sukses',
          'Template berhasil diunduh ke $outputPath',
        );
      }
    } catch (e) {
      _logger.e("Failed to download template", error: e);
      SnackbarHelper.show('Error', 'Gagal mengunduh template', isError: true);
    }
  }

  Future<void> importCsv() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        isImporting.value = true;
        File file = File(result.files.single.path!);
        String csvString = await file.readAsString();

        List<Map<String, dynamic>> parsedData = await CsvService.parseCsvData(
          csvString,
        );

        Database db = await _dbHelper.database;
        List<Map<String, dynamic>> errorRows = [];
        int successCount = 0;

        await db.transaction((txn) async {
          for (var row in parsedData) {
            try {
              if (row['name'] == null ||
                  row['name'].toString().trim().isEmpty) {
                row['error_message'] = 'Nama kategori kosong';
                errorRows.add(row);
                continue;
              }
              // Check existing
              var existing = await txn.query(
                'categories',
                where: 'name = ?',
                whereArgs: [row['name'].toString().trim()],
              );
              if (existing.isNotEmpty) {
                row['error_message'] = 'Kategori sudah ada';
                errorRows.add(row);
                continue;
              }

              await txn.insert('categories', {
                'name': row['name'].toString().trim(),
              });
              successCount++;
            } catch (e) {
              row['error_message'] = e.toString();
              errorRows.add(row);
            }
          }
        });

        if (errorRows.isNotEmpty) {
          await CsvService.saveErrorReport('categories', errorRows);
          SnackbarHelper.show(
            'Import Selesai',
            '$successCount berhasil. ${errorRows.length} gagal (Cek folder Documents/Kavarera/Upload Errors).',
            isError: true,
          );
        } else {
          SnackbarHelper.show(
            'Sukses',
            '$successCount kategori berhasil diimport',
          );
        }
        await fetchCategories();
      }
    } catch (e) {
      _logger.e("Failed to import CSV", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memproses file CSV: ${e.toString()}',
        isError: true,
      );
    } finally {
      isImporting.value = false;
    }
  }
}
