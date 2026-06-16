import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';

class PriceHistoryItem {
  final String supplierName;
  final double baseUnitPrice;
  final String invoiceDate;
  final double percentageDiff;

  PriceHistoryItem({
    required this.supplierName,
    required this.baseUnitPrice,
    required this.invoiceDate,
    required this.percentageDiff,
  });
}

class PriceAnalysisController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var isLoading = false.obs;

  // Search state
  var searchQuery = ''.obs;
  var searchResults = <Product>[].obs;
  var selectedProduct = Rxn<Product>();

  // Filter state
  var selectedMonth = Rxn<int>();
  var selectedYear = Rxn<int>();

  // Output
  var priceHistory = <PriceHistoryItem>[].obs;

  // Suppliers for Add Price Dialog
  var productSuppliers = <Supplier>[].obs;

  PriceHistoryItem? get cheapestHistoryItem {
    if (priceHistory.isEmpty) return null;
    try {
      return priceHistory.firstWhere((item) => item.percentageDiff == 0);
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Watch search query changes to auto-search
    debounce(searchQuery, (String query) {
      if (query.isNotEmpty) {
        searchProducts(query);
      } else {
        searchResults.clear();
      }
    }, time: const Duration(milliseconds: 300));
  }

  Future<void> loadProductSuppliers(int productId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery('''
        SELECT s.* 
        FROM suppliers s
        JOIN product_suppliers ps ON s.id = ps.supplier_id
        WHERE ps.product_id = ?
        ORDER BY s.name ASC
      ''', [productId]);
      productSuppliers.assignAll(maps.map((e) => Supplier.fromJson(e)).toList());
    } catch (e) {
      _logger.e('Failed to load product suppliers', error: e);
    }
  }

  Future<void> searchProducts(String query) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'products',
        where: 'name LIKE ? OR barcode LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        limit: 10,
      );
      searchResults.value = maps.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to search products', error: e);
    }
  }

  void selectProduct(Product product) {
    selectedProduct.value = product;
    searchQuery.value = '';
    searchResults.clear();
    fetchPriceHistory(product.id!);
    loadProductSuppliers(product.id!);
  }

  void clearSelection() {
    selectedProduct.value = null;
    priceHistory.clear();
    searchQuery.value = '';
    searchResults.clear();
  }

  void applyFilter({int? month, int? year}) {
    selectedMonth.value = month;
    selectedYear.value = year;
    if (selectedProduct.value != null) {
      fetchPriceHistory(selectedProduct.value!.id!);
    }
  }

  Future<void> fetchPriceHistory(int productId) async {
    isLoading.value = true;
    try {
      final db = await _dbHelper.database;

      List<String> conditions = ['pid.product_id = ?'];
      List<dynamic> args = [productId];

      if (selectedMonth.value != null) {
        conditions.add("strftime('%m', pi.invoice_date) = ?");
        args.add(selectedMonth.value.toString().padLeft(2, '0'));
      }
      if (selectedYear.value != null) {
        conditions.add("strftime('%Y', pi.invoice_date) = ?");
        args.add(selectedYear.value.toString());
      }

      String whereClause = conditions.join(' AND ');

      final maps = await db.rawQuery('''
        SELECT 
          s.name as supplier_name,
          pid.base_unit_price,
          pi.invoice_date
        FROM purchase_invoice_details pid
        JOIN purchase_invoices pi ON pid.invoice_id = pi.id
        LEFT JOIN suppliers s ON pi.supplier_id = s.id
        WHERE $whereClause
        ORDER BY pi.invoice_date DESC
      ''', args);

      if (maps.isEmpty) {
        priceHistory.clear();
        return;
      }

      // Find the cheapest base_unit_price
      double cheapest = double.infinity;
      for (var map in maps) {
        final price = (map['base_unit_price'] as num?)?.toDouble() ?? 0;
        if (price > 0 && price < cheapest) {
          cheapest = price;
        }
      }

      List<PriceHistoryItem> history = [];
      for (var map in maps) {
        final price = (map['base_unit_price'] as num?)?.toDouble() ?? 0;
        double diff = 0;
        if (cheapest != double.infinity && cheapest > 0) {
          diff = ((price - cheapest) / cheapest) * 100;
        }

        history.add(
          PriceHistoryItem(
            supplierName: map['supplier_name'] as String? ?? 'Unknown',
            baseUnitPrice: price,
            invoiceDate: map['invoice_date'] as String,
            percentageDiff: diff,
          ),
        );
      }

      priceHistory.value = history;
    } catch (e) {
      _logger.e('Failed to fetch price history', error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> insertManualPrice({
    required int supplierId,
    required double price,
    required DateTime date,
  }) async {
    if (selectedProduct.value == null) return;
    final product = selectedProduct.value!;

    try {
      isLoading.value = true;
      final db = await _dbHelper.database;

      final invoiceNumber = 'MNL-${DateTime.now().millisecondsSinceEpoch}';
      final dateStr = date.toIso8601String().split('T').first;

      await db.transaction((txn) async {
        final invoiceId = await txn.insert('purchase_invoices', {
          'invoice_number': invoiceNumber,
          'supplier_id': supplierId,
          'invoice_date': dateStr,
          'payment_method': 'Tunai',
          'total_nominal': price,
          'status': 'Lunas',
          'created_at': DateTime.now().toIso8601String(),
        });

        await txn.insert('purchase_invoice_details', {
          'invoice_id': invoiceId,
          'product_id': product.id,
          'unit_id': product.unitId ?? 0, // Fallback to 0 if unitId is null
          'qty': 0,
          'unit_price': price,
          'total_price': price,
          'base_unit_price': price,
        });
      });

      // Reload history
      fetchPriceHistory(product.id!);
    } catch (e) {
      _logger.e('Failed to insert manual price', error: e);
    } finally {
      isLoading.value = false;
    }
  }
}
