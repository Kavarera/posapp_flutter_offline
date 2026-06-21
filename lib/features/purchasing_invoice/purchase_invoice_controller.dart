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
  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  var invoices = <PurchaseInvoice>[].obs;
  var suppliers = <Supplier>[].obs;
  var isLoading = false.obs;

  // Filter & Sort
  var selectedStatus = Rxn<String>(); // 'Lunas', 'Belum Lunas'
  var selectedSupplierId = Rxn<int>();
  var selectedMonth = Rxn<int>();
  var selectedYear = Rxn<int>();
  var sortBy = 'created_at'.obs; // 'created_at', 'total_nominal', 'due_date'
  var sortAscending = false.obs;
  var showIncompleteOnly = false.obs;

  // Summaries
  int get totalInvoicesCount => invoices.length;
  double get totalInvoicesAmount =>
      invoices.fold(0, (sum, item) => sum + item.totalNominal);

  int get totalLunasCount => invoices.where((i) => i.status == 'Lunas').length;
  double get totalLunasAmount => invoices
      .where((i) => i.status == 'Lunas')
      .fold(0, (sum, item) => sum + item.totalNominal);

  int get totalBelumLunasCount =>
      invoices.where((i) => i.status == 'Belum Lunas').length;
  double get totalBelumLunasAmount => invoices
      .where((i) => i.status == 'Belum Lunas')
      .fold(0, (sum, item) => sum + item.totalNominal);

  @override
  void onInit() {
    super.onInit();
    fetchDependencies();
    fetchInvoices();
  }

  Future<void> fetchDependencies() async {
    try {
      final db = await _dbHelper.database;
      final supMaps = await db.query('suppliers');
      suppliers.value = supMaps.map((e) => Supplier.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching suppliers", error: e);
    }
  }

  void applyFilter({
    String? status,
    int? supplierId,
    int? month,
    int? year,
    bool changeStatus = false,
    bool changeSupplier = false,
    bool changeMonth = false,
    bool changeYear = false,
    bool changeIncomplete = false,
    bool incompleteValue = false,
  }) {
    if (changeStatus) selectedStatus.value = status;
    if (changeSupplier) selectedSupplierId.value = supplierId;
    if (changeMonth) selectedMonth.value = month;
    if (changeYear) selectedYear.value = year;
    if (changeIncomplete) showIncompleteOnly.value = incompleteValue;
    fetchInvoices();
  }

  void applySort(String field) {
    if (sortBy.value == field) {
      sortAscending.value = !sortAscending.value;
    } else {
      sortBy.value = field;
      sortAscending.value = true;
    }
    fetchInvoices();
  }

  void toggleSortDirection() {
    sortAscending.value = !sortAscending.value;
    fetchInvoices();
  }

  Future<int> getIncompleteInvoicesCount() async {
    final db = await _dbHelper.database;
    try {
      var res = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM purchase_invoices pi
        WHERE NOT EXISTS (SELECT 1 FROM purchase_invoice_details pid WHERE pid.invoice_id = pi.id)
      ''');
      return (res.first['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      _logger.e("Error counting incomplete invoices", error: e);
      return 0;
    }
  }

  Future<void> fetchInvoices() async {
    isLoading.value = true;
    try {
      final db = await _dbHelper.database;
      List<String> conditions = [];
      if (selectedStatus.value != null) {
        conditions.add('pi.status = "${selectedStatus.value}"');
      }
      if (selectedSupplierId.value != null) {
        conditions.add('pi.supplier_id = ${selectedSupplierId.value}');
      }
      if (selectedMonth.value != null) {
        String monthStr = selectedMonth.value!.toString().padLeft(2, '0');
        conditions.add('strftime("%m", pi.invoice_date) = "$monthStr"');
      }
      if (selectedYear.value != null) {
        conditions.add(
          'strftime("%Y", pi.invoice_date) = "${selectedYear.value}"',
        );
      }

      if (showIncompleteOnly.value) {
        conditions.add(
          'NOT EXISTS (SELECT 1 FROM purchase_invoice_details pid WHERE pid.invoice_id = pi.id)',
        );
      }

      String whereClause = conditions.isNotEmpty
          ? 'WHERE ${conditions.join(' AND ')}'
          : '';

      String sortField = 'pi.created_at';
      switch (sortBy.value) {
        case 'total_nominal':
          sortField = 'pi.total_nominal';
          break;
        case 'due_date':
          sortField = 'pi.due_date';
          break;
        case 'created_at':
        default:
          sortField = 'pi.created_at';
          break;
      }
      String sortOrder = sortAscending.value ? 'ASC' : 'DESC';

      final maps = await db.rawQuery('''
        SELECT pi.*, s.name as supplier_name 
        FROM purchase_invoices pi
        LEFT JOIN suppliers s ON pi.supplier_id = s.id
        $whereClause
        ORDER BY $sortField $sortOrder
      ''');

      List<PurchaseInvoice> list = [];
      for (var map in maps) {
        var invoice = PurchaseInvoice.fromJson(map);
        // Fetch details
        final detailMaps = await db.rawQuery(
          '''
          SELECT d.*, p.name as product_name, u.name as unit_name, pu.name as base_unit_name
          FROM purchase_invoice_details d
          LEFT JOIN products p ON d.product_id = p.id
          LEFT JOIN units u ON d.unit_id = u.id
          LEFT JOIN units pu ON p.unit_id = pu.id
          WHERE d.invoice_id = ?
        ''',
          [invoice.id],
        );
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
        WHERE ps.supplier_id = ? AND p.id != -1
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
          paidAmount: invoice.paymentMethod == 'Tunai'
              ? invoice.totalNominal
              : 0.0,
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

          double ratio = d.unitPrice / d.baseUnitPrice;
          int intRatio = ratio.round();
          if (intRatio == 0) intRatio = 1;

          int addedStock = d.qty * intRatio;

          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [addedStock, d.productId],
          );

          await txn.insert('stock_movements', {
            'product_id': d.productId,
            'type': 'IN',
            'reference_id': invoiceId,
            'qty': addedStock,
            'balance_after': 0,
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
      await fetchInvoices();
      return true;
    } catch (e) {
      _logger.e("Error saving invoice", error: e);
      SnackbarHelper.show('Error', 'Gagal menyimpan invoice', isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> completeInvoice(
    PurchaseInvoice invoice,
    double newTotalNominal,
    List<PurchaseInvoiceDetail> details,
  ) async {
    isLoading.value = true;
    final db = await _dbHelper.database;
    try {
      await db.transaction((txn) async {
        double oldTotalNominal = invoice.totalNominal;
        double diff = newTotalNominal - oldTotalNominal;

        // 1. Update Invoice Nominal
        double paidAmount = invoice.paymentMethod == 'Tunai' ? newTotalNominal : invoice.paidAmount;
        await txn.update(
          'purchase_invoices',
          {
            'total_nominal': newTotalNominal,
            'paid_amount': paidAmount,
          },
          where: 'id = ?',
          whereArgs: [invoice.id],
        );

        // 2. Insert Details & Update Stock
        for (var d in details) {
          var newDetail = PurchaseInvoiceDetail(
            invoiceId: invoice.id!,
            productId: d.productId,
            unitId: d.unitId,
            qty: d.qty,
            unitPrice: d.unitPrice,
            totalPrice: d.totalPrice,
            baseUnitPrice: d.baseUnitPrice,
          );
          await txn.insert('purchase_invoice_details', newDetail.toJson());

          double ratio = d.unitPrice / d.baseUnitPrice;
          int intRatio = ratio.round();
          if (intRatio == 0) intRatio = 1;
          int addedStock = d.qty * intRatio;

          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ? WHERE id = ?',
            [addedStock, d.productId],
          );

          await txn.insert('stock_movements', {
            'product_id': d.productId,
            'type': 'IN',
            'reference_id': invoice.id,
            'qty': addedStock,
            'balance_after': 0,
            'note': 'Pelengkapan Pembelian ${invoice.invoiceNumber}',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        // 3. Update Supplier Debt if Hutang & nominal changed
        if (invoice.paymentMethod == 'Hutang' && diff != 0) {
          await txn.rawUpdate(
            'UPDATE suppliers SET debt_balance = debt_balance + ? WHERE id = ?',
            [diff, invoice.supplierId],
          );
        }
      });
      await fetchInvoices();
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
