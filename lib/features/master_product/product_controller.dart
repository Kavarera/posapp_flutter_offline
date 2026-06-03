import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/utils/csv_helper.dart';

class ProductController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var products = <Product>[].obs;
  var isLoading = false.obs;
  var isImporting = false.obs;
  
  // Pagination
  final int limit = 50;
  var offset = 0;
  var hasMoreData = true.obs;
  
  // Search
  var searchQuery = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
      offset = 0;
      products.clear();
      hasMoreData.value = true;
      fetchProducts();
    });
  }

  Future<void> fetchProducts({bool loadMore = false}) async {
    if (isLoading.value || !hasMoreData.value && loadMore) return;

    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;
      
      String whereClause = '';
      List<dynamic> whereArgs = [];
      
      if (searchQuery.value.isNotEmpty) {
        whereClause = 'name LIKE ? OR barcode LIKE ?';
        whereArgs = ['%${searchQuery.value}%', '%${searchQuery.value}%'];
      }

      final List<Map<String, dynamic>> maps = await db.query(
        'products',
        where: whereClause.isEmpty ? null : whereClause,
        whereArgs: whereArgs.isEmpty ? null : whereArgs,
        limit: limit,
        offset: offset,
      );

      if (maps.length < limit) {
        hasMoreData.value = false;
      }

      var newProducts = maps.map((e) => Product.fromJson(e)).toList();
      
      if (loadMore) {
        products.addAll(newProducts);
      } else {
        products.value = newProducts;
      }
      
      offset += limit;
      
    } catch (e) {
      _logger.e("Error fetching products", error: e);
      Get.snackbar('Error', 'Gagal memuat barang');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('products', product.toJson());
      _logger.i("Product ${product.name} added");
      offset = 0;
      hasMoreData.value = true;
      products.clear();
      await fetchProducts();
    } catch (e) {
      _logger.e("Error adding product", error: e);
      Get.snackbar('Error', 'Gagal menambahkan barang (Barcode mungkin duplikat).');
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      Database db = await _dbHelper.database;
      await db.update('products', product.toJson(), where: 'id = ?', whereArgs: [product.id]);
      _logger.i("Product ${product.id} updated");
      offset = 0;
      hasMoreData.value = true;
      products.clear();
      await fetchProducts();
    } catch (e) {
      _logger.e("Error updating product", error: e);
      Get.snackbar('Error', 'Gagal memperbarui barang.');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      _logger.i("Product $id deleted");
      products.removeWhere((p) => p.id == id);
    } catch (e) {
      _logger.e("Error deleting product", error: e);
      Get.snackbar('Error', 'Gagal menghapus barang.');
    }
  }

  Future<void> exportCsvTemplate(String path) async {
    try {
      String csv = CsvHelper.generateCsvTemplate();
      File file = File(path);
      await file.writeAsString(csv);
      Get.snackbar('Sukses', 'Template CSV berhasil diekspor ke $path');
    } catch (e) {
      _logger.e("Export CSV failed", error: e);
      Get.snackbar('Error', 'Gagal mengekspor CSV.');
    }
  }

  Future<void> importCsv(String filePath) async {
    try {
      isImporting.value = true;
      File file = File(filePath);
      String csvString = await file.readAsString();
      
      // Parse CSV in isolate
      List<Map<String, dynamic>> parsedData = await compute(CsvHelper.parseCsvData, csvString);
      
      if (parsedData.isEmpty) {
        throw Exception("File CSV kosong atau format tidak valid.");
      }

      Database db = await _dbHelper.database;
      
      // Upsert logic inside a transaction
      await db.transaction((txn) async {
        for (var row in parsedData) {
          String barcode = row['barcode'].toString();
          
          List<Map<String, Object?>> existing = await txn.query('products', where: 'barcode = ?', whereArgs: [barcode]);
          
          if (existing.isNotEmpty) {
            // Update
            await txn.update('products', {
              'name': row['name'],
              'buy_price': double.tryParse(row['buy_price'].toString()) ?? 0.0,
              'buy_price_ppn': double.tryParse(row['buy_price_ppn'].toString()) ?? 0.0,
              'sell_price': double.tryParse(row['sell_price'].toString()) ?? 0.0,
              'stock': int.tryParse(row['stock'].toString()) ?? 0,
            }, where: 'barcode = ?', whereArgs: [barcode]);
          } else {
            // Insert
            await txn.insert('products', {
              'name': row['name'],
              'barcode': barcode,
              'base_unit': row['base_unit']?.toString() ?? 'Pcs',
              'buy_price': double.tryParse(row['buy_price'].toString()) ?? 0.0,
              'buy_price_ppn': double.tryParse(row['buy_price_ppn'].toString()) ?? 0.0,
              'sell_price': double.tryParse(row['sell_price'].toString()) ?? 0.0,
              'stock': int.tryParse(row['stock'].toString()) ?? 0,
              'min_stock': int.tryParse(row['min_stock'].toString()) ?? 0,
            });
          }
        }
      });
      
      _logger.i("CSV Import successful");
      Get.snackbar('Sukses', 'Data barang berhasil diimpor.');
      
      offset = 0;
      products.clear();
      hasMoreData.value = true;
      await fetchProducts();

    } catch (e) {
      _logger.e("CSV Import failed", error: e);
      Get.snackbar('Error', 'Gagal mengimpor CSV: $e');
    } finally {
      isImporting.value = false;
    }
  }
}
