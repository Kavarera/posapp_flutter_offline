import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/constants/app_routes.dart';
import 'package:posapp_w6zxit6s/core/services/session_service.dart';

class AuthMiddleware extends GetMiddleware {
  final List<String> allowedRoles;

  AuthMiddleware({required this.allowedRoles});

  @override
  RouteSettings? redirect(String? route) {
    final session = Get.find<SessionService>();
    
    if (session.role == null) {
      // Not logged in
      return const RouteSettings(name: AppRoutes.login);
    }
    
    if (!allowedRoles.contains(session.role)) {
      // Role not allowed
      // Redirect to their default page
      if (session.role == 'Kasir') {
        return const RouteSettings(name: AppRoutes.pos);
      } else {
        return const RouteSettings(name: AppRoutes.dashboard);
      }
    }
    
    return null; // Let them through
  }
}
