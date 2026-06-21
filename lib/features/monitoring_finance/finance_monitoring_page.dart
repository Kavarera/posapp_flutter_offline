import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'finance_monitoring_controller.dart';
import 'payment_dialog.dart';

class FinanceMonitoringPage extends StatelessWidget {
  FinanceMonitoringPage({Key? key}) : super(key: key);

  final FinanceMonitoringController _controller = Get.put(
    FinanceMonitoringController(),
  );
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            'Monitoring Keuangan',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 1,
          bottom: const TabBar(
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: Colors.black,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                child: Center(
                  child: Text(
                    'Hutang (Account Payable)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Tab(
                child: Center(
                  child: Text(
                    'Piutang (Account Receivable)',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(children: [_buildPayableTab(), _buildReceivableTab()]),
      ),
    );
  }

  Widget _buildPayableTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Filter Status: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Obx(
                () => DropdownButton<String>(
                  value: _controller.payableStatusFilter.value,
                  items: const [
                    DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                    DropdownMenuItem(
                      value: 'Belum Lunas',
                      child: Text('Belum Lunas'),
                    ),
                    DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _controller.payableStatusFilter.value = val;
                      _controller.loadPayables();
                    }
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _controller.loadPayables,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value)
              return const Center(child: CircularProgressIndicator());
            if (_controller.payables.isEmpty)
              return const Center(child: Text('Tidak ada data hutang.'));

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _controller.payables.length,
              itemBuilder: (context, index) {
                final item = _controller.payables[index];
                double sisa = item['sisa_tagihan'] as double;
                bool lunas = item['status'] == 'Lunas';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '${item['invoice_number']} - ${item['supplier_name']}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jatuh Tempo: ${item['due_date'] != null ? _dateFormat.format(DateTime.parse(item['due_date'])) : '-'}',
                        ),
                        Text(
                          'Total: ${_currencyFormat.format(item['total_nominal'])} | Dibayar: ${_currencyFormat.format(item['paid_amount'])}',
                        ),
                        Text(
                          'Sisa: ${_currencyFormat.format(sisa)}',
                          style: TextStyle(
                            color: lunas ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: lunas
                        ? const Chip(
                            label: Text('Lunas'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Get.dialog(
                                PaymentDialog(data: item, type: 'payable'),
                              );
                            },
                            child: const Text('Bayar / Cicil'),
                          ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReceivableTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text(
                'Filter Status: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Obx(
                () => DropdownButton<String>(
                  value: _controller.receivableStatusFilter.value,
                  items: const [
                    DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                    DropdownMenuItem(
                      value: 'Belum Lunas',
                      child: Text('Belum Lunas'),
                    ),
                    DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _controller.receivableStatusFilter.value = val;
                      _controller.loadReceivables();
                    }
                  },
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _controller.loadReceivables,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(() {
            if (_controller.isLoading.value)
              return const Center(child: CircularProgressIndicator());
            if (_controller.receivables.isEmpty)
              return const Center(child: Text('Tidak ada data piutang.'));

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _controller.receivables.length,
              itemBuilder: (context, index) {
                final item = _controller.receivables[index];
                double sisa = item['sisa_tagihan'] as double;
                bool lunas = item['status'] == 'Lunas';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      '${item['transaction_number']} - ${item['customer_name'] ?? 'Pelanggan'}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal: ${_dateFormat.format(DateTime.parse(item['transaction_date']))}',
                        ),
                        Text(
                          'Jatuh Tempo: ${item['due_date'] != null ? _dateFormat.format(DateTime.parse(item['due_date'])) : '-'}',
                        ),
                        Text(
                          'Total: ${_currencyFormat.format(item['total_nominal'])} | Dibayar: ${_currencyFormat.format(item['paid_amount'])}',
                        ),
                        Text(
                          'Sisa: ${_currencyFormat.format(sisa)}',
                          style: TextStyle(
                            color: lunas ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: lunas
                        ? const Chip(
                            label: Text('Lunas'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              Get.dialog(
                                PaymentDialog(data: item, type: 'receivable'),
                              );
                            },
                            child: const Text('Terima Pelunasan'),
                          ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
