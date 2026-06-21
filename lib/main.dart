import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:window_manager/window_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'package:posapp_w6zxit6s/core/theme/app_theme.dart';
import 'package:posapp_w6zxit6s/core/constants/app_routes.dart';
import 'package:posapp_w6zxit6s/features/auth/login_page.dart';
import 'package:posapp_w6zxit6s/features/dashboard/dashboard_page.dart';
import 'package:posapp_w6zxit6s/features/auth/auth_controller.dart';
import 'package:posapp_w6zxit6s/core/services/session_service.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync(() => PathService().init());
  // Initialize Desktop Window Manager
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1024, 768),
      minimumSize: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: "Kavarera POS",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.center();
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }
  Get.put(SessionService());
  Get.put(AuthController(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Kavarera POS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
    );
  }
}
