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
      
      // Fetch units with their derived unit name
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT u1.*, u2.name as derived_unit_name
        FROM units u1
        LEFT JOIN units u2 ON u1.derived_unit_id = u2.id
      ''');

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
      await db.update('units', unit.toJson(), where: 'id = ?', whereArgs: [unit.id]);
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
      
      // Find the unit
      List<Map<String, dynamic>> unitMaps = await db.query('units', where: 'id = ?', whereArgs: [id]);
      if (unitMaps.isEmpty) return;
      Unit unitToDelete = Unit.fromJson(unitMaps.first);

      await db.transaction((txn) async {
        if (unitToDelete.hasDerived && unitToDelete.derivedUnitId != null && unitToDelete.multiplierToDerived != null) {
          // It's a unit with a derived unit (e.g. Karton -> Dus).
          // If we delete Karton, products using Karton must fall back to Dus.
          // stock = stock * multiplier
          // buy_price = buy_price / multiplier
          // sell_price = sell_price / multiplier
          
          List<Map<String, dynamic>> products = await txn.query('products', where: 'unit_id = ?', whereArgs: [id]);
          for (var p in products) {
            int oldStock = p['stock'] as int;
            double oldBuy = (p['buy_price'] as num).toDouble();
            double oldSell = (p['sell_price'] as num).toDouble();
            
            await txn.update('products', {
              'unit_id': unitToDelete.derivedUnitId,
              'stock': oldStock * unitToDelete.multiplierToDerived!,
              'buy_price': oldBuy / unitToDelete.multiplierToDerived!,
              'sell_price': oldSell / unitToDelete.multiplierToDerived!,
            }, where: 'id = ?', whereArgs: [p['id']]);
          }
        } else {
          // If it's a primary unit without derived, delete all products using it (Rule 5)
          await txn.delete('products', where: 'unit_id = ?', whereArgs: [id]);
        }
        
        // Remove unit
        await txn.delete('units', where: 'id = ?', whereArgs: [id]);
      });
      
      _logger.i("Unit $id deleted");
      await fetchUnits();
      Get.snackbar('Sukses', 'Satuan berhasil dihapus dan produk terkait telah disesuaikan.');
    } catch (e) {
      _logger.e("Error deleting unit", error: e);
      Get.snackbar('Error', 'Gagal menghapus satuan. Pastikan tidak ada satuan lain yang menjadikannya turunan.');
    }
  }
}
