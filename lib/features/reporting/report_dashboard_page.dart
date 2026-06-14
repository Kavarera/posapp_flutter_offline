import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'report_controller.dart';

class ReportDashboardPage extends StatelessWidget {
  ReportDashboardPage({Key? key}) : super(key: key);

  final ReportController _controller = Get.put(ReportController());
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Laporan & Analitik',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 1,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Periode Waktu: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 16),
                Obx(
                  () => DropdownButton<String>(
                    value: _controller.filterPeriode.value,
                    items: const [
                      DropdownMenuItem(
                        value: 'Hari Ini',
                        child: Text('Hari Ini'),
                      ),
                      DropdownMenuItem(
                        value: 'Minggu Ini',
                        child: Text('Minggu Ini'),
                      ),
                      DropdownMenuItem(
                        value: 'Bulan Ini',
                        child: Text('Bulan Ini'),
                      ),
                      DropdownMenuItem(
                        value: 'Semua Waktu',
                        child: Text('Semua Waktu'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _controller.filterPeriode.value = val;
                        _controller.generateReport();
                      }
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _controller.generateReport,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                    _buildMetricCard(
                      'Total Omzet (Penjualan)',
                      _currencyFormat.format(_controller.totalOmzet.value),
                      Icons.monetization_on,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Total Laba Kotor',
                      _currencyFormat.format(_controller.totalLaba.value),
                      Icons.trending_up,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Total Transaksi',
                      '${_controller.totalTransaksi.value} Struk',
                      Icons.receipt,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'Valuasi Aset Gudang (Modal)',
                      _currencyFormat.format(_controller.valuasiAset.value),
                      Icons.inventory,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _controller.transactionHistory.isEmpty
                    ? const Center(child: Text('Tidak ada riwayat transaksi pada periode ini.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _controller.transactionHistory.length,
                        itemBuilder: (context, index) {
                          final item = _controller.transactionHistory[index];
                          bool isPenjualan = item['type'] == 'Penjualan';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isPenjualan ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                child: Icon(
                                  isPenjualan ? Icons.arrow_outward : Icons.file_download,
                                  color: isPenjualan ? Colors.blue : Colors.orange,
                                ),
                              ),
                              title: Text('${item['reference']} - ${item['type']}'),
                              subtitle: Text('Tanggal: ${item['date']} | Status: ${item['status']}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _currencyFormat.format(item['total_nominal']),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  if (isPenjualan) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.print, color: Colors.grey),
                                      tooltip: 'Cetak Ulang Struk',
                                      onPressed: () => _controller.rePrintReceipt(item['id'] as int),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
