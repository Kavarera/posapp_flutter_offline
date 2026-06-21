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

  // searchResults no longer needed for Autocomplete

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

  Future<List<Map<String, dynamic>>> searchProductsAsync(String query) async {
    try {
      Database db = await _dbHelper.database;
      if (query.isEmpty) {
        return await db.rawQuery('''
          SELECT p.*, u.name as base_unit_name
          FROM products p
          LEFT JOIN units u ON p.unit_id = u.id
          WHERE p.id != -1
          LIMIT 50
        ''');
      } else {
        return await db.rawQuery(
          '''
          SELECT p.*, u.name as base_unit_name
          FROM products p
          LEFT JOIN units u ON p.unit_id = u.id
          WHERE (p.name LIKE ? OR p.barcode LIKE ?) AND p.id != -1
          LIMIT 50
        ''',
          ['%$query%', '%$query%'],
        );
      }
    } catch (e) {
      _logger.e("Error searching products", error: e);
      return [];
    }
  }

  void addToCart(Map<String, dynamic> product) {
    int index = cartItems.indexWhere(
      (item) => item['product_id'] == product['id'],
    );
    if (index >= 0) {
      updateQty(index, cartItems[index]['qty'] + 1);
    } else {
      cartItems.add({
        'product_id': product['id'],
        'product_name': product['name'],
        'unit_id': product['unit_id'],
        'unit_name': product['base_unit_name'],
        'qty': 1,
        'normal_price': product['sell_price'],
        'wholesale_qty': product['wholesale_qty'] ?? 0,
        'wholesale_price': (product['wholesale_price'] ?? 0).toDouble(),
        'is_wholesale_approved': false,
        'unit_price': product['sell_price'],
        'base_unit_price':
            product['buy_price'], // Storing HPP for profit calculation
        'total_price': product['sell_price'],
      });
      // Check if wholesale applies at qty = 1
      updateQty(cartItems.length - 1, 1);
    }
  }

  void updateQty(int index, int qty) {
    if (qty <= 0) {
      cartItems.removeAt(index);
    } else {
      var item = cartItems[index];
      int wQty = item['wholesale_qty'] ?? 0;

      if (wQty > 0 && qty >= wQty && item['is_wholesale_approved'] == false) {
        // Prompt dialog
        Get.defaultDialog(
          title: "Harga Grosir",
          middleText:
              "Kuantitas mencapai minimum grosir ($wQty). Gunakan harga grosir?",
          textConfirm: "Ya",
          textCancel: "Tidak",
          confirmTextColor: Colors.white,
          onConfirm: () {
            _applyQtyChange(index, qty, true);
            Get.back();
          },
          onCancel: () {
            _applyQtyChange(index, qty, false);
          },
        );
      } else {
        bool isApproved = item['is_wholesale_approved'] ?? false;
        // If qty drops below wholesale, reset approval
        if (wQty > 0 && qty < wQty) {
          isApproved = false;
        }
        _applyQtyChange(index, qty, isApproved);
      }
    }
  }

  void _applyQtyChange(int index, int qty, bool isWholesaleApproved) {
    var item = cartItems[index];
    int wQty = item['wholesale_qty'] ?? 0;
    double wPrice = (item['wholesale_price'] ?? 0).toDouble();
    double nPrice = (item['normal_price'] ?? item['unit_price']).toDouble();

    double totalPrice = 0;
    if (wQty > 0 && isWholesaleApproved && qty >= wQty) {
      int grosirCount = (qty ~/ wQty) * wQty;
      int normalCount = qty % wQty;
      totalPrice = (grosirCount * wPrice) + (normalCount * nPrice);
    } else {
      totalPrice = qty * nPrice;
    }

    cartItems[index] = {
      ...item,
      'qty': qty,
      'is_wholesale_approved': isWholesaleApproved,
      'total_price': totalPrice,
    };
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
      var selectedCust = customers.firstWhereOrNull(
        (c) => c['id'] == selectedCustomerId.value,
      );
      if (selectedCust == null || selectedCust['name'] == 'Pelanggan Umum') {
        SnackbarHelper.show(
          'Peringatan',
          'Pembayaran hutang hanya berlaku untuk Member terdaftar (Bukan Pelanggan Umum).',
          isError: true,
        );
        return false;
      }

      double currentHutang = (selectedCust['receivable_balance'] ?? 0)
          .toDouble();
      double maxCredit = (selectedCust['max_credit'] ?? 0).toDouble();

      if (maxCredit > 0 && (currentHutang + totalNominal) > maxCredit) {
        SnackbarHelper.show(
          'Limit Hutang Terlampaui',
          'Total hutang (Rp ${(currentHutang + totalNominal).toInt()}) melebihi limit maksimal (Rp ${maxCredit.toInt()}).',
          isError: true,
        );
        return false;
      }
    } else if (paymentMethod.value == 'Tunai') {
      if (amountPaid.value < totalNominal) {
        SnackbarHelper.show(
          'Peringatan',
          'Uang tunai kurang dari total belanja.',
          isError: true,
        );
        return false;
      }
    } else if (paymentMethod.value == 'Digital') {
      // Pembayaran Digital
      bool confirmed =
          await Get.defaultDialog<bool>(
            title: "Konfirmasi Pembayaran Digital",
            middleText:
                "Apakah pembayaran sebesar Rp ${totalNominal.toInt()} sudah diterima ke rekening Anda?",
            textConfirm: "Sudah",
            textCancel: "Belum",
            confirmTextColor: Colors.white,
            onConfirm: () => Get.back(result: true),
            onCancel: () {},
          ) ??
          false;

      if (!confirmed) {
        return false; // Batal simpan
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
          'paid_amount': amountPaid.value,
          'status': paymentMethod.value == 'Hutang' ? 'Belum Lunas' : 'Lunas',
          'created_at': nowStr,
        });

        for (var item in cartItems) {
          int wQty = item['wholesale_qty'] ?? 0;
          bool isWholesaleApproved = item['is_wholesale_approved'] ?? false;
          int qty = item['qty'];
          double nPrice = (item['normal_price'] ?? item['unit_price'])
              .toDouble();
          double wPrice = (item['wholesale_price'] ?? 0).toDouble();

          List<Map<String, dynamic>> finalRows = [];

          if (wQty > 0 && isWholesaleApproved && qty >= wQty) {
            int grosirCount = (qty ~/ wQty) * wQty;
            int normalCount = qty % wQty;

            finalRows.add({
              'qty': grosirCount,
              'unit_price': wPrice,
              'total_price': grosirCount * wPrice,
            });
            if (normalCount > 0) {
              finalRows.add({
                'qty': normalCount,
                'unit_price': nPrice,
                'total_price': normalCount * nPrice,
              });
            }
          } else {
            finalRows.add({
              'qty': qty,
              'unit_price': nPrice,
              'total_price': qty * nPrice,
            });
          }

          for (var row in finalRows) {
            await txn.insert('sales_transaction_details', {
              'transaction_id': insertedId,
              'product_id': item['product_id'],
              'unit_id': item['unit_id'] ?? 1,
              'qty': row['qty'],
              'unit_price': row['unit_price'],
              'total_price': row['total_price'],
              'base_unit_price': item['base_unit_price'], // HPP
              'custom_product_name': item['product_id'] == -1
                  ? item['product_name']
                  : null,
              'is_custom': item['product_id'] == -1 ? 1 : 0,
            });
          }

          // Deduct Stock only if it's NOT a custom item
          if (item['product_id'] != -1) {
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
                  0, // Should be computed but 0 for performance now
              'note': 'Penjualan Kasir $trxNumber',
              'created_at': nowStr,
            });
          }
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
  }
}
