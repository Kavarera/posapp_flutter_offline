import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:posapp_w6zxit6s/core/constants/app_constants.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';

class UserManagementController extends GetxController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Logger _logger = Logger();

  var usersList = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    isLoading.value = true;
    try {
      Database db = await _dbHelper.database;
      var data = await db.query('users', orderBy: 'role ASC, username ASC');
      usersList.assignAll(data);
    } catch (e) {
      _logger.e("Error loading users", error: e);
    } finally {
      isLoading.value = false;
    }
  }

  String hashPassword(String raw) {
    String salt = AppConstants.passwordSalt;
    String passwordToHash = '$raw$salt';
    var bytes = utf8.encode(passwordToHash);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> addUser(String username, String password, String role) async {
    if (username.isEmpty || password.isEmpty || role.isEmpty) {
      SnackbarHelper.show('Error', 'Semua field harus diisi.', isError: true);
      return;
    }

    try {
      Database db = await _dbHelper.database;

      // Check duplicate
      var existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      if (existing.isNotEmpty) {
        SnackbarHelper.show(
          'Error',
          'Username sudah terdaftar.',
          isError: true,
        );
        return;
      }

      await db.insert('users', {
        'username': username,
        'password_hash': hashPassword(password),
        'role': role,
        'is_active': 1,
      });

      SnackbarHelper.show(
        'Sukses',
        'Pengguna berhasil ditambahkan.',
        isError: false,
      );
      Get.back(); // close dialog
      loadUsers();
    } catch (e) {
      _logger.e("Error adding user", error: e);
      SnackbarHelper.show('Error', 'Gagal menambah pengguna.', isError: true);
    }
  }

  Future<void> toggleUserStatus(int id, int currentStatus) async {
    if (id == 1) {
      // Default admin ID is usually 1, prevent disabling
      SnackbarHelper.show(
        'Peringatan',
        'Tidak dapat menonaktifkan Super Admin.',
        isError: true,
      );
      return;
    }

    try {
      Database db = await _dbHelper.database;
      int newStatus = currentStatus == 1 ? 0 : 1;
      await db.update(
        'users',
        {'is_active': newStatus},
        where: 'id = ?',
        whereArgs: [id],
      );

      loadUsers();
    } catch (e) {
      _logger.e("Error toggling user status", error: e);
    }
  }

  Future<void> resetPassword(int id, String newPassword) async {
    if (newPassword.isEmpty) {
      SnackbarHelper.show(
        'Error',
        'Password tidak boleh kosong.',
        isError: true,
      );
      return;
    }

    try {
      Database db = await _dbHelper.database;
      await db.update(
        'users',
        {'password_hash': hashPassword(newPassword)},
        where: 'id = ?',
        whereArgs: [id],
      );

      SnackbarHelper.show(
        'Sukses',
        'Password berhasil direset.',
        isError: false,
      );
      Get.back();
    } catch (e) {
      _logger.e("Error resetting password", error: e);
      SnackbarHelper.show('Error', 'Gagal mereset password.', isError: true);
    }
  }
}
