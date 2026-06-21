import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/services/csv_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class SupplierController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var suppliers = <Supplier>[].obs;
  var isLoading = false.obs;
  var isImporting = false.obs;

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
      SnackbarHelper.show('Error', 'Gagal memuat supplier', isError: true);
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
      SnackbarHelper.show(
        'Error',
        'Gagal menambahkan supplier.',
        isError: true,
      );
    }
  }

  Future<void> updateSupplier(Supplier supplier) async {
    try {
      Database db = await _dbHelper.database;
      await db.update(
        'suppliers',
        supplier.toJson(),
        where: 'id = ?',
        whereArgs: [supplier.id],
      );
      _logger.i("Supplier ${supplier.id} updated");
      await fetchSuppliers();
    } catch (e) {
      _logger.e("Error updating supplier", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memperbarui supplier.',
        isError: true,
      );
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
      SnackbarHelper.show('Error', 'Gagal menghapus supplier.', isError: true);
    }
  }

  Future<void> showSupplierProducts(Supplier supplier) async {
    try {
      Database db = await _dbHelper.database;
      var products = await db.rawQuery(
        '''
        SELECT p.name, p.stock
        FROM products p
        JOIN product_suppliers ps ON p.id = ps.product_id
        WHERE ps.supplier_id = ? AND p.id != -1
      ''',
        [supplier.id],
      );

      Get.dialog(
        AlertDialog(
          title: Text('Produk dari ${supplier.name}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: products.isEmpty
                ? const Center(
                    child: Text('Tidak ada produk dari supplier ini.'),
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
      _logger.e("Error fetching products for supplier", error: e);
    }
  }

  Future<void> downloadTemplate() async {
    try {
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan Template CSV Supplier',
        fileName: 'template_supplier.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        String csvData = CsvService.generateTemplate('suppliers');
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
                row['error_message'] = 'Nama supplier kosong';
                errorRows.add(row);
                continue;
              }

              await txn.insert('suppliers', {
                'name': row['name'].toString().trim(),
                'contact': row['contact']?.toString().trim() ?? '',
                'phone': row['phone']?.toString().trim() ?? '',
                'address': row['address']?.toString().trim() ?? '',
              });
              successCount++;
            } catch (e) {
              row['error_message'] = e.toString();
              errorRows.add(row);
            }
          }
        });

        if (errorRows.isNotEmpty) {
          await CsvService.saveErrorReport('suppliers', errorRows);
          SnackbarHelper.show(
            'Import Selesai',
            '$successCount berhasil. ${errorRows.length} gagal (Cek folder Documents/Kavarera/Upload Errors).',
            isError: true,
          );
        } else {
          SnackbarHelper.show(
            'Sukses',
            '$successCount supplier berhasil diimport',
          );
        }
        await fetchSuppliers();
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
