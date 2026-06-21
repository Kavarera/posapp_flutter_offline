import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class StockCardController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var products = <Map<String, dynamic>>[].obs;
  var selectedProductId = RxnInt();
  var selectedTypeFilter = 'Semua'.obs;

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
      String whereStr = 'product_id = ?';
      List<dynamic> whereArgsList = [selectedProductId.value];
      
      if (selectedTypeFilter.value != 'Semua') {
        whereStr += ' AND type = ?';
        if (selectedTypeFilter.value == 'Masuk') {
          whereArgsList.add('IN');
        } else if (selectedTypeFilter.value == 'Keluar') {
          whereArgsList.add('OUT');
        } else if (selectedTypeFilter.value == 'Opname') {
          whereArgsList.add('ADJUSTMENT');
        }
      }

      List<Map<String, dynamic>> data = await db.query(
        'stock_movements',
        where: whereStr,
        whereArgs: whereArgsList,
        orderBy: 'created_at DESC',
      );
      stockMovements.assignAll(data);
    } catch (e) {
      _logger.e("Error loading stock movements", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> processStockOpname(List<Map<String, dynamic>> opnameItems) async {
    if (opnameItems.isEmpty) return false;
    try {
      Database db = await _dbHelper.database;
      
      await db.transaction((txn) async {
        String nowStr = DateTime.now().toIso8601String();
        
        for (var item in opnameItems) {
          int productId = item['product_id'] as int;
          int actualPhysicalStock = item['actual_stock'] as int;
          int diff = item['diff'] as int;
          
          if (diff == 0) continue;
          
          // Update product stock
          await txn.update(
            'products',
            {'stock': actualPhysicalStock, 'updated_at': nowStr},
            where: 'id = ?',
            whereArgs: [productId],
          );
          
          // Record adjustment movement
          await txn.insert('stock_movements', {
            'product_id': productId,
            'type': 'ADJUSTMENT',
            'reference_id': null,
            'qty': diff,
            'balance_after': actualPhysicalStock,
            'note': 'Opname Stok Fisik',
            'created_at': nowStr,
          });
        }
      });
      
      // Reload products to update UI dropdown stock indicator
      await _loadProducts();
      await loadStockMovements();
      return true;
    } catch (e) {
      _logger.e("Error batch rebalancing stock", error: e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getMovementDetail(Map<String, dynamic> item) async {
    if (item['type'] == 'ADJUSTMENT' || item['reference_id'] == null) {
      return null;
    }
    
    try {
      Database db = await _dbHelper.database;
      int refId = item['reference_id'] as int;
      
      if (item['type'] == 'IN') {
        var res = await db.rawQuery('''
          SELECT pi.invoice_number as reference_number, s.name as related_party
          FROM purchase_invoices pi
          LEFT JOIN suppliers s ON pi.supplier_id = s.id
          WHERE pi.id = ?
        ''', [refId]);
        if (res.isNotEmpty) return res.first;
      } else if (item['type'] == 'OUT') {
        var res = await db.rawQuery('''
          SELECT st.transaction_number as reference_number, c.name as related_party
          FROM sales_transactions st
          LEFT JOIN customers c ON st.customer_id = c.id
          WHERE st.id = ?
        ''', [refId]);
        if (res.isNotEmpty) return res.first;
      }
    } catch (e) {
      _logger.e("Error fetching movement detail", error: e);
    }
    return null;
  }
}
