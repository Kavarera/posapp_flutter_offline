import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:posapp_w6zxit6s/core/constants/app_constants.dart';
import 'package:logger/logger.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  final Logger _logger = Logger();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    Directory documentsDirectory = await getApplicationSupportDirectory();
    String path = join(documentsDirectory.path, "kavarera_pos.db");

    _logger.i("Initializing database at: $path");

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i(
      "Upgrading database from v$oldVersion to v$newVersion. Dropping all tables and recreating.",
    );
    await db.execute('DROP TABLE IF EXISTS purchase_invoice_details');
    await db.execute('DROP TABLE IF EXISTS purchase_invoices');
    await db.execute('DROP TABLE IF EXISTS product_suppliers');
    await db.execute('DROP TABLE IF EXISTS product_units'); // Old table
    await db.execute('DROP TABLE IF EXISTS products');
    await db.execute('DROP TABLE IF EXISTS units');
    await db.execute('DROP TABLE IF EXISTS categories');
    await db.execute('DROP TABLE IF EXISTS suppliers');
    await db.execute('DROP TABLE IF EXISTS customers');
    await db.execute('DROP TABLE IF EXISTS users');
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    _logger.i("Creating database tables for Phase 1 (v2)");

    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        pin_hash TEXT,
        role TEXT NOT NULL DEFAULT 'Kasir'
      )
    ''');

    // 2. Suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT,
        npwp TEXT,
        bank_account TEXT,
        address TEXT,
        debt_balance REAL NOT NULL DEFAULT 0
      )
    ''');

    // 3. Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 4. Units table (Master Satuan)
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // 4.5. Product Units table (Satuan Turunan per Barang)
    await db.execute('''
      CREATE TABLE product_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        is_base INTEGER NOT NULL DEFAULT 0,
        parent_unit_id INTEGER,
        multiplier_to_parent INTEGER,
        multiplier_to_base INTEGER NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT,
        FOREIGN KEY (parent_unit_id) REFERENCES units (id) ON DELETE RESTRICT,
        UNIQUE(product_id, unit_id)
      )
    ''');

    // 5. Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        unit_id INTEGER,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE NOT NULL,
        buy_price REAL NOT NULL DEFAULT 0,
        buy_price_ppn REAL NOT NULL DEFAULT 0,
        sell_price REAL NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT
      )
    ''');

    // 6. Product Suppliers Junction Table (Many-to-Many)
    await db.execute('''
      CREATE TABLE product_suppliers (
        product_id INTEGER,
        supplier_id INTEGER,
        PRIMARY KEY (product_id, supplier_id),
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE CASCADE
      )
    ''');

    // 7. Customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        status TEXT NOT NULL DEFAULT 'Aktif',
        receivable_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT
      )
    ''');

    // 8. Purchase Invoices table (Header)
    await db.execute('''
      CREATE TABLE purchase_invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT UNIQUE NOT NULL,
        supplier_invoice_number TEXT,
        supplier_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        due_date TEXT,
        payment_method TEXT NOT NULL,
        total_nominal REAL NOT NULL DEFAULT 0,
        document_paths TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE RESTRICT
      )
    ''');

    // 9. Purchase Invoice Details table
    await db.execute('''
      CREATE TABLE purchase_invoice_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        base_unit_price REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES purchase_invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE RESTRICT
      )
    ''');

    // Seed default admin and default unit "Pcs"
    await _seedAdmin(db);
    await _seedDefaultData(db);
    await _seedDummyDataForTesting(db);
  }

  Future<void> _seedAdmin(Database db) async {
    String salt = AppConstants.passwordSalt;
    String passwordToHash = 'admin123$salt';
    var bytes = utf8.encode(passwordToHash);
    var digest = sha256.convert(bytes);
    String passwordHash = digest.toString();

    await db.insert('users', {
      'username': 'admin',
      'password_hash': passwordHash,
      'role': 'Admin',
    });

    _logger.i("Default admin seeded successfully.");
  }

  Future<void> _seedDefaultData(Database db) async {
    // Generate default unit "Pcs" per FRD requirement
    await db.insert('units', {'name': 'Pcs'});
    _logger.i("Default unit 'Pcs' seeded successfully.");
  }

  Future<void> _seedDummyDataForTesting(Database db) async {
    _logger.i("Seeding dummy data for testing...");
    final batch = db.batch();

    // 1. Suppliers
    List<String> supplierNames = [
      'PT. Indofood',
      'PT. Wings',
      'PT. Unilever',
      'PT. Mayora',
      'CV. Makmur',
    ];
    for (int i = 0; i < supplierNames.length; i++) {
      batch.insert('suppliers', {
        'id': i + 1,
        'name': supplierNames[i],
        'debt_balance': 0,
      });
    }

    // 2. Units (Pcs is already 1)
    batch.insert('units', {'id': 2, 'name': 'Box'});
    batch.insert('units', {'id': 3, 'name': 'Lusin'});
    batch.insert('units', {'id': 4, 'name': 'Karton'});

    // 3. Categories
    batch.insert('categories', {'id': 1, 'name': 'Makanan'});
    batch.insert('categories', {'id': 2, 'name': 'Minuman'});
    batch.insert('categories', {'id': 3, 'name': 'Kebutuhan Rumah'});

    // 4. Products
    List<Map<String, dynamic>> products = [
      {'id': 1, 'name': 'Indomie Goreng', 'category_id': 1, 'unit_id': 1},
      {'id': 2, 'name': 'Teh Pucuk Harum', 'category_id': 2, 'unit_id': 1},
      {'id': 3, 'name': 'Sabun Lifebuoy', 'category_id': 3, 'unit_id': 1},
      {'id': 4, 'name': 'Kopi Kapal Api', 'category_id': 2, 'unit_id': 1},
      {'id': 5, 'name': 'Biskuit Roma', 'category_id': 1, 'unit_id': 1},
    ];

    Map<int, List<int>> supplierProducts = {1: [], 2: [], 3: [], 4: [], 5: []};
    final random = Random();

    for (var p in products) {
      batch.insert('products', {
        'id': p['id'],
        'name': p['name'],
        'barcode': '1000${p['id']}',
        'category_id': p['category_id'],
        'unit_id': p['unit_id'], // Base unit
        'buy_price': 2000.0 + (p['id'] * 500),
        'sell_price': 3000.0 + (p['id'] * 500),
        'min_stock': 10,
        'stock': 0,
      });

      // Insert base unit to product_units
      batch.insert('product_units', {
        'product_id': p['id'],
        'unit_id': p['unit_id'],
        'is_base': 1,
        'multiplier_to_base': 1,
      });

      // Insert derived unit (e.g. Kardus = 40 Pcs)
      batch.insert('product_units', {
        'product_id': p['id'],
        'unit_id': 4, // Karton
        'is_base': 0,
        'parent_unit_id': p['unit_id'],
        'multiplier_to_parent': 40,
        'multiplier_to_base': 40,
      });

      // Link to multiple suppliers
      int numSupp = random.nextInt(3) + 2; // 2, 3 or 4 suppliers
      List<int> sList = [1, 2, 3, 4, 5];
      sList.shuffle(random);
      for(int j=0; j<numSupp; j++) {
        int sId = sList[j];
        batch.insert('product_suppliers', {
          'product_id': p['id'],
          'supplier_id': sId,
        });
        supplierProducts[sId]!.add(p['id'] as int);
      }
    }

    // 5. Invoices (500 Invoices)
    DateTime now = DateTime.now();

    for (int i = 1; i <= 500; i++) {
      int supplierId = 1;
      while (true) {
        supplierId = random.nextInt(supplierNames.length) + 1;
        if (supplierProducts[supplierId] != null && supplierProducts[supplierId]!.isNotEmpty) break;
      }
      int daysAgo = random.nextInt(90); // Last 90 days
      DateTime invDate = now.subtract(Duration(days: daysAgo));

      batch.insert('purchase_invoices', {
        'id': i,
        'invoice_number': 'INV-2026-${i.toString().padLeft(5, '0')}',
        'supplier_invoice_number': 'SUP-${i}',
        'supplier_id': supplierId,
        'invoice_date': invDate.toIso8601String(),
        'payment_method': 'Tunai',
        'total_nominal': 0, // Will update below
        'created_at': invDate.toIso8601String(),
      });

      double totalNominal = 0;
      int detailsCount = random.nextInt(3) + 1; // 1 to 3 items

      for (int d = 0; d < detailsCount; d++) {
        int pIdx = random.nextInt(supplierProducts[supplierId]!.length);
        int productId = supplierProducts[supplierId]![pIdx];
        // Base Unit (Pcs) or Karton
        bool useKarton = random.nextBool();
        int unitId = useKarton ? 4 : 1;
        int qty = random.nextInt(10) + 1;

        // Base price fluctuation
        double basePrice = 2000.0 + (productId * 500);
        // Random fluctuation between -10% to +10%
        double fluctuation = 1.0 + ((random.nextDouble() * 0.2) - 0.1);
        double actualBasePrice = (basePrice * fluctuation).roundToDouble();

        double unitPrice = useKarton ? actualBasePrice * 40 : actualBasePrice;
        double totalPrice = unitPrice * qty;
        totalNominal += totalPrice;

        batch.insert('purchase_invoice_details', {
          'invoice_id': i,
          'product_id': productId,
          'unit_id': unitId,
          'qty': qty,
          'unit_price': unitPrice,
          'total_price': totalPrice,
          'base_unit_price': actualBasePrice,
        });

        // Also add stock directly for dummy
        batch.rawUpdate('UPDATE products SET stock = stock + ? WHERE id = ?', [
          useKarton ? qty * 40 : qty,
          productId,
        ]);
      }

      batch.rawUpdate(
        'UPDATE purchase_invoices SET total_nominal = ? WHERE id = ?',
        [totalNominal, i],
      );
    }

    await batch.commit(noResult: true);
    _logger.i("Dummy data seeded successfully.");
  }
}
