import 'dart:io';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class FinanceMonitoringController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var payables = <Map<String, dynamic>>[].obs;
  var receivables = <Map<String, dynamic>>[].obs;

  var payableStatusFilter = 'Semua'.obs;
  var receivableStatusFilter = 'Semua'.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPayables();
    loadReceivables();
  }

  Future<void> loadPayables() async {
    isLoading.value = true;
    try {
      Database db = await _dbHelper.database;
      String where = "payment_method = 'Hutang'";
      List<String> whereArgs = [];
      if (payableStatusFilter.value != 'Semua') {
        where += " AND status = ?";
        whereArgs.add(payableStatusFilter.value);
      }

      var data = await db.rawQuery('''
        SELECT pi.*, s.name as supplier_name,
               (pi.total_nominal - pi.paid_amount) as sisa_tagihan
        FROM purchase_invoices pi
        LEFT JOIN suppliers s ON pi.supplier_id = s.id
        WHERE $where
        ORDER BY pi.invoice_date DESC
      ''', whereArgs);

      payables.assignAll(data);
    } catch (e) {
      _logger.e("Error loading payables", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadReceivables() async {
    isLoading.value = true;
    try {
      Database db = await _dbHelper.database;
      String where = "payment_method = 'Hutang'";
      List<String> whereArgs = [];
      if (receivableStatusFilter.value != 'Semua') {
        where += " AND status = ?";
        whereArgs.add(receivableStatusFilter.value);
      }

      var data = await db.rawQuery('''
        SELECT st.*, c.name as customer_name,
               (st.total_nominal - st.paid_amount) as sisa_tagihan
        FROM sales_transactions st
        LEFT JOIN customers c ON st.customer_id = c.id
        WHERE $where
        ORDER BY st.transaction_date DESC
      ''', whereArgs);

      receivables.assignAll(data);
    } catch (e) {
      _logger.e("Error loading receivables", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> _saveAttachment(File file) async {
    try {
      String attachmentsPath = PathService.attachmentsDir;
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
      String savedPath = p.join(attachmentsPath, fileName);
      await file.copy(savedPath);
      return savedPath;
    } catch (e) {
      _logger.e("Failed to save attachment", error: e);
      return null;
    }
  }

  Future<void> processPayment({
    required String type, // 'payable' or 'receivable'
    required int id,
    required double amount,
    required File attachment,
  }) async {
    try {
      String? savedPath = await _saveAttachment(attachment);
      if (savedPath == null) {
        SnackbarHelper.show(
          'Error',
          'Gagal menyimpan bukti pembayaran.',
          isError: true,
        );
        return;
      }

      Database db = await _dbHelper.database;
      await db.transaction((txn) async {
        // Insert Payment Transaction
        await txn.insert('payment_transactions', {
          'reference_type': type,
          'reference_id': id,
          'amount': amount,
          'payment_date': DateTime.now().toIso8601String(),
          'proof_document_path': savedPath,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Update Invoice & Check if Lunas
        if (type == 'payable') {
          var res = await txn.query(
            'purchase_invoices',
            where: 'id = ?',
            whereArgs: [id],
          );
          if (res.isNotEmpty) {
            double oldPaid = res.first['paid_amount'] as double;
            double total = res.first['total_nominal'] as double;
            int supplierId = res.first['supplier_id'] as int;

            double newPaid = oldPaid + amount;
            String newStatus = newPaid >= total ? 'Lunas' : 'Belum Lunas';

            await txn.update(
              'purchase_invoices',
              {'paid_amount': newPaid, 'status': newStatus},
              where: 'id = ?',
              whereArgs: [id],
            );

            await txn.rawUpdate(
              'UPDATE suppliers SET debt_balance = debt_balance - ? WHERE id = ?',
              [amount, supplierId],
            );
          }
        } else if (type == 'receivable') {
          var res = await txn.query(
            'sales_transactions',
            where: 'id = ?',
            whereArgs: [id],
          );
          if (res.isNotEmpty) {
            double oldPaid = res.first['paid_amount'] as double;
            double total = res.first['total_nominal'] as double;
            int customerId = res.first['customer_id'] as int;

            double newPaid = oldPaid + amount;
            String newStatus = newPaid >= total ? 'Lunas' : 'Belum Lunas';

            await txn.update(
              'sales_transactions',
              {'paid_amount': newPaid, 'status': newStatus},
              where: 'id = ?',
              whereArgs: [id],
            );

            await txn.rawUpdate(
              'UPDATE customers SET receivable_balance = receivable_balance - ? WHERE id = ?',
              [amount, customerId],
            );
          }
        }
      });

      SnackbarHelper.show(
        'Sukses',
        'Pelunasan berhasil disimpan.',
        isError: false,
      );
      if (type == 'payable') {
        loadPayables();
      } else {
        loadReceivables();
      }
    } catch (e) {
      _logger.e("Error processing payment", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memproses pelunasan: $e',
        isError: true,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(
    String type,
    int referenceId,
  ) async {
    try {
      Database db = await _dbHelper.database;
      return await db.query(
        'payment_transactions',
        where: 'reference_type = ? AND reference_id = ?',
        whereArgs: [type, referenceId],
        orderBy: 'payment_date DESC',
      );
    } catch (e) {
      _logger.e("Error getting payment history", error: e);
      return [];
    }
  }
}
