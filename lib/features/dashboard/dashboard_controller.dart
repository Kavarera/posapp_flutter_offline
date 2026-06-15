import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:posapp_w6zxit6s/core/database/database_helper.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:posapp_w6zxit6s/core/utils/snackbar_helper.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

class AdminNote {
  int? id;
  String title;
  String content;
  int displayOrder;
  String createdAt;

  AdminNote({
    this.id,
    required this.title,
    required this.content,
    required this.displayOrder,
    required this.createdAt,
  });

  factory AdminNote.fromJson(Map<String, dynamic> json) {
    return AdminNote(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      displayOrder: json['display_order'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'display_order': displayOrder,
      'created_at': createdAt,
    };
  }
}

class DashboardController extends GetxController {
  final Logger _logger = Logger();

  // Metrics
  var totalOmzet = 0.0.obs;
  var totalKeuntungan = 0.0.obs;
  var totalPembelian = 0.0.obs;
  var totalHutangSupplier = 0.0.obs;
  var totalPiutangKonsumen = 0.0.obs;
  var totalAsetMengendap = 0.0.obs;

  var isLoadingMetrics = false.obs;

  // Notes
  var adminNotes = <AdminNote>[].obs;
  var isLoadingNotes = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMetrics();
    fetchNotes();
  }

  Future<void> fetchMetrics() async {
    isLoadingMetrics.value = true;
    try {
      final db = await DatabaseHelper().database;

      // Omzet
      var omzetResult = await db.rawQuery(
        "SELECT SUM(total_nominal) as total FROM sales_transactions WHERE status = 'Lunas'",
      );
      totalOmzet.value =
          (omzetResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Keuntungan
      var untungResult = await db.rawQuery('''
        SELECT SUM((std.unit_price - std.base_unit_price) * std.qty) as total 
        FROM sales_transaction_details std 
        JOIN sales_transactions st ON std.transaction_id = st.id 
        WHERE st.status = 'Lunas'
      ''');
      totalKeuntungan.value =
          (untungResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Pembelian
      var beliResult = await db.rawQuery(
        "SELECT SUM(total_nominal) as total FROM purchase_invoices",
      );
      totalPembelian.value =
          (beliResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Hutang Supplier
      var hutangResult = await db.rawQuery(
        "SELECT SUM(debt_balance) as total FROM suppliers",
      );
      totalHutangSupplier.value =
          (hutangResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Piutang Konsumen
      var piutangResult = await db.rawQuery(
        "SELECT SUM(receivable_balance) as total FROM customers",
      );
      totalPiutangKonsumen.value =
          (piutangResult.first['total'] as num?)?.toDouble() ?? 0.0;

      // Aset Mengendap (Stock * buy_price)
      var asetResult = await db.rawQuery(
        "SELECT SUM(stock * buy_price) as total FROM products",
      );
      totalAsetMengendap.value =
          (asetResult.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      _logger.e("Failed to fetch metrics", error: e);
    } finally {
      isLoadingMetrics.value = false;
    }
  }

  // --- Admin Notes ---

  Future<void> fetchNotes() async {
    isLoadingNotes.value = true;
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query(
        'admin_notes',
        orderBy: 'display_order ASC',
      );
      adminNotes.assignAll(result.map((e) => AdminNote.fromJson(e)).toList());
    } catch (e) {
      _logger.e("Failed to fetch admin notes", error: e);
    } finally {
      isLoadingNotes.value = false;
    }
  }

  Future<void> addNote(String title, String content) async {
    try {
      final db = await DatabaseHelper().database;
      int nextOrder = adminNotes.length;
      final newNote = AdminNote(
        title: title,
        content: content,
        displayOrder: nextOrder,
        createdAt: DateTime.now().toIso8601String(),
      );
      int id = await db.insert('admin_notes', newNote.toJson());
      newNote.id = id;
      adminNotes.add(newNote);
    } catch (e) {
      _logger.e("Failed to add note", error: e);
    }
  }

  Future<void> updateNote(int id, String title, String content) async {
    try {
      final db = await DatabaseHelper().database;
      await db.update(
        'admin_notes',
        {'title': title, 'content': content},
        where: 'id = ?',
        whereArgs: [id],
      );
      int index = adminNotes.indexWhere((n) => n.id == id);
      if (index != -1) {
        adminNotes[index].title = title;
        adminNotes[index].content = content;
        adminNotes.refresh();
      }
    } catch (e) {
      _logger.e("Failed to update note", error: e);
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      final db = await DatabaseHelper().database;
      await db.delete('admin_notes', where: 'id = ?', whereArgs: [id]);
      adminNotes.removeWhere((n) => n.id == id);
      _recalculateNoteOrders();
    } catch (e) {
      _logger.e("Failed to delete note", error: e);
    }
  }

  Future<void> reorderNotes(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final note = adminNotes.removeAt(oldIndex);
    adminNotes.insert(newIndex, note);

    await _recalculateNoteOrders();
  }

  Future<void> _recalculateNoteOrders() async {
    try {
      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        for (int i = 0; i < adminNotes.length; i++) {
          adminNotes[i].displayOrder = i;
          await txn.update(
            'admin_notes',
            {'display_order': i},
            where: 'id = ?',
            whereArgs: [adminNotes[i].id],
          );
        }
      });
      adminNotes.refresh();
    } catch (e) {
      _logger.e("Failed to reorder notes", error: e);
    }
  }

  // --- Export / Import Data ---

  Future<void> exportData() async {
    try {
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Export Data Aplikasi',
        fileName:
            'kavarera_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputFile == null) return; // User canceled

      SnackbarHelper.show('Info', 'Proses ekspor data dimulai...');

      var encoder = ZipFileEncoder();
      encoder.create(outputFile);

      Directory appDir = Directory(PathService.appDataDir);
      if (appDir.existsSync()) {
        List<FileSystemEntity> entities = appDir.listSync();
        for (var entity in entities) {
          // Skip the Exports directory to avoid recursive zipping if saving inside
          if (entity.path.contains('Exports') ||
              entity.path.contains(outputFile)) {
            continue;
          }
          if (entity is File) {
            encoder.addFile(entity);
          } else if (entity is Directory) {
            encoder.addDirectory(entity);
          }
        }
      }

      encoder.close();

      SnackbarHelper.show(
        'Sukses',
        'Data berhasil diekspor ke $outputFile',
        isError: false,
      );
      _logger.i("Data exported to $outputFile");
    } catch (e) {
      _logger.e("Export failed", error: e);
      SnackbarHelper.show('Error', 'Gagal mengekspor data: $e', isError: true);
    }
  }

  Future<void> importData() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Import Data Aplikasi',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) return;

      String zipPath = result.files.single.path!;

      bool confirm =
          await Get.defaultDialog(
            title: "Konfirmasi Import",
            middleText:
                "Peringatan: Seluruh data saat ini akan DITIMPA PERMANEN oleh data dari file zip ini. Aplikasi akan membutuhkan restart setelah proses selesai. Lanjutkan?",
            textConfirm: "Ya, Timpa Data",
            textCancel: "Batal",
            confirmTextColor: const Color(0xFFFFFFFF),
            onConfirm: () => Get.back(result: true),
            onCancel: () => Get.back(result: false),
          ) ??
          false;

      if (!confirm) return;

      SnackbarHelper.show('Info', 'Menyiapkan import data...');

      // Close DB connection
      await DatabaseHelper().close();

      // Read ZIP
      final bytes = File(zipPath).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      Directory appDir = Directory(PathService.appDataDir);

      // Clear existing directory contents EXCEPT Exports
      if (appDir.existsSync()) {
        for (var entity in appDir.listSync()) {
          if (entity.path.contains('Exports')) continue;
          if (entity is File) {
            entity.deleteSync();
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
          }
        }
      }

      // Extract ZIP
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          File outFile = File(p.join(appDir.path, filename));
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        } else {
          Directory(p.join(appDir.path, filename)).createSync(recursive: true);
        }
      }

      _logger.i("Data imported successfully.");

      await Get.defaultDialog(
        title: "Import Berhasil",
        middleText:
            "Data berhasil dikembalikan. Harap muat ulang atau restart aplikasi.",
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );

      // Reload dashboard stats just in case
      fetchMetrics();
      fetchNotes();
    } catch (e) {
      _logger.e("Import failed", error: e);
      SnackbarHelper.show('Error', 'Gagal mengimpor data: $e', isError: true);
    }
  }
}
