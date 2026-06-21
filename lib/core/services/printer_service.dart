import 'dart:io';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:posapp_w6zxit6s/core/services/path_service.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrinterService extends GetxService {
  final Logger _logger = Logger();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy HH:mm');

  Future<pw.Document> generatePdfReceipt({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> details,
  }) async {
    final pdf = pw.Document();

    // 78mm paper width, 0 margins
    final format = PdfPageFormat(
      78 * PdfPageFormat.mm,
      double.infinity,
      marginAll: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(4 * PdfPageFormat.mm),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // Header
                pw.Center(
                  child: pw.Text(
                    'NI',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Toko Kelontong & Grosir',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // Transaction Info
                pw.Text(
                  'No   : ${transaction['transaction_number']}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Tgl  : ${_dateFormat.format(DateTime.parse(transaction['transaction_date']))}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Kasir: ${transaction['kasir_name'] ?? 'Admin'}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // Items
                ...details.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          item['product_name'] ?? 'Barang',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              '${item['qty']} x ${_currencyFormat.format(item['unit_price'])}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              _currencyFormat.format(item['total_price']),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                pw.Divider(borderStyle: pw.BorderStyle.dashed),

                // Totals
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.Text(
                      _currencyFormat.format(transaction['total_nominal']),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),

                if (transaction['payment_method'] == 'Tunai') ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TUNAI:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        _currencyFormat.format(transaction['paid_amount']),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'KEMBALI:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        _currencyFormat.format(
                          (transaction['paid_amount'] as num).toDouble() -
                              (transaction['total_nominal'] as num).toDouble(),
                        ),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ] else ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'METODE:',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        transaction['payment_method'].toString().toUpperCase(),
                        style: transaction['payment_method'] == 'Digital'
                            ? pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              )
                            : const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  if (transaction['payment_method'] == 'Hutang') ...[
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('DP:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          _currencyFormat.format(transaction['paid_amount']),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'SISA HUTANG:',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          _currencyFormat.format(
                            (transaction['total_nominal'] as num).toDouble() -
                                (transaction['paid_amount'] as num).toDouble(),
                          ),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ],

                pw.Divider(borderStyle: pw.BorderStyle.dashed),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Terima Kasih',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  Future<String?> generateAndSavePdf({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final pdf = await generatePdfReceipt(
        transaction: transaction,
        details: details,
      );
      final pdfBytes = await pdf.save();

      String receiptsPath = PathService.receiptsDir;
      String fileName = 'struk_${transaction['transaction_number']}.pdf';
      String filePath = p.join(receiptsPath, fileName);
      File file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      _logger.i("Struk PDF disimpan di: $filePath");

      return filePath;
    } catch (e) {
      _logger.e("Gagal membuat PDF", error: e);
      return null;
    }
  }

  Future<bool> printReceipt({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final pdf = await generatePdfReceipt(
        transaction: transaction,
        details: details,
      );
      final pdfBytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Struk ${transaction['transaction_number']}',
      );

      return true;
    } catch (e) {
      _logger.e("Gagal mencetak PDF", error: e);
      return false;
    }
  }

  Future<void> previewReceiptInOs({
    required Map<String, dynamic> transaction,
    required List<Map<String, dynamic>> details,
  }) async {
    String? filePath = await generateAndSavePdf(
      transaction: transaction,
      details: details,
    );
    if (filePath != null) {
      if (Platform.isWindows) {
        Process.run('cmd', ['/c', 'start', '""', filePath]);
      } else if (Platform.isMacOS) {
        Process.run('open', [filePath]);
      } else if (Platform.isLinux) {
        Process.run('xdg-open', [filePath]);
      }
    }
  }
}
