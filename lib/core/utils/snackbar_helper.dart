import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';

class SnackbarHelper {
  static void show(String title, String message, {bool isError = false}) {
    // Dismiss any active snackbar first to avoid stacking
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: AppColors.white,
      colorText: AppColors.textPrimary,
      margin: const EdgeInsets.only(top: 24, right: 24),
      maxWidth: 350,
      borderWidth: 1,
      borderColor: isError ? AppColors.error : AppColors.primary,
      icon: Icon(
        isError ? Icons.error_outline : Icons.info_outline,
        color: isError ? AppColors.error : AppColors.primary,
      ),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      duration: const Duration(seconds: 2),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
