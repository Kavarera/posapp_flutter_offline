import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/auth/auth_controller.dart';
import 'package:posapp_w6zxit6s/features/master_category/category_page.dart';
import 'package:posapp_w6zxit6s/features/master_supplier/supplier_page.dart';
import 'package:posapp_w6zxit6s/features/master_customer/customer_page.dart';
import 'package:posapp_w6zxit6s/features/master_product/product_page.dart';
import 'package:posapp_w6zxit6s/features/master_unit/unit_page.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_page.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/price_analysis_page.dart';
import 'package:posapp_w6zxit6s/features/monitoring_finance/finance_monitoring_page.dart';
import 'package:posapp_w6zxit6s/features/monitoring_stock/stock_card_page.dart';
import 'package:posapp_w6zxit6s/features/reporting/report_dashboard_page.dart';
import 'package:posapp_w6zxit6s/features/user_management/user_management_page.dart';
import 'package:posapp_w6zxit6s/core/constants/app_routes.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthController _authController = Get.find<AuthController>();

  int _selectedIndex = 0;

  // Placeholder pages for Master Data
  final List<Widget> _pages = [
    const Center(
      child: Text("Welcome to Kavarera POS", style: TextStyle(fontSize: 24)),
    ),
    const SupplierPage(),
    const CategoryPage(),
    const ProductPage(),
    const CustomerPage(),
    const UnitPage(),
    PurchaseInvoicePage(),
    PriceAnalysisPage(),
    FinanceMonitoringPage(),
    StockCardPage(),
    ReportDashboardPage(),
    UserManagementPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: AppColors.primary,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(
                  Icons.point_of_sale_rounded,
                  size: 48,
                  color: AppColors.white,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kavarera POS',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 10.0,
                  ),
                  width: double.infinity,
                  child: const Text(
                    textAlign: TextAlign.left,
                    'MENU UTAMA',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMenuItem(0, Icons.dashboard, "Dashboard"),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 10.0,
                  ),
                  width: double.infinity,
                  child: const Text(
                    'MASTER DATA',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMenuItem(1, Icons.local_shipping, "Master Supplier"),
                _buildMenuItem(2, Icons.category, "Master Kategori"),
                _buildMenuItem(5, Icons.straighten, "Master Satuan"),
                _buildMenuItem(3, Icons.inventory, "Master Barang"),
                _buildMenuItem(4, Icons.people, "Master Customer"),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 10.0,
                  ),
                  width: double.infinity,
                  child: const Text(
                    'PEMBELIAN',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildMenuItem(6, Icons.receipt_long, "Invoice Pembelian"),
                _buildMenuItem(7, Icons.analytics, "Analisis Harga"),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  width: double.infinity,
                  child: const Text('MONITORING', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                _buildMenuItem(8, Icons.account_balance_wallet, "Hutang & Piutang"),
                _buildMenuItem(9, Icons.history, "Kartu Stok"),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  width: double.infinity,
                  child: const Text('ADMIN', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                _buildMenuItem(10, Icons.bar_chart, "Laporan Analitik"),
                _buildMenuItem(11, Icons.manage_accounts, "Manajemen Akun"),
                    ],
                  ),
                ),

                const Divider(color: AppColors.accent),
                ListTile(
                  leading: const Icon(Icons.point_of_sale, color: Colors.orange),
                  title: const Text('Masuk Kasir', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Get.toNamed(AppRoutes.pos);
                  },
                ),
                const Divider(color: AppColors.accent),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.white),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.white),
                  ),
                  onTap: () {
                    _authController.logout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              color: AppColors.background.withOpacity(0.3),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : Colors.transparent,
        borderRadius: isSelected
            ? BorderRadius.circular(12)
            : BorderRadius.circular(0),
      ),
      margin: isSelected
          ? EdgeInsets.symmetric(horizontal: 8)
          : EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? AppColors.white
              : AppColors.white.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? AppColors.white
                : AppColors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
