import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/unit.dart';
import 'package:posapp_w6zxit6s/core/services/csv_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class UnitController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var units = <Unit>[].obs;
  var isLoading = false.obs;
  var isImporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUnits();
  }

  Future<void> fetchUnits() async {
    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;

      final List<Map<String, dynamic>> maps = await db.query('units');
      units.value = maps.map((e) => Unit.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching units", error: e);
      SnackbarHelper.show('Error', 'Gagal memuat data satuan', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUnit(Unit unit) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('units', unit.toJson());
      _logger.i("Unit ${unit.name} added");
      await fetchUnits();
    } catch (e) {
      _logger.e("Error adding unit", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal menambahkan satuan. Nama mungkin duplikat.',
        isError: true,
      );
    }
  }

  Future<void> updateUnit(Unit unit) async {
    try {
      Database db = await _dbHelper.database;
      await db.update(
        'units',
        unit.toJson(),
        where: 'id = ?',
        whereArgs: [unit.id],
      );
      _logger.i("Unit ${unit.id} updated");
      await fetchUnits();
    } catch (e) {
      _logger.e("Error updating unit", error: e);
      SnackbarHelper.show('Error', 'Gagal memperbarui satuan.', isError: true);
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      Database db = await _dbHelper.database;

      await db.delete('units', where: 'id = ?', whereArgs: [id]);

      _logger.i("Unit $id deleted");
      await fetchUnits();
      SnackbarHelper.show('Sukses', 'Satuan berhasil dihapus.');
    } catch (e) {
      _logger.e("Error deleting unit", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal menghapus satuan. Pastikan tidak ada barang yang menggunakan satuan ini.',
        isError: true,
      );
    }
  }

  Future<void> downloadTemplate() async {
    try {
      String? outputPath = await FilePicker.saveFile(
        dialogTitle: 'Simpan Template CSV Satuan',
        fileName: 'template_satuan.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (outputPath != null) {
        String csvData = CsvService.generateTemplate('units');
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
                row['error_message'] = 'Nama satuan kosong';
                errorRows.add(row);
                continue;
              }

              var existing = await txn.query(
                'units',
                where: 'name = ?',
                whereArgs: [row['name'].toString().trim()],
              );
              if (existing.isNotEmpty) {
                row['error_message'] = 'Satuan sudah ada';
                errorRows.add(row);
                continue;
              }

              await txn.insert('units', {
                'name': row['name'].toString().trim(),
                'symbol': row['symbol']?.toString().trim() ?? '',
              });
              successCount++;
            } catch (e) {
              row['error_message'] = e.toString();
              errorRows.add(row);
            }
          }
        });

        if (errorRows.isNotEmpty) {
          await CsvService.saveErrorReport('units', errorRows);
          SnackbarHelper.show(
            'Import Selesai',
            '$successCount berhasil. ${errorRows.length} gagal (Cek folder Documents/Kavarera/Upload Errors).',
          );
        } else {
          SnackbarHelper.show(
            'Sukses',
            '$successCount satuan berhasil diimport',
          );
        }
        await fetchUnits();
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
