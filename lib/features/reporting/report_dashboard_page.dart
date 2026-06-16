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

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

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
                  onPressed: () => _showAdvancedReportOptionsDialog(context),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Advanced Laporan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
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
                              subtitle: Text('Tanggal: ${_formatDateString(item['date'].toString())} | Status: ${item['status']}'),
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

  void _showAdvancedReportOptionsDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Advanced Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rentang Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _controller.advancedStartDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) _controller.advancedStartDate.value = date;
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Dari Tanggal'),
                            child: Text(
                              _controller.advancedStartDate.value != null
                                  ? DateFormat('dd MMM yyyy').format(_controller.advancedStartDate.value!)
                                  : 'Pilih Tanggal',
                            ),
                          ),
                        )),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Obx(() => InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _controller.advancedEndDate.value ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) _controller.advancedEndDate.value = date;
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Sampai Tanggal'),
                            child: Text(
                              _controller.advancedEndDate.value != null
                                  ? DateFormat('dd MMM yyyy').format(_controller.advancedEndDate.value!)
                                  : 'Pilih Tanggal',
                            ),
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Tipe Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
              Obx(() => RadioListTile<String>(
                    title: const Text('Histori Pembelian (Umum)'),
                    value: 'Umum',
                    groupValue: _controller.advancedReportType.value,
                    onChanged: (val) => _controller.advancedReportType.value = val!,
                    contentPadding: EdgeInsets.zero,
                  )),
              Obx(() => RadioListTile<String>(
                    title: const Text('Histori Pembelian Detail (Per Barang)'),
                    value: 'Detail',
                    groupValue: _controller.advancedReportType.value,
                    onChanged: (val) => _controller.advancedReportType.value = val!,
                    contentPadding: EdgeInsets.zero,
                  )),
              Obx(() => RadioListTile<String>(
                    title: const Text('Histori Penjualan (Umum)'),
                    value: 'Penjualan Umum',
                    groupValue: _controller.advancedReportType.value,
                    onChanged: (val) => _controller.advancedReportType.value = val!,
                    contentPadding: EdgeInsets.zero,
                  )),
              Obx(() => RadioListTile<String>(
                    title: const Text('Histori Penjualan Detail (Per Barang)'),
                    value: 'Penjualan Detail',
                    groupValue: _controller.advancedReportType.value,
                    onChanged: (val) => _controller.advancedReportType.value = val!,
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Get.back();
              await _controller.generateAdvancedReport();
              _showAdvancedReportPreviewDialog(context);
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedReportPreviewDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Text(
                        'Preview: Laporan ${_controller.advancedReportType.value}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      )),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _controller.exportToCSV(),
                        icon: const Icon(Icons.file_download),
                        label: const Text('Export Excel (CSV)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              Expanded(
                child: Obx(() {
                  if (_controller.isGeneratingAdvanced.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_controller.advancedReportData.isEmpty) {
                    return const Center(child: Text('Tidak ada data pada periode ini.'));
                  }

                  bool isUmum = _controller.advancedReportType.value == 'Umum';
                  bool isDetail = _controller.advancedReportType.value == 'Detail';
                  bool isPenjualanUmum = _controller.advancedReportType.value == 'Penjualan Umum';
                  bool isPenjualanDetail = _controller.advancedReportType.value == 'Penjualan Detail';

                  List<DataColumn> getColumns() {
                    if (isUmum) {
                      return const [
                        DataColumn(label: Text('No Invoice')),
                        DataColumn(label: Text('No Invoice Supplier')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Total Nominal')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Metode')),
                      ];
                    } else if (isDetail) {
                      return const [
                        DataColumn(label: Text('No Invoice')),
                        DataColumn(label: Text('No Invoice Supplier')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Supplier')),
                        DataColumn(label: Text('Nama Barang')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Harga Satuan')),
                        DataColumn(label: Text('Total Harga')),
                      ];
                    } else if (isPenjualanUmum) {
                      return const [
                        DataColumn(label: Text('No Transaksi')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Total Nominal')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Metode')),
                      ];
                    } else { // Penjualan Detail
                      return const [
                        DataColumn(label: Text('No Transaksi')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Nama Barang')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Harga Satuan')),
                        DataColumn(label: Text('Total Harga')),
                      ];
                    }
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                        columns: getColumns(),
                        rows: _controller.advancedReportData.map((row) {
                          if (isUmum) {
                            return DataRow(cells: [
                              DataCell(Text(row['invoice_number'].toString())),
                              DataCell(Text(row['supplier_invoice_number']?.toString() ?? '-')),
                              DataCell(Text(_formatDateString(row['invoice_date'].toString()))),
                              DataCell(Text(row['supplier_name']?.toString() ?? '-')),
                              DataCell(Text(_currencyFormat.format(row['total_nominal']))),
                              DataCell(Text(row['status'].toString())),
                              DataCell(Text(row['payment_method'].toString())),
                            ]);
                          } else if (isDetail) {
                            return DataRow(cells: [
                              DataCell(Text(row['invoice_number'].toString())),
                              DataCell(Text(row['supplier_invoice_number']?.toString() ?? '-')),
                              DataCell(Text(_formatDateString(row['invoice_date'].toString()))),
                              DataCell(Text(row['supplier_name']?.toString() ?? '-')),
                              DataCell(Text(row['product_name']?.toString() ?? '-')),
                              DataCell(Text(row['qty'].toString())),
                              DataCell(Text(_currencyFormat.format(row['unit_price']))),
                              DataCell(Text(_currencyFormat.format(row['total_price']))),
                            ]);
                          } else if (isPenjualanUmum) {
                            return DataRow(cells: [
                              DataCell(Text(row['invoice_number'].toString())),
                              DataCell(Text(_formatDateString(row['invoice_date'].toString()))),
                              DataCell(Text(_currencyFormat.format(row['total_nominal']))),
                              DataCell(Text(row['status'].toString())),
                              DataCell(Text(row['payment_method'].toString())),
                            ]);
                          } else { // Penjualan Detail
                            return DataRow(cells: [
                              DataCell(Text(row['invoice_number'].toString())),
                              DataCell(Text(_formatDateString(row['invoice_date'].toString()))),
                              DataCell(Text(row['product_name']?.toString() ?? '-')),
                              DataCell(Text(row['qty'].toString())),
                              DataCell(Text(_currencyFormat.format(row['unit_price']))),
                              DataCell(Text(_currencyFormat.format(row['total_price']))),
                            ]);
                          }
                        }).toList(),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
