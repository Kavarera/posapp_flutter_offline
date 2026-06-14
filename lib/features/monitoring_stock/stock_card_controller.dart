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
}
