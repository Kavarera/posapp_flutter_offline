import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/customer.dart';
import 'package:posapp_w6zxit6s/core/services/csv_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class CustomerController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var customers = <Customer>[].obs;
  var isLoading = false.obs;
  var isImporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('customers');
      customers.value = maps.map((e) => Customer.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching customers", error: e);
      SnackbarHelper.show('Error', 'Gagal memuat customer', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('customers', customer.toJson());
      _logger.i("Customer ${customer.name} added");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error adding customer", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal menambahkan customer.',
        isError: true,
      );
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      Database db = await _dbHelper.database;
      await db.update(
        'customers',
        customer.toJson(),
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      _logger.i("Customer ${customer.id} updated");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error updating customer", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memperbarui customer.',
        isError: true,
      );
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      _logger.i("Customer $id deleted");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error deleting customer", error: e);
      SnackbarHelper.show('Error', 'Gagal menghapus customer.', isError: true);
    }
  }

  Future<void> downloadTemplate() async {
    try {
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan Template CSV Pelanggan',
        fileName: 'template_pelanggan.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        String csvData = CsvService.generateTemplate('customers');
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
                row['error_message'] = 'Nama pelanggan kosong';
                errorRows.add(row);
                continue;
              }

              await txn.insert('customers', {
                'name': row['name'].toString().trim(),
                'phone': row['phone']?.toString().trim() ?? '',
                'address': row['address']?.toString().trim() ?? '',
                'max_credit':
                    double.tryParse(row['max_credit']?.toString() ?? '') ?? 0.0,
                'current_credit': 0.0,
              });
              successCount++;
            } catch (e) {
              row['error_message'] = e.toString();
              errorRows.add(row);
            }
          }
        });

        if (errorRows.isNotEmpty) {
          await CsvService.saveErrorReport('customers', errorRows);
          SnackbarHelper.show(
            'Import Selesai',
            '$successCount berhasil. ${errorRows.length} gagal (Cek folder Documents/Kavarera/Upload Errors).',
            isError: true,
          );
        } else {
          SnackbarHelper.show(
            'Sukses',
            '$successCount pelanggan berhasil diimport',
          );
        }
        await fetchCustomers();
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
