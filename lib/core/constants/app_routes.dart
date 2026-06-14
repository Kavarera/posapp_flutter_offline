import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/features/auth/login_page.dart';
import 'package:posapp_w6zxit6s/features/dashboard/dashboard_page.dart';
import 'package:posapp_w6zxit6s/features/pos/pos_page.dart';
import 'package:posapp_w6zxit6s/core/middleware/auth_middleware.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard'; // Container for the Master Data pages
  static const String pos = '/pos'; // Point of Sale Kasir
  
  static const String masterSupplier = '/master/supplier';
  static const String masterCategory = '/master/category';
  static const String masterProduct = '/master/product';
  static const String masterCustomer = '/master/customer';

  static final routes = [
    GetPage(name: login, page: () => const LoginPage()),
    GetPage(
      name: dashboard, 
      page: () => const DashboardPage(),
      middlewares: [AuthMiddleware(allowedRoles: ['Admin'])],
    ),
    GetPage(
      name: pos, 
      page: () => PosPage(),
      middlewares: [AuthMiddleware(allowedRoles: ['Admin', 'Kasir'])],
    ),
  ];
}
