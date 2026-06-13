import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class PriceAnalysisController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var isLoading = false.obs;

  // Filters
  var startDate = DateTime.now().subtract(const Duration(days: 90)).obs;
  var endDate = DateTime.now().obs;

  var allSuppliers = <Supplier>[].obs;
  var selectedSupplierIds = <int>[].obs;

  var analysisType = 'Barang'.obs; // 'Barang' atau 'Kategori'

  var allProducts = <Product>[].obs;
  var selectedProductIds = <int>[].obs;

  var allCategories = <Map<String, dynamic>>[].obs;
  var selectedCategoryIds = <int>[].obs;

  // Outputs
  var recommendedPrices = <Map<String, dynamic>>[].obs;
  var lineChartData = <Map<String, dynamic>>[].obs;
  var barChartData = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      final db = await _dbHelper.database;

      final sMaps = await db.query('suppliers', orderBy: 'name ASC');
      allSuppliers.assignAll(sMaps.map((e) => Supplier.fromJson(e)).toList());

      final pMaps = await db.query('products', orderBy: 'name ASC');
      allProducts.assignAll(pMaps.map((e) => Product.fromJson(e)).toList());

      final cMaps = await db.query('categories', orderBy: 'name ASC');
      allCategories.assignAll(cMaps);
    } catch (e) {
      _logger.e('Failed to load filters', error: e);
    }
  }

  void toggleSupplier(int id) {
    if (selectedSupplierIds.contains(id)) {
      selectedSupplierIds.remove(id);
    } else {
      if (selectedSupplierIds.length >= 5) {
        SnackbarHelper.show(
          'Validasi',
          'Maksimal 5 Supplier dapat dipilih',
          isError: true,
        );
        return;
      }
      selectedSupplierIds.add(id);
    }
  }

  void toggleProduct(int id) {
    if (selectedProductIds.contains(id)) {
      selectedProductIds.remove(id);
    } else {
      selectedProductIds.add(id);
    }
  }

  void toggleCategory(int id) {
    if (selectedCategoryIds.contains(id)) {
      selectedCategoryIds.remove(id);
    } else {
      selectedCategoryIds.add(id);
    }
  }

  Future<void> runAnalysis() async {
    // We don't strictly require items to be selected if we default to all.
    // Wait, the FRD says "Namun pada kondisi awal akan menampilkan tren harga untuk semua barang dan supplier."
    // So if no product/category selected, we don't block. But it might be too much data.
    // We will allow empty selection to mean "All".

    isLoading.value = true;
    try {
      final db = await _dbHelper.database;

      bool filterSupplier = selectedSupplierIds.isNotEmpty;
      String sIds = selectedSupplierIds.join(',');

      bool filterProduct = selectedProductIds.isNotEmpty;
      String pIds = selectedProductIds.join(',');

      bool filterCategory = selectedCategoryIds.isNotEmpty;
      String cIds = selectedCategoryIds.join(',');

      String startIso = startDate.value.toIso8601String();
      String endIso = endDate.value.toIso8601String();

      // 1. Rekomendasi Harga Jual Terbaru
      String queryRec = '''
        SELECT p.id as product_id, p.name as product_name, d.base_unit_price, i.invoice_date
        FROM purchase_invoice_details d
        JOIN purchase_invoices i ON d.invoice_id = i.id
        JOIN products p ON d.product_id = p.id
        WHERE 1=1
      ''';

      if (filterSupplier) queryRec += ' AND i.supplier_id IN ($sIds)';
      if (analysisType.value == 'Barang' && filterProduct) {
        queryRec += ' AND p.id IN ($pIds)';
      } else if (analysisType.value == 'Kategori' && filterCategory) {
        queryRec += ' AND p.category_id IN ($cIds)';
      }
      queryRec += ' ORDER BY i.invoice_date DESC';

      final rawRec = await db.rawQuery(queryRec);
      final processedRec = await compute(_processRecommendations, rawRec);
      recommendedPrices.assignAll(processedRec);

      // 2. Line Chart (Tren Harga)
      String queryLine = '''
        SELECT 
          i.invoice_date, 
          s.name as supplier_name, 
          p.name as product_name, 
          d.base_unit_price
        FROM purchase_invoice_details d
        JOIN purchase_invoices i ON d.invoice_id = i.id
        JOIN products p ON d.product_id = p.id
        JOIN suppliers s ON i.supplier_id = s.id
        WHERE i.invoice_date >= ? AND i.invoice_date <= ?
      ''';

      if (filterSupplier) queryLine += ' AND i.supplier_id IN ($sIds)';
      if (analysisType.value == 'Barang' && filterProduct) {
        queryLine += ' AND p.id IN ($pIds)';
      } else if (analysisType.value == 'Kategori' && filterCategory) {
        queryLine += ' AND p.category_id IN ($cIds)';
      }
      queryLine += ' ORDER BY i.invoice_date ASC';

      final rawLine = await db.rawQuery(queryLine, [startIso, endIso]);
      final processedLine = await compute(_processLineChart, rawLine);
      lineChartData.assignAll(processedLine);

      // 3. Bar Chart (Perbandingan Harga)
      // Only for products with >1 supplier in product_suppliers.
      // So we fetch all products that qualify first.
      String qualifyingProductsQuery = '''
        SELECT product_id 
        FROM product_suppliers 
        GROUP BY product_id 
        HAVING COUNT(supplier_id) > 1
      ''';
      final multiSuppProducts = await db.rawQuery(qualifyingProductsQuery);
      List<int> validPids = multiSuppProducts
          .map((e) => e['product_id'] as int)
          .toList();

      if (validPids.isEmpty) {
        barChartData.assignAll([]);
      } else {
        String validPidsStr = validPids.join(',');
        String queryBar =
            '''
          SELECT 
            p.name as product_name, 
            s.name as supplier_name, 
            d.base_unit_price
          FROM purchase_invoice_details d
          JOIN purchase_invoices i ON d.invoice_id = i.id
          JOIN products p ON d.product_id = p.id
          JOIN suppliers s ON i.supplier_id = s.id
          WHERE p.id IN ($validPidsStr)
        ''';

        if (filterSupplier) queryBar += ' AND i.supplier_id IN ($sIds)';
        if (analysisType.value == 'Barang' && filterProduct) {
          queryBar += ' AND p.id IN ($pIds)';
        } else if (analysisType.value == 'Kategori' && filterCategory) {
          queryBar += ' AND p.category_id IN ($cIds)';
        }

        final rawBar = await db.rawQuery(queryBar);
        final processedBar = await compute(_processBarChart, rawBar);
        barChartData.assignAll(processedBar);
      }
    } catch (e) {
      _logger.e('Failed to run analysis', error: e);
      SnackbarHelper.show('Error', 'Gagal memuat analisis data', isError: true);
    } finally {
      isLoading.value = false;
    }
  }
}

// Top-level functions for compute / Isolate
List<Map<String, dynamic>> _processRecommendations(
  List<Map<String, Object?>> rawData,
) {
  Set<String> seenProducts = {};
  List<Map<String, dynamic>> result = [];

  for (var row in rawData) {
    String pname = row['product_name'] as String;
    if (!seenProducts.contains(pname)) {
      seenProducts.add(pname);
      double buyPrice = (row['base_unit_price'] as num).toDouble();
      // Rekomendasi: base_unit_price dibulatkan ke atas, ditambah 3000
      double recPrice = buyPrice.ceilToDouble() + 3000;
      result.add({
        'product_name': pname,
        'latest_buy_price': buyPrice,
        'recommended_price': recPrice,
        'date': row['invoice_date'],
      });
    }
  }
  return result;
}

List<Map<String, dynamic>> _processLineChart(
  List<Map<String, Object?>> rawData,
) {
  // Group by Product Name
  // Then inside, have a list of lines (one for each supplier)
  Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};

  for (var row in rawData) {
    String pName = row['product_name'] as String;
    String sName = row['supplier_name'] as String;
    String dateStr = row['invoice_date'] as String;
    double price = (row['base_unit_price'] as num).toDouble();

    DateTime d = DateTime.parse(dateStr);

    if (!grouped.containsKey(pName)) {
      grouped[pName] = {};
    }
    if (!grouped[pName]!.containsKey(sName)) {
      grouped[pName]![sName] = [];
    }
    grouped[pName]![sName]!.add({'x': d, 'y': price});
  }

  List<Map<String, dynamic>> result = [];
  grouped.forEach((pName, suppliers) {
    List<Map<String, dynamic>> lines = [];
    suppliers.forEach((sName, points) {
      lines.add({
        'label': sName, // Line label is Supplier
        'points': points,
      });
    });
    result.add({'product_name': pName, 'lines': lines});
  });

  return result;
}

List<Map<String, dynamic>> _processBarChart(
  List<Map<String, Object?>> rawData,
) {
  // Group by Product
  // Then by Supplier to get average
  Map<String, Map<String, List<double>>> productSupplierPrices = {};

  for (var row in rawData) {
    String pName = row['product_name'] as String;
    String sName = row['supplier_name'] as String;
    double price = (row['base_unit_price'] as num).toDouble();

    if (!productSupplierPrices.containsKey(pName)) {
      productSupplierPrices[pName] = {};
    }
    if (!productSupplierPrices[pName]!.containsKey(sName)) {
      productSupplierPrices[pName]![sName] = [];
    }
    productSupplierPrices[pName]![sName]!.add(price);
  }

  List<Map<String, dynamic>> result = [];

  productSupplierPrices.forEach((productName, supplierMap) {
    List<Map<String, dynamic>> suppliersData = [];
    supplierMap.forEach((supplierName, prices) {
      double sum = prices.fold(0.0, (a, b) => a + b);
      double avg = sum / prices.length;
      suppliersData.add({'supplier_name': supplierName, 'avg_price': avg});
    });
    result.add({'product_name': productName, 'suppliers': suppliersData});
  });

  return result;
}
