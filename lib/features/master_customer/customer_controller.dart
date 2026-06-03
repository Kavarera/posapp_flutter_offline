import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/models/customer.dart';

class CustomerController extends GetxController {
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var customers = <Customer>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      isLoading.value = true;
      Database db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('customers');
      customers.value = maps.map((e) => Customer.fromJson(e)).toList();
    } catch (e) {
      _logger.e("Error fetching customers", error: e);
      Get.snackbar('Error', 'Gagal memuat customer');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      Database db = await _dbHelper.database;
      await db.insert('customers', customer.toJson());
      _logger.i("Customer ${customer.name} added");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error adding customer", error: e);
      Get.snackbar('Error', 'Gagal menambahkan customer.');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      Database db = await _dbHelper.database;
      await db.update('customers', customer.toJson(), where: 'id = ?', whereArgs: [customer.id]);
      _logger.i("Customer ${customer.id} updated");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error updating customer", error: e);
      Get.snackbar('Error', 'Gagal memperbarui customer.');
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      Database db = await _dbHelper.database;
      await db.delete('customers', where: 'id = ?', whereArgs: [id]);
      _logger.i("Customer $id deleted");
      await fetchCustomers();
    } catch (e) {
      _logger.e("Error deleting customer", error: e);
      Get.snackbar('Error', 'Gagal menghapus customer.');
    }
  }
}
