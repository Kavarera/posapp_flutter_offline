import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StockCardController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var products = <Map<String, dynamic>>[].obs;
  var selectedProductId = RxnInt();

  var stockMovements = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> data = await db.query(
        'products',
        where: 'id != ?',
        whereArgs: [-1],
        orderBy: 'name ASC',
      );
      products.assignAll(data);
      if (data.isNotEmpty) {
        selectedProductId.value = data.first['id'] as int;
        loadStockMovements();
      }
    } catch (e) {
      _logger.e("Error loading products", error: e);
    }
  }

  void onProductChanged(int? productId) {
    if (productId != null) {
      selectedProductId.value = productId;
      loadStockMovements();
    }
  }

  Future<void> loadStockMovements() async {
    if (selectedProductId.value == null) return;
    isLoading.value = true;
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> data = await db.query(
        'stock_movements',
        where: 'product_id = ?',
        whereArgs: [selectedProductId.value],
        orderBy: 'created_at DESC',
      );
      stockMovements.assignAll(data);
    } catch (e) {
      _logger.e("Error loading stock movements", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rebalanceStock(int actualPhysicalStock) async {
    if (selectedProductId.value == null) return;
    try {
      Database db = await _dbHelper.database;
      
      var productData = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [selectedProductId.value],
      );
      
      if (productData.isEmpty) return;
      
      int currentStock = productData.first['stock'] as int;
      int diff = actualPhysicalStock - currentStock;
      
      if (diff == 0) {
        return; // No change
      }
      
      await db.transaction((txn) async {
        String nowStr = DateTime.now().toIso8601String();
        
        // Update product stock
        await txn.update(
          'products',
          {'stock': actualPhysicalStock, 'updated_at': nowStr},
          where: 'id = ?',
          whereArgs: [selectedProductId.value],
        );
        
        // Record adjustment movement
        await txn.insert('stock_movements', {
          'product_id': selectedProductId.value,
          'type': 'ADJUSTMENT',
          'reference_id': null,
          'qty': diff,
          'balance_after': actualPhysicalStock,
          'note': 'Penyesuaian Fisik (Rebalancing)',
          'created_at': nowStr,
        });
      });
      
      // Reload products to update UI dropdown stock indicator
      await _loadProducts();
      await loadStockMovements();
    } catch (e) {
      _logger.e("Error rebalancing stock", error: e);
    }
  }
}
