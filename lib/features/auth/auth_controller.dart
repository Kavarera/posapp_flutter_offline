import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:posapp_w6zxit6s/core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/constants/app_routes.dart';
import 'package:posapp_w6zxit6s/core/services/session_service.dart';

class AuthController extends GetxController {
  final _secureStorage = const FlutterSecureStorage();
  final _dbHelper = DatabaseHelper();
  final _logger = Logger();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var isObscureText = true.obs;

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  void togglePasswordVisibility() {
    isObscureText.value = !isObscureText.value;
  }

  Future<void> _checkExistingSession() async {
    try {
      String? token = await _secureStorage.read(key: 'session_token');
      String? role = await _secureStorage.read(key: 'session_role');
      if (token != null && role != null) {
        Get.find<SessionService>().setSession(token, role);
        _logger.i("Existing session found. Redirecting...");
        if (role == 'Kasir') {
          Get.offAllNamed(AppRoutes.pos);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      _logger.e("Failed to check session", error: e);
    }
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      errorMessage.value = "Username dan Password/PIN tidak boleh kosong.";
      Get.snackbar("Error", errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      Database db = await _dbHelper.database;
      
      // Fetch user from DB
      List<Map<String, dynamic>> results = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (results.isEmpty) {
        throw Exception("Username tidak ditemukan.");
      }

      var user = results.first;
      
      // Hash inputted password
      String salt = AppConstants.passwordSalt;
      String passwordToHash = '$password$salt';
      var bytes = utf8.encode(passwordToHash);
      var digest = sha256.convert(bytes);
      String inputHash = digest.toString();

      if (user['password_hash'] == inputHash || user['pin_hash'] == inputHash) {
        // Login success, create session
        await _secureStorage.write(key: 'session_token', value: user['id'].toString());
        await _secureStorage.write(key: 'session_role', value: user['role'].toString());
        
        Get.find<SessionService>().setSession(user['id'].toString(), user['role'].toString());
        
        _logger.i("User $username logged in successfully.");
        if (user['role'] == 'Kasir') {
          Get.offAllNamed(AppRoutes.pos);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      } else {
        throw Exception("Password atau PIN salah.");
      }

    } catch (e) {
      errorMessage.value = e.toString().replaceAll("Exception: ", "");
      Get.snackbar("Login Gagal", errorMessage.value, snackPosition: SnackPosition.BOTTOM);
      _logger.w("Login failed for $username: ${errorMessage.value}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'session_token');
    await _secureStorage.delete(key: 'session_role');
    Get.find<SessionService>().clearSession();
    Get.offAllNamed(AppRoutes.login);
  }
}
