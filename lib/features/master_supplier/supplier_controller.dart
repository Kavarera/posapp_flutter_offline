import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';

class SupplierController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var suppliers = <Supplier>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSuppliers();
  }

  Future<void> fetchSuppliers() async {
    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('suppliers');
      suppliers.value = maps.map((e) => Supplier.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching suppliers", error: e);
      Get.snackbar('Error', 'Gagal memuat supplier');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('suppliers', supplier.toJson());
      _logger.i("Supplier ${supplier.name} added");
      await fetchSuppliers();
    } catch (e) {
      _logger.e("Error adding supplier", error: e);
      Get.snackbar('Error', 'Gagal menambahkan supplier.');
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      Database db = await _dbHelper.database;
      await db.update('suppliers', supplier.toJson(), where: 'id = ?', whereArgs: [supplier.id]);
      _logger.i("Supplier ${supplier.id} updated");
      await fetchSuppliers();
    } catch (e) {
      _logger.e("Error updating supplier", error: e);
      Get.snackbar('Error', 'Gagal memperbarui supplier.');
    }
  }

  Future<void> deleteSupplier(int id) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
      _logger.i("Supplier $id deleted");
      await fetchSuppliers();
    } catch (e) {
      _logger.e("Error deleting supplier", error: e);
      Get.snackbar('Error', 'Gagal menghapus supplier.');
    }
  }

  Future<void> showSupplierProducts(Supplier supplier) async {
    try {
      Database db = await _dbHelper.database;
      var products = await db.rawQuery('''
        SELECT p.name, p.stock
        FROM products p
        JOIN product_suppliers ps ON p.id = ps.product_id
        WHERE ps.supplier_id = ?
      ''', [supplier.id]);

      Get.dialog(
        AlertDialog(
          title: Text('Produk dari ${supplier.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: products.isEmpty
                ? const Center(child: Text('Tidak ada produk dari supplier ini.'))
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
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } catch (e) {
      _logger.e("Error fetching products for supplier", error: e);
    }
  }
}
