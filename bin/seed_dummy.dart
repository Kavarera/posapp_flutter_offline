import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  String path = 'C:\\Users\\rafli\\AppData\\Roaming\\com.example\\posapp_w6zxit6s\\kavarera_pos.db';
  
  var db = await databaseFactory.openDatabase(path);
  print('Connected to database at \$path');

  var rnd = Random();

  await db.delete('purchase_invoice_details');
  await db.delete('purchase_invoices');
  await db.delete('product_suppliers');
  await db.delete('products');
  await db.delete('categories');
  await db.delete('suppliers');
  await db.delete('units');

  print('Cleared old data...');

  List<String> baseUnits = ['Pcs', 'Kg', 'Liter', 'Bungkus'];
  List<int> unitIds = [];
  for (String u in baseUnits) {
    int id = await db.insert('units', {
      'name': u,
      'has_derived': 0,
      'multiplier_to_derived': 1
    });
    unitIds.add(id);
  }

  int boxId = await db.insert('units', {
    'name': 'Box',
    'has_derived': 1,
    'derived_unit_id': unitIds[0],
    'multiplier_to_derived': 10
  });
  unitIds.add(boxId);

  List<String> catNames = ['Sembako', 'Minuman', 'Peralatan Mandi', 'Alat Tulis', 'Bumbu Dapur'];
  List<int> catIds = [];
  for (String c in catNames) {
    int id = await db.insert('categories', {
      'name': c
    });
    catIds.add(id);
  }

  List<int> supIds = [];
  for (int i = 1; i <= 15; i++) {
    int id = await db.insert('suppliers', {
      'name': 'PT Mitra Pemasok \${i}',
      'contact': '0812345670\${i}',
      'npwp': '12.345.678.9-00\${i}.000',
      'bank_account': 'BCA 12345678\${i}',
      'address': 'Jalan Industri No. \${i}',
      'debt_balance': 0.0,
      'created_at': DateTime.now().toIso8601String()
    });
    supIds.add(id);
  }

  List<Map<String, dynamic>> products = [];
  for (int i = 1; i <= 30; i++) {
    int catId = catIds[rnd.nextInt(catIds.length)];
    int unitId = unitIds[rnd.nextInt(unitIds.length)];
    
    double basePrice = (rnd.nextInt(50) + 5) * 1000.0;
    int minStock = rnd.nextInt(20) + 10;
    
    String barcode = 'PRD-\${i.toString().padLeft(4, "0")}';
    
    int pId = await db.insert('products', {
      'barcode': barcode,
      'name': 'Barang Dummy \${i}',
      'category_id': catId,
      'unit_id': unitId,
      'buy_price': basePrice,
      'sell_price': basePrice + 3000,
      'stock': 0,
      'min_stock': minStock,
      'created_at': DateTime.now().toIso8601String()
    });

    products.add({
      'id': pId,
      'base_price': basePrice,
      'unit_id': unitId
    });

    int numSuppliers = rnd.nextInt(5) + 1;
    var shuffledSupps = List.of(supIds)..shuffle();
    for (int j = 0; j < numSuppliers; j++) {
      await db.insert('product_suppliers', {
        'product_id': pId,
        'supplier_id': shuffledSupps[j]
      });
    }
  }

  print('Master data generated. Generating 500 invoices...');

  DateTime now = DateTime.now();
  for (int i = 1; i <= 500; i++) {
    int daysAgo = rnd.nextInt(180);
    DateTime invDate = now.subtract(Duration(days: daysAgo));
    
    int supId = supIds[rnd.nextInt(supIds.length)];
    
    var sps = await db.query('product_suppliers', where: 'supplier_id = ?', whereArgs: [supId]);
    if (sps.isEmpty) continue;

    String invNumber = '\${invDate.year}\${invDate.month.toString().padLeft(2, "0")}-\${i.toString().padLeft(5, "0")}';
    
    int invoiceId = await db.insert('purchase_invoices', {
      'invoice_number': invNumber,
      'supplier_invoice_number': 'INV-SUP-\${i}',
      'supplier_id': supId,
      'invoice_date': invDate.toIso8601String(),
      'payment_method': ['Tunai', 'Transfer', 'Hutang'][rnd.nextInt(3)],
      'total_nominal': 0.0,
      'created_at': invDate.toIso8601String()
    });

    int numItems = rnd.nextInt(5) + 1;
    var shuffledSps = List.of(sps)..shuffle();
    int actualItems = min(numItems, shuffledSps.length);

    double invoiceTotal = 0;

    for (int j = 0; j < actualItems; j++) {
      int pId = shuffledSps[j]['product_id'] as int;
      var prod = products.firstWhere((p) => p['id'] == pId);
      
      int qty = rnd.nextInt(50) + 1;
      
      double basePrice = prod['base_price'];
      double fluctuation = (rnd.nextDouble() * 0.3) - 0.15;
      double currentPrice = basePrice * (1 + fluctuation);
      currentPrice = (currentPrice / 500).round() * 500.0;
      if (currentPrice < 500) currentPrice = 500;
      
      double total = currentPrice * qty;
      invoiceTotal += total;

      await db.insert('purchase_invoice_details', {
        'invoice_id': invoiceId,
        'product_id': pId,
        'unit_id': prod['unit_id'],
        'qty': qty,
        'unit_price': currentPrice,
        'total_price': total,
        'base_unit_price': currentPrice
      });
      
      await db.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [qty, pId]);
    }

    await db.update('purchase_invoices', {'total_nominal': invoiceTotal}, where: 'id = ?', whereArgs: [invoiceId]);
  }

  print('Done generating 500 invoices.');
  await db.close();
}
