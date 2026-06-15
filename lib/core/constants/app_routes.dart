import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/features/auth/login_page.dart';
import 'package:posapp_w6zxit6s/features/dashboard/dashboard_page.dart';
import 'package:posapp_w6zxit6s/features/pos/pos_page.dart';
import 'package:posapp_w6zxit6s/core/middleware/auth_middleware.dart';
import 'package:posapp_w6zxit6s/features/master_supplier/supplier_page.dart' as posapp_supplier;
import 'package:posapp_w6zxit6s/features/master_category/category_page.dart' as posapp_category;
import 'package:posapp_w6zxit6s/features/master_product/product_page.dart' as posapp_product;
import 'package:posapp_w6zxit6s/features/master_customer/customer_page.dart' as posapp_customer;
import 'package:posapp_w6zxit6s/features/master_unit/unit_page.dart' as posapp_unit;

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard'; // Container for the Master Data pages
  static const String pos = '/pos'; // Point of Sale Kasir
  
  static const String masterSupplier = '/master/supplier';
  static const String masterCategory = '/master/category';
  static const String masterProduct = '/master/product';
  static const String masterCustomer = '/master/customer';

  static const String masterUnit = '/master/unit';

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
    GetPage(
      name: masterSupplier,
      page: () => const posapp_supplier.SupplierPage(),
    ),
    GetPage(
      name: masterCategory,
      page: () => const posapp_category.CategoryPage(),
    ),
    GetPage(
      name: masterProduct,
      page: () => const posapp_product.ProductPage(),
    ),
    GetPage(
      name: masterCustomer,
      page: () => const posapp_customer.CustomerPage(),
    ),
    GetPage(
      name: masterUnit,
      page: () => const posapp_unit.UnitPage(),
    ),
  ];
}
