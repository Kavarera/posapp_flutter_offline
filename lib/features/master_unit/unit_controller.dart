import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/unit.dart';

class UnitController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var units = <Unit>[].obs;
  var isLoading = false.obs;

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
      Get.snackbar('Error', 'Gagal memuat data satuan');
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
      Get.snackbar('Error', 'Gagal menambahkan satuan. Nama mungkin duplikat.');
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
      Get.snackbar('Error', 'Gagal memperbarui satuan.');
    }
  }

  Future<void> deleteUnit(int id) async {
    try {
      Database db = await _dbHelper.database;

      await db.delete('units', where: 'id = ?', whereArgs: [id]);

      _logger.i("Unit $id deleted");
      await fetchUnits();
      Get.snackbar('Sukses', 'Satuan berhasil dihapus.');
    } catch (e) {
      _logger.e("Error deleting unit", error: e);
      Get.snackbar(
        'Error',
        'Gagal menghapus satuan. Pastikan tidak ada barang yang menggunakan satuan ini.',
      );
    }
  }
}
