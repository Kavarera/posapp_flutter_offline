import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/purchasing_invoice/price_analysis_controller.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class PriceAnalysisPage extends StatefulWidget {
  const PriceAnalysisPage({super.key});

  @override
  State<PriceAnalysisPage> createState() => _PriceAnalysisPageState();
}

class _PriceAnalysisPageState extends State<PriceAnalysisPage>
    with SingleTickerProviderStateMixin {
  final PriceAnalysisController _controller = Get.put(
    PriceAnalysisController(),
  );
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background.withValues(alpha: 0.3),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis Harga Pembelian',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // TOP: Filter Controls
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Tanggal
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Periode Tanggal',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _controller.startDate.value,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null)
                                            _controller.startDate.value = date;
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          child: Text(
                                            DateFormat('dd MMM yyyy').format(
                                              _controller.startDate.value,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.0,
                                      ),
                                      child: Text(
                                        's/d',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                _controller.endDate.value,
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null)
                                            _controller.endDate.value = date;
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                          ),
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                            ).format(_controller.endDate.value),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Filter Supplier
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Obx(
                                () => Text(
                                  'Filter Supplier (${_controller.selectedSupplierIds.length}/5)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 45,
                                child: Obx(
                                  () => ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _controller.allSuppliers.length,
                                    itemBuilder: (context, index) {
                                      final s = _controller.allSuppliers[index];
                                      final isSelected = _controller
                                          .selectedSupplierIds
                                          .contains(s.id);
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            s.name,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          onSelected: (val) =>
                                              _controller.toggleSupplier(s.id!),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Radio: Barang / Kategori
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Analisis Berdasarkan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Obx(
                                () => Column(
                                  children: [
                                    RadioListTile<String>(
                                      title: const Text('Barang'),
                                      value: 'Barang',
                                      groupValue:
                                          _controller.analysisType.value,
                                      onChanged: (val) =>
                                          _controller.analysisType.value = val!,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppColors.primary,
                                    ),
                                    RadioListTile<String>(
                                      title: const Text('Kategori'),
                                      value: 'Kategori',
                                      groupValue:
                                          _controller.analysisType.value,
                                      onChanged: (val) =>
                                          _controller.analysisType.value = val!,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Dynamic Chip Selection
                        Expanded(
                          flex: 3,
                          child: Obx(() {
                            if (_controller.analysisType.value == 'Barang') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilih Barang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _controller.allProducts.map((p) {
                                      final isSelected = _controller
                                          .selectedProductIds
                                          .contains(p.id);
                                      return ChoiceChip(
                                        label: Text(
                                          p.name,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: AppColors.accent,
                                        onSelected: (_) =>
                                            _controller.toggleProduct(p.id!),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pilih Kategori',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _controller.allCategories.map((
                                      c,
                                    ) {
                                      final isSelected = _controller
                                          .selectedCategoryIds
                                          .contains(c['id']);
                                      return ChoiceChip(
                                        label: Text(
                                          c['name'],
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                        selected: isSelected,
                                        selectedColor: AppColors.accent,
                                        onSelected: (_) =>
                                            _controller.toggleCategory(c['id']),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            }
                          }),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _controller.runAnalysis,
                          icon: const Icon(
                            Icons.analytics,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Jalankan Analisis',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // TABS (Pills UI)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Tren Harga'),
                  Tab(text: 'Perbandingan Harga'),
                  Tab(text: 'Rekomendasi Harga Jual'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // BOTTOM: Tab Views
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (_controller.recommendedPrices.isEmpty &&
                    _controller.lineChartData.isEmpty &&
                    _controller.barChartData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.query_stats,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada data / Silakan jalankan analisis',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTrenHargaTab(),
                    _buildPerbandinganTab(),
                    _buildRekomendasiTab(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrenHargaTab() {
    return _controller.lineChartData.isEmpty
        ? const Center(child: Text('Data tidak cukup untuk Tren Harga'))
        : ListView.separated(
            itemCount: _controller.lineChartData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final productData = _controller.lineChartData[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tren Harga: ${productData['product_name']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: List.generate(
                          (productData['lines'] as List).length,
                          (idx) {
                            final List<Color> colors = [
                              Colors.blue,
                              Colors.red,
                              Colors.green,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                              Colors.indigo,
                            ];
                            final line = productData['lines'][idx];
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colors[idx % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  line['label'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildLineChartDataForProduct(productData['lines']),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildPerbandinganTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Analisis Perbandingan Harga Supplier',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Membandingkan rata-rata harga beli pada barang yang disuplai oleh lebih dari 1 supplier.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _controller.barChartData.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Tidak ada barang terpilih yang memiliki >1 Supplier.',
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _controller.barChartData.length,
                  itemBuilder: (context, index) {
                    final item = _controller.barChartData[index];
                    return _buildBarChartCard(
                      item['product_name'],
                      item['suppliers'],
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildRekomendasiTab() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekomendasi Harga Jual Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berdasarkan harga pembelian terakhir di-markup secara otomatis.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _controller.recommendedPrices.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _controller.recommendedPrices[index];
                  final formatter = NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  );
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withValues(
                        alpha: 0.2,
                      ),
                      child: const Icon(Icons.sell, color: AppColors.primary),
                    ),
                    title: Text(
                      item['product_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Harga Beli Terakhir: ${formatter.format(item['latest_buy_price'])}',
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Rekomendasi Jual',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            formatter.format(item['recommended_price']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(
    String productName,
    List<Map<String, dynamic>> suppliers,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Barang: $productName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: suppliers.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var suppData = entry.value;
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(
                          toY: suppData['avg_price'],
                          color: AppColors.accent,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: suppData['avg_price'] * 1.2, // Visual headroom
                            color: Colors.grey.shade100,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          final f = NumberFormat.compactCurrency(
                            locale: 'id_ID',
                            symbol: 'Rp',
                          );
                          return Text(
                            f.format(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int idx = value.toInt();
                          if (idx >= 0 && idx < suppliers.length) {
                            String name = suppliers[idx]['supplier_name'];
                            if (name.length > 8)
                              name = '${name.substring(0, 8)}.';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartDataForProduct(List<dynamic> linesData) {
    List<LineChartBarData> lines = [];
    List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];

    int colorIdx = 0;
    double minY = double.infinity;
    double maxY = 0;

    for (var series in linesData) {
      List<FlSpot> spots = [];
      for (var pt in series['points']) {
        DateTime d = pt['x'];
        double val = pt['y'];
        if (val < minY) minY = val;
        if (val > maxY) maxY = val;
        spots.add(FlSpot(d.millisecondsSinceEpoch.toDouble(), val));
      }
      spots.sort((a, b) => a.x.compareTo(b.x));

      lines.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: colors[colorIdx % colors.length],
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      );
      colorIdx++;
    }

    if (minY == double.infinity) minY = 0;
    // Add 10% padding
    double padding = (maxY - minY) * 0.1;
    if (padding == 0) padding = 1000; // fallback if all prices equal
    minY -= padding;
    maxY += padding;
    if (minY < 0) minY = 0;

    return LineChartData(
      minY: minY,
      maxY: maxY,
      lineBarsData: lines,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
              final formattedDate = DateFormat('dd MMM').format(date);
              final formattedPrice = NumberFormat.currency(
                locale: 'id_ID',
                symbol: 'Rp',
                decimalDigits: 0,
              ).format(spot.y);
              return LineTooltipItem(
                '$formattedDate\n$formattedPrice',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              final f = NumberFormat.compactCurrency(
                locale: 'id_ID',
                symbol: 'Rp',
              );
              return Text(
                f.format(value),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 86400000 * 5, // Approx 5 days step for labels
            getTitlesWidget: (value, meta) {
              DateTime d = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd MMM').format(d),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.shade200),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
      ),
    );
  }
}
