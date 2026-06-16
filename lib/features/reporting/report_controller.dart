import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:posapp_w6zxit6s/core/services/printer_service.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class ReportDataPayload {
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> products;

  ReportDataPayload(this.sales, this.products);
}

class ReportResult {
  final double totalOmzet;
  final double totalLaba;
  final int totalTransaksi;
  final double valuasiAset;

  ReportResult(
    this.totalOmzet,
    this.totalLaba,
    this.totalTransaksi,
    this.valuasiAset,
  );
}

// Top level function for Isolate
ReportResult _calculateReportMetrics(ReportDataPayload payload) {
  double omzet = 0;
  double laba = 0;
  int transaksi = 0;
  double valuasi = 0;

  // Process sales (which are joined with details in the query)
  // To avoid duplicate transactions count, we use a Set
  Set<int> transactionIds = {};

  for (var row in payload.sales) {
    int id = row['transaction_id'] as int;
    if (!transactionIds.contains(id)) {
      transactionIds.add(id);
      omzet += (row['total_nominal'] as num).toDouble();
      transaksi++;
    }

    double detailTotalPrice = (row['detail_total_price'] as num).toDouble();
    double detailHpp = (row['base_unit_price'] as num).toDouble();
    int qty = row['qty'] as int;
    double unitRatio = 1.0;
    // Usually HPP is base unit price, and sell price might be multiplied.
    // Laba = Total Price - (Base Unit Price * Qty * RatioToBase).
    // To simplify: if useKarton, qty is already karton qty, and we need total HPP for those kartons.
    // For simplicity, let's just do: total_price - (base_unit_price * qty) assuming base_unit_price in DB was already multiplied or stored correctly.
    // In our seeder, base_unit_price was 1 pcs price.
    // So if unitPrice is karton (x40), total_price = unitPrice * qty. HPP = base_unit_price * 40 * qty.
    // We should rely on a simpler formula for now or assuming base_unit_price in details table is the PER ITEM HPP (including ratio).
    // In our seeder, base_unit_price is the 1 pcs price. So we need ratio. But we don't have ratio here easily.
    // Let's just do an approximation or assume base_unit_price in details is the HPP for the 'unit' sold.
    // To be strictly correct according to our seeder:
    double unitPrice = (row['unit_price'] as num).toDouble();
    double ratio = unitPrice / detailHpp; // approximation of multiplier
    int intRatio = ratio.round() == 0 ? 1 : ratio.round();

    double totalHpp = detailHpp * intRatio * qty;
    laba += (detailTotalPrice - totalHpp);
  }

  // Process valuation
  for (var p in payload.products) {
    int stock = p['stock'] as int;
    double buyPrice = (p['buy_price'] as num).toDouble();
    valuasi += (stock * buyPrice);
  }

  return ReportResult(omzet, laba, transaksi, valuasi);
}

class ReportController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var isLoading = false.obs;

  var totalOmzet = 0.0.obs;
  var totalLaba = 0.0.obs;
  var totalTransaksi = 0.obs;
  var valuasiAset = 0.0.obs;

  var filterPeriode = 'Bulan Ini'.obs; // Hari Ini, Minggu Ini, Bulan Ini, Semua

  var transactionHistory = <Map<String, dynamic>>[].obs;

  // Advanced Report State
  var advancedStartDate = Rxn<DateTime>();
  var advancedEndDate = Rxn<DateTime>();
  var advancedReportType = 'Umum'.obs; // 'Umum' (Histori Pembelian) atau 'Detail' (Histori Pembelian Detail)
  var advancedReportData = <Map<String, dynamic>>[].obs;
  var isGeneratingAdvanced = false.obs;

  @override
  void onInit() {
    super.onInit();
    generateReport();
  }

  Future<void> generateReport() async {
    isLoading.value = true;
    try {
      Database db = await _dbHelper.database;

      String dateFilter = '';
      DateTime now = DateTime.now();
      if (filterPeriode.value == 'Hari Ini') {
        dateFilter =
            "AND st.transaction_date >= '${now.toIso8601String().substring(0, 10)} 00:00:00'";
      } else if (filterPeriode.value == 'Minggu Ini') {
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        dateFilter =
            "AND st.transaction_date >= '${startOfWeek.toIso8601String().substring(0, 10)} 00:00:00'";
      } else if (filterPeriode.value == 'Bulan Ini') {
        dateFilter =
            "AND st.transaction_date >= '${now.year}-${now.month.toString().padLeft(2, '0')}-01 00:00:00'";
      }

      var salesData = await db.rawQuery('''
        SELECT st.id as transaction_id, st.total_nominal,
               std.qty, std.unit_price, std.total_price as detail_total_price, std.base_unit_price
        FROM sales_transactions st
        JOIN sales_transaction_details std ON st.id = std.transaction_id
        WHERE 1=1 $dateFilter
      ''');

      var productsData = await db.query(
        'products',
        columns: ['id', 'stock', 'buy_price'],
      );

      // Execute computation in separate Isolate
      ReportDataPayload payload = ReportDataPayload(salesData, productsData);
      ReportResult result = await compute(_calculateReportMetrics, payload);

      totalOmzet.value = result.totalOmzet;
      totalLaba.value = result.totalLaba;
      totalTransaksi.value = result.totalTransaksi;
      valuasiAset.value = result.valuasiAset;
      // Transaction History
      List<Map<String, dynamic>> history = [];

      var purchasesData = await db.rawQuery('''
        SELECT id, invoice_number as reference, invoice_date as date, 'Pembelian' as type, total_nominal, status, supplier_id as entity_id
        FROM purchase_invoices pi
        WHERE EXISTS (SELECT 1 FROM purchase_invoice_details pid WHERE pid.invoice_id = pi.id AND pid.qty > 0) 
        ${dateFilter.replaceAll('st.transaction_date', 'invoice_date')}
      ''');

      var historySales = await db.rawQuery('''
        SELECT id, transaction_number as reference, transaction_date as date, 'Penjualan' as type, total_nominal, status, customer_id as entity_id
        FROM sales_transactions st
        WHERE 1=1 $dateFilter
      ''');

      history.addAll(purchasesData);
      history.addAll(historySales);
      history.sort((a, b) {
        DateTime dateA = DateTime.parse(a['date']);
        DateTime dateB = DateTime.parse(b['date']);
        return dateB.compareTo(dateA); // Descending
      });
      transactionHistory.assignAll(history);

    } catch (e) {
      _logger.e("Error generating report", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rePrintReceipt(int transactionId) async {
    try {
      Database db = await _dbHelper.database;
      var stData = await db.query(
        'sales_transactions',
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      if (stData.isEmpty) return;

      var detailsData = await db.rawQuery('''
        SELECT std.*, p.name as product_name
        FROM sales_transaction_details std
        JOIN products p ON std.product_id = p.id
        WHERE std.transaction_id = ?
      ''', [transactionId]);

      // Need to import PrinterService and SnackbarHelper at the top of file
      // Wait, let's just use Get.put
      bool printed = await Get.put(PrinterService()).printReceipt(
        transaction: stData.first,
        details: detailsData,
      );

      if (printed) {
        SnackbarHelper.show('Sukses', 'Struk berhasil dicetak ulang');
      } else {
        SnackbarHelper.show('Info', 'Gagal mencetak, pastikan printer terhubung', isError: true);
      }
    } catch (e) {
      _logger.e("Error re-printing", error: e);
    }
  }

  Future<void> generateAdvancedReport() async {
    isGeneratingAdvanced.value = true;
    advancedReportData.clear();
    try {
      if (advancedStartDate.value == null || advancedEndDate.value == null) {
        SnackbarHelper.show('Validasi', 'Silakan pilih rentang tanggal', isError: true);
        return;
      }

      Database db = await _dbHelper.database;
      
      // We format to YYYY-MM-DD
      String startStr = DateFormat('yyyy-MM-dd').format(advancedStartDate.value!);
      String endStr = DateFormat('yyyy-MM-dd').format(advancedEndDate.value!);

      if (advancedReportType.value == 'Umum') {
        var data = await db.rawQuery('''
          SELECT pi.invoice_number, pi.supplier_invoice_number, pi.invoice_date, s.name as supplier_name, pi.total_nominal, pi.status, pi.payment_method
          FROM purchase_invoices pi
          LEFT JOIN suppliers s ON pi.supplier_id = s.id
          WHERE date(pi.invoice_date) BETWEEN ? AND ?
          AND EXISTS (SELECT 1 FROM purchase_invoice_details pid WHERE pid.invoice_id = pi.id AND pid.qty > 0)
          ORDER BY pi.invoice_date DESC
        ''', [startStr, endStr]);
        advancedReportData.assignAll(data);
      } else if (advancedReportType.value == 'Detail') {
        var data = await db.rawQuery('''
          SELECT pi.invoice_number, pi.supplier_invoice_number, pi.invoice_date, s.name as supplier_name, p.name as product_name, pid.qty, pid.unit_price, pid.total_price
          FROM purchase_invoice_details pid
          JOIN purchase_invoices pi ON pid.invoice_id = pi.id
          LEFT JOIN suppliers s ON pi.supplier_id = s.id
          JOIN products p ON pid.product_id = p.id
          WHERE date(pi.invoice_date) BETWEEN ? AND ?
          AND pid.qty > 0
          ORDER BY pi.invoice_date DESC
        ''', [startStr, endStr]);
        advancedReportData.assignAll(data);
      } else if (advancedReportType.value == 'Penjualan Umum') {
        var data = await db.rawQuery('''
          SELECT st.transaction_number as invoice_number, st.transaction_date as invoice_date, st.total_nominal, st.status, st.payment_method
          FROM sales_transactions st
          WHERE date(st.transaction_date) BETWEEN ? AND ?
          ORDER BY st.transaction_date DESC
        ''', [startStr, endStr]);
        advancedReportData.assignAll(data);
      } else if (advancedReportType.value == 'Penjualan Detail') {
        var data = await db.rawQuery('''
          SELECT st.transaction_number as invoice_number, st.transaction_date as invoice_date, p.name as product_name, std.qty, std.unit_price, std.total_price
          FROM sales_transaction_details std
          JOIN sales_transactions st ON std.transaction_id = st.id
          JOIN products p ON std.product_id = p.id
          WHERE date(st.transaction_date) BETWEEN ? AND ?
          ORDER BY st.transaction_date DESC
        ''', [startStr, endStr]);
        advancedReportData.assignAll(data);
      }
    } catch (e) {
      _logger.e("Error generating advanced report", error: e);
      SnackbarHelper.show('Error', 'Gagal memuat laporan lanjutan', isError: true);
    } finally {
      isGeneratingAdvanced.value = false;
    }
  }

  Future<void> exportToCSV() async {
    if (advancedReportData.isEmpty) {
      SnackbarHelper.show('Info', 'Tidak ada data untuk diekspor');
      return;
    }

    try {
      List<List<dynamic>> csvData = [];
      
      String formatDateCSV(String dateString) {
        try {
          final date = DateTime.parse(dateString);
          return DateFormat('dd MMM yyyy HH:mm').format(date);
        } catch (e) {
          return dateString;
        }
      }
      
      // Header
      if (advancedReportType.value == 'Umum') {
        csvData.add(['No Invoice', 'No Invoice Supplier', 'Tanggal', 'Supplier', 'Total Nominal', 'Status', 'Metode Pembayaran']);
        for (var row in advancedReportData) {
          csvData.add([
            row['invoice_number'],
            row['supplier_invoice_number'] ?? '-',
            formatDateCSV(row['invoice_date'].toString()),
            row['supplier_name'] ?? '-',
            row['total_nominal'],
            row['status'],
            row['payment_method'],
          ]);
        }
      } else if (advancedReportType.value == 'Detail') {
        csvData.add(['No Invoice', 'No Invoice Supplier', 'Tanggal', 'Supplier', 'Nama Barang', 'Qty', 'Harga Satuan', 'Total Harga']);
        for (var row in advancedReportData) {
          csvData.add([
            row['invoice_number'],
            row['supplier_invoice_number'] ?? '-',
            formatDateCSV(row['invoice_date'].toString()),
            row['supplier_name'] ?? '-',
            row['product_name'] ?? '-',
            row['qty'],
            row['unit_price'],
            row['total_price'],
          ]);
        }
      } else if (advancedReportType.value == 'Penjualan Umum') {
        csvData.add(['No Transaksi', 'Tanggal', 'Total Nominal', 'Status', 'Metode Pembayaran']);
        for (var row in advancedReportData) {
          csvData.add([
            row['invoice_number'],
            formatDateCSV(row['invoice_date'].toString()),
            row['total_nominal'],
            row['status'],
            row['payment_method'],
          ]);
        }
      } else if (advancedReportType.value == 'Penjualan Detail') {
        csvData.add(['No Transaksi', 'Tanggal', 'Nama Barang', 'Qty', 'Harga Satuan', 'Total Harga']);
        for (var row in advancedReportData) {
          csvData.add([
            row['invoice_number'],
            formatDateCSV(row['invoice_date'].toString()),
            row['product_name'] ?? '-',
            row['qty'],
            row['unit_price'],
            row['total_price'],
          ]);
        }
      }

      String csvString = const ListToCsvConverter().convert(csvData);

      final directory = await getApplicationDocumentsDirectory();
      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String typeStr = advancedReportType.value.replaceAll(' ', '_');
      String filePath = '${directory.path}/Kavarera_Report_$typeStr\_$timestamp.csv';

      final file = File(filePath);
      await file.writeAsString(csvString);

      SnackbarHelper.show('Sukses', 'File berhasil disimpan di:\n$filePath');
      
      // Auto open the file using system command
      if (Platform.isWindows) {
        Process.run('explorer.exe', [filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [filePath]);
      }
    } catch (e) {
      _logger.e("Error exporting to CSV", error: e);
      SnackbarHelper.show('Error', 'Gagal mengekspor file', isError: true);
    }
  }
}
