import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'dart:async';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/models/category.dart' as category_model;
import 'package:posapp_w6zxit6s/core/models/unit.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/models/product_unit.dart';
import 'package:posapp_w6zxit6s/core/utils/csv_helper.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class ProductController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var products = <Product>[].obs;
  var categories = <category_model.Category>[].obs;
  var units = <Unit>[].obs;
  var suppliers = <Supplier>[].obs;

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
    fetchDependencies();
    fetchProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> fetchDependencies() async {
    try {
      Database db = await _dbHelper.database;

      final catMaps = await db.query('categories');
      categories.value = catMaps
          .map((e) => category_model.Category.fromJson(e))
          .toList();

      final unitMaps = await db.query('units');
      units.value = unitMaps.map((e) => Unit.fromJson(e)).toList();

      final supMaps = await db.query('suppliers');
      suppliers.value = supMaps.map((e) => Supplier.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching dependencies", error: e);
    }
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

      String searchCondition = '';
      if (searchQuery.value.isNotEmpty) {
        searchCondition =
            'WHERE p.name LIKE "%${searchQuery.value}%" OR p.barcode LIKE "%${searchQuery.value}%"';
      }

      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT p.*, 
               c.name as category_name, 
               u.name as unit_name,
               GROUP_CONCAT(s.name, ', ') as supplier_names
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        LEFT JOIN units u ON p.unit_id = u.id
        LEFT JOIN product_suppliers ps ON p.id = ps.product_id
        LEFT JOIN suppliers s ON ps.supplier_id = s.id
        $searchCondition
        GROUP BY p.id
        LIMIT $limit OFFSET $offset
      ''');

      if (maps.length < limit) {
        hasMoreData.value = false;
      }

      var newProducts = maps.map((e) => Product.fromJson(e)).toList();

      // Fetch exact supplier IDs for each product to make editing easier
      for (var p in newProducts) {
        final psMaps = await db.query(
          'product_suppliers',
          columns: ['supplier_id'],
          where: 'product_id = ?',
          whereArgs: [p.id],
        );
        p.supplierIds = psMaps.map((e) => e['supplier_id'] as int).toList();

        final puMaps = await db.rawQuery(
          '''
          SELECT pu.*, 
                 u1.name as unit_name, 
                 u2.name as parent_unit_name
          FROM product_units pu
          LEFT JOIN units u1 ON pu.unit_id = u1.id
          LEFT JOIN units u2 ON pu.parent_unit_id = u2.id
          WHERE pu.product_id = ?
        ''',
          [p.id],
        );
        p.productUnits = puMaps.map((e) => ProductUnit.fromJson(e)).toList();
      }

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

      await db.transaction((txn) async {
        final newJson = product.toJson();
        newJson['created_at'] = DateTime.now().toIso8601String();
        int productId = await txn.insert('products', newJson);

        for (int supId in product.supplierIds) {
          await txn.insert('product_suppliers', {
            'product_id': productId,
            'supplier_id': supId,
          });
        }

        for (var pu in product.productUnits) {
          await txn.insert('product_units', {
            'product_id': productId,
            'unit_id': pu.unitId,
            'is_base': pu.isBase ? 1 : 0,
            'parent_unit_id': pu.parentUnitId,
            'multiplier_to_parent': pu.multiplierToParent,
            'multiplier_to_base': pu.multiplierToBase,
          });
        }
      });

      _logger.i("Product ${product.name} added");
      offset = 0;
      hasMoreData.value = true;
      products.clear();
      await fetchProducts();
    } catch (e) {
      _logger.e("Error adding product", error: e);
      Get.snackbar(
        'Error',
        'Gagal menambahkan barang (Barcode mungkin duplikat).',
      );
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      Database db = await _dbHelper.database;

      await db.transaction((txn) async {
        final newJson = product.toJson();
        newJson['updated_at'] = DateTime.now().toIso8601String();
        await txn.update(
          'products',
          newJson,
          where: 'id = ?',
          whereArgs: [product.id],
        );

        // Update product_suppliers: delete all existing, insert new
        await txn.delete(
          'product_suppliers',
          where: 'product_id = ?',
          whereArgs: [product.id],
        );
        for (int supId in product.supplierIds) {
          await txn.insert('product_suppliers', {
            'product_id': product.id,
            'supplier_id': supId,
          });
        }

        await txn.delete(
          'product_units',
          where: 'product_id = ?',
          whereArgs: [product.id],
        );
        for (var pu in product.productUnits) {
          await txn.insert('product_units', {
            'product_id': product.id,
            'unit_id': pu.unitId,
            'is_base': pu.isBase ? 1 : 0,
            'parent_unit_id': pu.parentUnitId,
            'multiplier_to_parent': pu.multiplierToParent,
            'multiplier_to_base': pu.multiplierToBase,
          });
        }
      });

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
      file.parent.createSync(recursive: true);
      await file.writeAsString(csv);
      SnackbarHelper.show(
        'Sukses',
        'Template CSV berhasil diekspor ke $path',
        isError: false,
      );
    } catch (e) {
      _logger.e("Export CSV failed", error: e);
      SnackbarHelper.show('Error', 'Gagal mengekspor CSV.', isError: true);
    }
  }

  Future<void> importCsv(String filePath) async {
    try {
      isImporting.value = true;
      File file = File(filePath);
      String csvString = await file.readAsString();

      // Parse CSV in isolate
      List<Map<String, dynamic>> parsedData = await compute(
        CsvHelper.parseCsvData,
        csvString,
      );

      if (parsedData.isEmpty) {
        throw Exception("File CSV kosong atau format tidak valid.");
      }

      Database db = await _dbHelper.database;

      // Upsert logic inside a transaction
      await db.transaction((txn) async {
        for (var row in parsedData) {
          String barcode = row['barcode'].toString();

          List<Map<String, Object?>> existing = await txn.query(
            'products',
            where: 'barcode = ?',
            whereArgs: [barcode],
          );

          if (existing.isNotEmpty) {
            // Update
            await txn.update(
              'products',
              {
                'name': row['name'],
                'category_id': int.tryParse(row['category_id']?.toString() ?? ''),
                'unit_id': int.tryParse(row['unit_id']?.toString() ?? '') ?? 1,
                'buy_price':
                    double.tryParse(row['buy_price'].toString()) ?? 0.0,
                'buy_price_ppn':
                    double.tryParse(row['buy_price_ppn'].toString()) ?? 0.0,
                'sell_price':
                    double.tryParse(row['sell_price'].toString()) ?? 0.0,
                'stock': int.tryParse(row['stock'].toString()) ?? 0,
              },
              where: 'barcode = ?',
              whereArgs: [barcode],
            );
            
            // Note: Since base unit might change, we ideally should update product_units.
            // But to keep it simple and safe for CSV imports, we ensure base unit exists
            int productId = existing.first['id'] as int;
            int unitId = int.tryParse(row['unit_id']?.toString() ?? '') ?? 1;
            
            List<Map<String, Object?>> existingUnits = await txn.query(
              'product_units',
              where: 'product_id = ? AND is_base = 1',
              whereArgs: [productId],
            );
            if (existingUnits.isEmpty) {
               await txn.insert('product_units', {
                  'product_id': productId,
                  'unit_id': unitId,
                  'is_base': 1,
                  'multiplier_to_base': 1,
               });
            } else {
               await txn.update('product_units', {
                  'unit_id': unitId,
               }, where: 'product_id = ? AND is_base = 1', whereArgs: [productId]);
            }
          } else {
            // Insert
            int unitId = int.tryParse(row['unit_id']?.toString() ?? '') ?? 1;
            int productId = await txn.insert('products', {
              'name': row['name'],
              'barcode': barcode,
              'category_id': int.tryParse(row['category_id']?.toString() ?? ''),
              'unit_id': unitId,
              'buy_price': double.tryParse(row['buy_price'].toString()) ?? 0.0,
              'buy_price_ppn':
                  double.tryParse(row['buy_price_ppn'].toString()) ?? 0.0,
              'sell_price':
                  double.tryParse(row['sell_price'].toString()) ?? 0.0,
              'stock': int.tryParse(row['stock'].toString()) ?? 0,
              'min_stock': int.tryParse(row['min_stock'].toString()) ?? 0,
            });
            
            // Insert base unit
            await txn.insert('product_units', {
                'product_id': productId,
                'unit_id': unitId,
                'is_base': 1,
                'multiplier_to_base': 1,
            });
          }
        }
      });

      _logger.i("CSV Import successful");
      SnackbarHelper.show(
        'Sukses',
        'Data barang berhasil diimpor.',
        isError: false,
      );

      offset = 0;
      products.clear();
      hasMoreData.value = true;
      await fetchProducts();
    } catch (e) {
      _logger.e("CSV Import failed", error: e);
      SnackbarHelper.show('Error', 'Gagal mengimpor CSV: $e', isError: true);
    } finally {
      isImporting.value = false;
    }
  }
}
