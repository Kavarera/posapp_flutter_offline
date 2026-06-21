import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/theme/app_colors.dart';
import 'package:posapp_w6zxit6s/features/auth/auth_controller.dart';
import 'package:posapp_w6zxit6s/core/services/session_service.dart';
import 'package:posapp_w6zxit6s/features/dashboard/dashboard_controller.dart';
import 'package:posapp_w6zxit6s/features/dashboard/dashboard_page.dart'; // to get parent state if needed
import 'package:posapp_w6zxit6s/features/purchasing_invoice/purchase_invoice_form_page.dart';

class DashboardContent extends StatefulWidget {
  final void Function(int, {bool autoOpenAddDialog}) onNavigate;

  const DashboardContent({super.key, required this.onNavigate});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final DashboardController _controller = Get.put(DashboardController());
  final SessionService _sessionService = Get.find<SessionService>();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    bool isAdmin = _sessionService.role == 'Admin';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard & Control Center',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Obx(() => IconButton(
                icon: Icon(
                  _controller.isNominalHidden.value ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  _controller.isNominalHidden.value = !_controller.isNominalHidden.value;
                },
                tooltip: _controller.isNominalHidden.value ? 'Tampilkan Nominal' : 'Sembunyikan Nominal',
              )),
            ],
          ),
          const SizedBox(height: 24),

          // --- Metrics Cards ---
          Obx(() {
            if (_controller.isLoadingMetrics.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard(
                  "Total Omzet",
                  _controller.totalOmzet.value,
                  Colors.blue,
                ),
                _buildMetricCard(
                  "Total Keuntungan",
                  _controller.totalKeuntungan.value,
                  Colors.green,
                ),
                _buildMetricCard(
                  "Total Pembelian",
                  _controller.totalPembelian.value,
                  Colors.orange,
                ),
                _buildMetricCard(
                  "Hutang Supplier",
                  _controller.totalHutangSupplier.value,
                  Colors.red,
                ),
                _buildMetricCard(
                  "Piutang Konsumen",
                  _controller.totalPiutangKonsumen.value,
                  Colors.purple,
                ),
                _buildMetricCard(
                  "Aset Mengendap",
                  _controller.totalAsetMengendap.value,
                  Colors.teal,
                ),
              ],
            );
          }),

          const SizedBox(height: 32),

          // --- Quick Access ---
          const Text(
            'Akses Cepat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildQuickAction(
                "Tambah Barang",
                Icons.add_box,
                Colors.indigo,
                () => widget.onNavigate(3, autoOpenAddDialog: true),
              ),
              _buildQuickAction(
                "Tambah Invoice",
                Icons.receipt,
                Colors.orange,
                () => Get.to(() => const PurchaseInvoiceFormPage()),
              ),
              if (isAdmin)
                _buildQuickAction(
                  "Buat Akun",
                  Icons.person_add,
                  Colors.blueGrey,
                  () => widget.onNavigate(11, autoOpenAddDialog: true),
                ),
              if (isAdmin)
                _buildQuickAction(
                  "Export Data",
                  Icons.save_alt,
                  Colors.green,
                  () => _controller.exportData(),
                ),
              if (isAdmin)
                _buildQuickAction(
                  "Import Data",
                  Icons.restore,
                  Colors.redAccent,
                  () => _controller.importData(),
                ),
            ],
          ),

          const SizedBox(height: 32),

          // --- Admin Notes ---
          if (isAdmin) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Catatan Admin',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNoteDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Tambah Catatan',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                if (_controller.isLoadingNotes.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (_controller.adminNotes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada catatan.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  itemCount: _controller.adminNotes.length,
                  onReorder: _controller.reorderNotes,
                  buildDefaultDragHandles: true,
                  itemBuilder: (context, index) {
                    final note = _controller.adminNotes[index];
                    return Card(
                      key: ValueKey(note.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.drag_indicator,
                          color: Colors.grey,
                        ),
                        title: Text(
                          note.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(note.content),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: AppColors.accent,
                                size: 20,
                              ),
                              onPressed: () => _showNoteDialog(note: note),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () => _controller.deleteNote(note.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ] else ...[
            const Expanded(child: SizedBox.shrink()),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => Text(
            _controller.isNominalHidden.value ? '••••••••' : _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog({AdminNote? note}) {
    String title = note?.title ?? '';
    String content = note?.content ?? '';

    Get.dialog(
      AlertDialog(
        title: Text(note == null ? 'Tambah Catatan' : 'Edit Catatan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Judul'),
              controller: TextEditingController(text: title),
              onChanged: (val) => title = val,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(labelText: 'Isi Catatan'),
              controller: TextEditingController(text: content),
              onChanged: (val) => content = val,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (note == null) {
                _controller.addNote(title, content);
              } else {
                _controller.updateNote(note.id!, title, content);
              }
              Get.back();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
