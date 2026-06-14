import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';

class PrinterService extends GetxService {
  final Logger _logger = Logger();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  Future<bool> printReceipt({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      // 1. Generate text format
      String receiptText = _generateReceiptText(transaction, details);

      // 2. Save to file
      String receiptsPath = PathService.receiptsDir;

      String fileName = 'struk_${transaction['transaction_number']}.txt';
      String filePath = p.join(receiptsPath, fileName);
      File file = File(filePath);
      await file.writeAsString(receiptText);
      _logger.i("Struk disimpan di: $filePath");

      // 3. Print using Windows PowerShell default printer
      return await _printFile(filePath);
    } catch (e) {
      _logger.e("Gagal memproses cetak struk", error: e);
      return false;
    }
  }

  String _generateReceiptText(
    Map<String, dynamic> transaction,
    List<Map<String, dynamic>> details,
  ) {
    StringBuffer sb = StringBuffer();
    int lineLength = 32; // Standard thermal printer width (58mm)

    String centerText(String text) {
      if (text.length >= lineLength) return text;
      int pad = (lineLength - text.length) ~/ 2;
      return ' ' * pad + text;
    }

    String rightAlign(String left, String right) {
      int space = lineLength - left.length - right.length;
      if (space <= 0) return left + ' ' + right;
      return left + (' ' * space) + right;
    }

    // Header
    sb.writeln(centerText('KAVARERA POS'));
    sb.writeln(centerText('Toko Kelontong & Grosir'));
    sb.writeln('-' * lineLength);

    // Transaction Info
    sb.writeln('No   : ${transaction['transaction_number']}');
    DateTime date = DateTime.parse(transaction['transaction_date']);
    sb.writeln('Tgl  : ${_dateFormat.format(date)}');
    sb.writeln('Kasir: ${transaction['kasir_name'] ?? 'Admin'}');
    sb.writeln('-' * lineLength);

    // Items
    for (var item in details) {
      String itemName = item['product_name'] ?? 'Barang';
      if (itemName.length > lineLength) {
        itemName = itemName.substring(0, lineLength);
      }
      sb.writeln(itemName);

      String qtyPrice =
          '${item['qty']} x ${_currencyFormat.format(item['unit_price'])}';
      String total = _currencyFormat.format(item['total_price']);
      sb.writeln(rightAlign(qtyPrice, total));
    }

    sb.writeln('-' * lineLength);

    // Totals
    sb.writeln(
      rightAlign(
        'TOTAL:',
        _currencyFormat.format(transaction['total_nominal']),
      ),
    );

    if (transaction['payment_method'] == 'Tunai') {
      sb.writeln(
        rightAlign(
          'TUNAI:',
          _currencyFormat.format(transaction['paid_amount']),
        ),
      );
      double kembalian =
          (transaction['paid_amount'] as num).toDouble() -
          (transaction['total_nominal'] as num).toDouble();
      sb.writeln(
        rightAlign(
          'KEMBALI:',
          _currencyFormat.format(kembalian > 0 ? kembalian : 0),
        ),
      );
    } else {
      sb.writeln(rightAlign('METODE:', 'HUTANG'));
      sb.writeln(
        rightAlign('DP:', _currencyFormat.format(transaction['paid_amount'])),
      );
      double sisa =
          (transaction['total_nominal'] as num).toDouble() -
          (transaction['paid_amount'] as num).toDouble();
      sb.writeln(
        rightAlign('SISA HUTANG:', _currencyFormat.format(sisa > 0 ? sisa : 0)),
      );
    }

    sb.writeln('-' * lineLength);
    sb.writeln(centerText('Terima Kasih'));
    sb.writeln(centerText('Barang yang sudah dibeli'));
    sb.writeln(centerText('tidak dapat ditukar/dikembalikan'));
    sb.writeln('\n\n\n'); // Feed lines

    return sb.toString();
  }

  Future<bool> _printFile(String filePath) async {
    if (!Platform.isWindows) {
      _logger.w("Pencetakan fisik saat ini hanya didukung di Windows.");
      return false;
    }

    try {
      // PowerShell script to check for valid physical printer before printing
      String psScript =
          '''
\$printer = Get-WmiObject -Class Win32_Printer -Filter "Default = True"
if (\$null -eq \$printer) { Write-Error "NO_PRINTER"; exit 1 }
if (\$printer.Name -match "PDF|XPS|OneNote|Snagit") { Write-Error "VIRTUAL_PRINTER"; exit 1 }
if (\$printer.WorkOffline -eq \$True) { Write-Error "OFFLINE"; exit 1 }

Get-Content "$filePath" | Out-Printer
''';

      ProcessResult result = await Process.run('powershell', [
        '-Command',
        psScript,
      ]);

      if (result.exitCode != 0) {
        String err = result.stderr.toString();
        if (err.contains("NO_PRINTER")) {
          _logger.e("Tidak ada printer default.");
        } else if (err.contains("VIRTUAL_PRINTER")) {
          _logger.e(
            "Printer default adalah virtual (PDF/XPS). Harap setel printer kasir fisik sebagai default.",
          );
        } else if (err.contains("OFFLINE")) {
          _logger.e("Printer default sedang offline.");
        } else {
          _logger.e("PowerShell Print Error: \$err");
        }
        return false;
      }

      _logger.i("Berhasil mengirim dokumen ke printer fisik.");
      return true;
    } catch (e) {
      _logger.e("Exception saat print", error: e);
      return false;
    }
  }
}
