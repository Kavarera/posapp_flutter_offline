import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/material.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:posapp_w6zxit6s/core/services/printer_service.dart';

class POSController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var cartItems = <Map<String, dynamic>>[].obs;
  var customers = <Map<String, dynamic>>[].obs;
  var selectedCustomerId = RxnInt();

  var searchQuery = ''.obs;
  var searchResults = <Map<String, dynamic>>[].obs;

  var paymentMethod = 'Tunai'.obs; // Tunai, Hutang (Piutang bagi toko)
  var amountPaid = 0.0.obs;

  var uangDiterimaController = TextEditingController(text: '0');

  double get totalNominal {
    return cartItems.fold(
      0,
      (sum, item) => sum + (item['total_price'] as double),
    );
  }

  @override
  void onInit() {
    super.onInit();
    _loadCustomers();
    searchProducts(''); // Load initial 30 products
  }

  Future<void> _loadCustomers() async {
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> data = await db.query(
        'customers',
        where: 'status = ?',
        whereArgs: ['Aktif'],
        orderBy: 'name ASC',
      );
      customers.assignAll(data);
      if (data.isNotEmpty) {
        selectedCustomerId.value = data.first['id'] as int;
      }
    } catch (e) {
      _logger.e("Error loading customers", error: e);
    }
  }

  Future<void> searchProducts(String query) async {
    searchQuery.value = query;
    try {
      Database db = await _dbHelper.database;
      List<Map<String, dynamic>> data;
      if (query.isEmpty) {
        data = await db.rawQuery('''
          SELECT p.*, u.name as base_unit_name
          FROM products p
          LEFT JOIN units u ON p.unit_id = u.id
          LIMIT 30
        ''');
      } else {
        data = await db.rawQuery(
          '''
          SELECT p.*, u.name as base_unit_name
          FROM products p
          LEFT JOIN units u ON p.unit_id = u.id
          WHERE p.name LIKE ? OR p.barcode LIKE ?
          LIMIT 30
        ''',
          ['%$query%', '%$query%'],
        );
      }
      searchResults.assignAll(data);
    } catch (e) {
      _logger.e("Error searching products", error: e);
    }
  }

  void addToCart(Map<String, dynamic> product) {
    int index = cartItems.indexWhere(
      (item) => item['product_id'] == product['id'],
    );
    if (index >= 0) {
      var item = cartItems[index];
      int newQty = item['qty'] + 1;
      cartItems[index] = {
        ...item,
        'qty': newQty,
        'total_price': newQty * item['unit_price'],
      };
    } else {
      cartItems.add({
        'product_id': product['id'],
        'product_name': product['name'],
        'unit_id': product['unit_id'],
        'unit_name': product['base_unit_name'],
        'qty': 1,
        'unit_price': product['sell_price'],
        'base_unit_price':
            product['buy_price'], // Storing HPP for profit calculation
        'total_price': product['sell_price'],
      });
    }
    searchResults.clear();
    searchQuery.value = '';
  }

  void updateQty(int index, int qty) {
    if (qty <= 0) {
      cartItems.removeAt(index);
    } else {
      var item = cartItems[index];
      cartItems[index] = {
        ...item,
        'qty': qty,
        'total_price': qty * item['unit_price'],
      };
    }
  }

  void removeCartItem(int index) {
    cartItems.removeAt(index);
  }

  void setAmountPaid(String val) {
    String cleanVal = val.replaceAll(RegExp(r'[^0-9]'), '');
    amountPaid.value = double.tryParse(cleanVal) ?? 0.0;
  }

  Future<bool> processCheckout() async {
    if (cartItems.isEmpty) {
      SnackbarHelper.show(
        'Peringatan',
        'Keranjang masih kosong.',
        isError: true,
      );
      return false;
    }

    if (paymentMethod.value == 'Hutang') {
      if (selectedCustomerId.value == null) {
        SnackbarHelper.show(
          'Peringatan',
          'Pilih customer untuk transaksi Piutang.',
          isError: true,
        );
        return false;
      }
    } else {
      // Tunai
      if (amountPaid.value < totalNominal) {
        SnackbarHelper.show(
          'Peringatan',
          'Uang tunai kurang dari total belanja.',
          isError: true,
        );
        return false;
      }
    }

    try {
      Database db = await _dbHelper.database;
      await db.transaction((txn) async {
        String nowStr = DateTime.now().toIso8601String();
        String trxNumber = 'TRX-${DateTime.now().millisecondsSinceEpoch}';

        double actualPaid = paymentMethod.value == 'Tunai'
            ? totalNominal
            : 0.0; // If Hutang, paid_amount is 0 for now (could be DP, but let's assume 0)

        int insertedId = await txn.insert('sales_transactions', {
          'transaction_number': trxNumber,
          'customer_id': selectedCustomerId.value,
          'transaction_date': nowStr,
          'due_date': paymentMethod.value == 'Hutang'
              ? DateTime.now().add(const Duration(days: 14)).toIso8601String()
              : null,
          'payment_method': paymentMethod.value,
          'total_nominal': totalNominal,
          'paid_amount': actualPaid,
          'status': paymentMethod.value == 'Hutang' ? 'Belum Lunas' : 'Lunas',
          'created_at': nowStr,
        });

        for (var item in cartItems) {
          await txn.insert('sales_transaction_details', {
            'transaction_id': insertedId,
            'product_id': item['product_id'],
            'unit_id': item['unit_id'],
            'qty': item['qty'],
            'unit_price': item['unit_price'],
            'total_price': item['total_price'],
            'base_unit_price': item['base_unit_price'], // HPP
          });

          // Deduct Stock
          await txn.rawUpdate(
            'UPDATE products SET stock = stock - ? WHERE id = ?',
            [item['qty'], item['product_id']],
          );

          // Insert Stock Movement (OUT)
          await txn.insert('stock_movements', {
            'product_id': item['product_id'],
            'type': 'OUT',
            'reference_id': insertedId,
            'qty': item['qty'],
            'balance_after':
                0, // Placeholder, usually computed via trigger or read
            'note': 'Penjualan Kasir $trxNumber',
            'created_at': nowStr,
          });
        }

        // Update customer receivable if Piutang
        if (paymentMethod.value == 'Hutang' &&
            selectedCustomerId.value != null) {
          await txn.rawUpdate(
            'UPDATE customers SET receivable_balance = receivable_balance + ? WHERE id = ?',
            [totalNominal, selectedCustomerId.value],
          );
        }
      });

      Map<String, dynamic> transactionData = {
        'transaction_number': 'TRX-${DateTime.now().millisecondsSinceEpoch}',
        'transaction_date': DateTime.now().toIso8601String(),
        'total_nominal': totalNominal,
        'payment_method': paymentMethod.value,
        'paid_amount': paymentMethod.value == 'Tunai' ? totalNominal : 0.0,
      };
      List<Map<String, dynamic>> detailsForPrint = List.from(cartItems);

      // Bersihkan form SEBELUM memunculkan dialog, hanya jika sukses
      _clearForm();

      Get.defaultDialog(
        title: "Cetak Nota",
        middleText: "Ingin cetak nota untuk transaksi ini?",
        textConfirm: "Ya",
        textCancel: "Tidak",
        confirmTextColor: Colors.white,
        onConfirm: () async {
          Get.back();
          bool printed = await Get.put(PrinterService()).printReceipt(
            transaction: transactionData,
            details: detailsForPrint,
          );
          if (printed) {
            SnackbarHelper.show('Sukses', 'Struk berhasil dicetak');
          } else {
            SnackbarHelper.show(
              'Info',
              'Struk gagal dicetak, pastikan printer terhubung',
              isError: true,
            );
          }
        },
      );

      return true;
    } catch (e) {
      _logger.e("Error processing checkout", error: e);
      SnackbarHelper.show(
        'Error',
        'Gagal memproses transaksi: $e',
        isError: true,
      );
      return false;
    }
  }

  void _clearForm() {
    cartItems.clear();
    amountPaid.value = 0.0;
    paymentMethod.value = 'Tunai';
    uangDiterimaController.text = ''; // Kosongkan textfield
    searchProducts(''); // Reload 30 products instead of clearing
  }
}
