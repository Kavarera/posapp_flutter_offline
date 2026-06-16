import 'dart:io';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:posapp_w6zxit6s/core/models/purchase_invoice.dart';
import 'package:posapp_w6zxit6s/core/models/supplier.dart';
import 'package:posapp_w6zxit6s/core/models/product.dart';
import 'package:posapp_w6zxit6s/core/models/unit.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PurchaseInvoiceController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var invoices = <PurchaseInvoice>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    isLoading.value = true;
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery('''
        SELECT pi.*, s.name as supplier_name 
        FROM purchase_invoices pi
        LEFT JOIN suppliers s ON pi.supplier_id = s.id
        ORDER BY pi.created_at DESC
      ''');

      List<PurchaseInvoice> list = [];
      for (var map in maps) {
        var invoice = PurchaseInvoice.fromJson(map);
        // Fetch details
        final detailMaps = await db.rawQuery('''
          SELECT d.*, p.name as product_name, u.name as unit_name
          FROM purchase_invoice_details d
          LEFT JOIN products p ON d.product_id = p.id
          LEFT JOIN units u ON d.unit_id = u.id
          WHERE d.invoice_id = ?
        ''', [invoice.id]);
        var details = detailMaps
            .map((d) => PurchaseInvoiceDetail.fromJson(d))
            .toList();
        list.add(
          PurchaseInvoice(
            id: invoice.id,
            invoiceNumber: invoice.invoiceNumber,
            supplierInvoiceNumber: invoice.supplierInvoiceNumber,
            supplierId: invoice.supplierId,
            invoiceDate: invoice.invoiceDate,
            dueDate: invoice.dueDate,
            paymentMethod: invoice.paymentMethod,
            totalNominal: invoice.totalNominal,
            documentPaths: invoice.documentPaths,
            createdAt: invoice.createdAt,
            supplierName: invoice.supplierName,
            details: details,
          ),
        );
      }
      invoices.assignAll(list);
    } catch (e) {
      _logger.e('Failed to fetch invoices', error: e);
      SnackbarHelper.show('Error', 'Gagal memuat data invoice', isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<String> generateInvoiceNumber() async {
    final now = DateTime.now();
    final yearStr = now.year.toString();
    final monthStr = now.month.toString().padLeft(2, '0');
    final prefix = '$yearStr$monthStr-';

    try {
      final db = await _dbHelper.database;
      // Find the latest invoice in the current YEAR
      final maps = await db.query(
        'purchase_invoices',
        columns: ['invoice_number'],
        where: 'invoice_number LIKE ?',
        whereArgs: ['$yearStr%-%'],
        orderBy: 'invoice_number DESC',
        limit: 1,
      );

      int nextSequence = 1;
      if (maps.isNotEmpty) {
        final lastNumber = maps.first['invoice_number'] as String;
        final parts = lastNumber.split('-');
        if (parts.length == 2) {
          final lastSequence = int.tryParse(parts[1]) ?? 0;
          nextSequence = lastSequence + 1;
        }
      }

      return '$prefix${nextSequence.toString().padLeft(5, '0')}';
    } catch (e) {
      _logger.e('Failed to generate invoice number', error: e);
      return '${prefix}00001';
    }
  }

  Future<List<Supplier>> fetchSuppliers() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('suppliers', orderBy: 'name ASC');
      return maps.map((e) => Supplier.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to fetch suppliers', error: e);
      return [];
    }
  }

  Future<List<Product>> fetchProductsBySupplier(int supplierId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT p.* FROM products p
        INNER JOIN product_suppliers ps ON p.id = ps.product_id
        WHERE ps.supplier_id = ?
        ORDER BY p.name ASC
      ''',
        [supplierId],
      );
      return maps.map((e) => Product.fromJson(e)).toList();
    } catch (e) {
      _logger.e('Failed to fetch products for supplier', error: e);
      return [];
    }
  }

  // Returns units that can be used for the product, and their multiplier to the base unit
  // Returns List of Map: {'unit': Unit, 'multiplier': int}
  Future<List<Map<String, dynamic>>> fetchUnitsForProduct(int productId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.rawQuery(
        '''
        SELECT pu.*, u.name as unit_name
        FROM product_units pu
        INNER JOIN units u ON pu.unit_id = u.id
        WHERE pu.product_id = ?
      ''',
        [productId],
      );

      List<Map<String, dynamic>> result = [];
      for (var map in maps) {
        Unit unit = Unit(
          id: map['unit_id'] as int,
          name: map['unit_name'] as String,
        );
        result.add({
          'unit': unit,
          'multiplier': map['multiplier_to_base'] as int,
        });
      }
      return result;
    } catch (e) {
      _logger.e('Failed to fetch units for product', error: e);
      return [];
    }
  }

  Future<bool> saveInvoice(
    PurchaseInvoice invoice,
    List<PurchaseInvoiceDetail> details,
    List<String> tempFilePaths,
  ) async {
    isLoading.value = true;
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        // 1. Copy files to permanent storage
        List<String> permanentPaths = [];
        if (tempFilePaths.isNotEmpty) {
          String invoicesDir = PathService.invoicesDir;

          for (var tempPath in tempFilePaths) {
            File tempFile = File(tempPath);
            if (await tempFile.exists()) {
              String fileName = p.basename(tempPath);
              // append timestamp to prevent filename collision
              String newFileName =
                  '${DateTime.now().millisecondsSinceEpoch}_$fileName';
              String permPath = p.join(invoicesDir, newFileName);
              await tempFile.copy(permPath);
              permanentPaths.add(permPath);
            }
          }
        }

        // 2. Insert Invoice
        final newInvoice = PurchaseInvoice(
          invoiceNumber: invoice.invoiceNumber,
          supplierInvoiceNumber: invoice.supplierInvoiceNumber,
          supplierId: invoice.supplierId,
          invoiceDate: invoice.invoiceDate,
          dueDate: invoice.dueDate,
          paymentMethod: invoice.paymentMethod,
          totalNominal: invoice.totalNominal,
          paidAmount: invoice.paymentMethod == 'Tunai' ? invoice.totalNominal : 0.0,
          status: invoice.paymentMethod == 'Tunai' ? 'Lunas' : 'Belum Lunas',
          documentPaths: permanentPaths,
          createdAt: DateTime.now().toIso8601String(),
        );

        int invoiceId = await txn.insert(
          'purchase_invoices',
          newInvoice.toJson(),
        );

        // 3. Insert Details & Update Stock
        for (var d in details) {
          var newDetail = PurchaseInvoiceDetail(
            invoiceId: invoiceId,
            productId: d.productId,
            unitId: d.unitId,
            qty: d.qty,
            unitPrice: d.unitPrice,
            totalPrice: d.totalPrice,
            baseUnitPrice: d.baseUnitPrice,
          );
          await txn.insert('purchase_invoice_details', newDetail.toJson());

          // Calculate ratio for stock update
          double ratio = d.unitPrice / d.baseUnitPrice;
          // Because of floating point division, we round to nearest int
          int intRatio = ratio.round();
          if (intRatio == 0) intRatio = 1;

          int addedStock = d.qty * intRatio;

          // Update product stock
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [addedStock, d.productId],
          );

          // Add to stock_movements
          await txn.insert('stock_movements', {
            'product_id': d.productId,
            'type': 'IN',
            'reference_id': invoiceId,
            'qty': addedStock,
            'balance_after': 0, // In real app, query current stock first
            'note': 'Pembelian ${invoice.invoiceNumber}',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // 4. Update Supplier Debt if Hutang
        if (invoice.paymentMethod == 'Hutang') {
          await txn.rawUpdate(
            'UPDATE suppliers SET debt_balance = debt_balance + ? WHERE id = ?',
            [invoice.totalNominal, invoice.supplierId],
          );
        }
      });

      _logger.i('Invoice saved successfully: ${invoice.invoiceNumber}');
      SnackbarHelper.show(
        'Sukses',
        'Invoice Pembelian berhasil disimpan',
        isError: false,
      );
      fetchInvoices();
      return true;
    } catch (e) {
      _logger.e('Failed to save invoice', error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal menyimpan invoice: $e',
        isError: true,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteInvoice(PurchaseInvoice invoice) async {
    // Phase 2 out-of-scope for deleting invoices but adding a safe method just in case
    // If we delete, we'd need to reverse stock and debt changes.
    // For now, keep it simple.
  }
}
