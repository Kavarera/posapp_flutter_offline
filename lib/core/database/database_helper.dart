import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
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
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    _logger.i("Upgrading database from v$oldVersion to v$newVersion. Dropping all tables and recreating.");
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
        address TEXT
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
        name TEXT NOT NULL UNIQUE,
        has_derived INTEGER NOT NULL DEFAULT 0,
        derived_unit_id INTEGER,
        multiplier_to_derived INTEGER,
        FOREIGN KEY (derived_unit_id) REFERENCES units(id) ON DELETE RESTRICT
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

    // Seed default admin and default unit "Pcs"
    await _seedAdmin(db);
    await _seedDefaultData(db);
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
    await db.insert('units', {
      'name': 'Pcs',
      'has_derived': 0,
    });
    _logger.i("Default unit 'Pcs' seeded successfully.");
  }
}
