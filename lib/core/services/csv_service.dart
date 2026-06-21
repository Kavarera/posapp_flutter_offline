import 'dart:io';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CsvService {
  static final Logger _logger = Logger();

  static Future<List<Map<String, dynamic>>> parseCsvData(String csvString) async {
    try {
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(
        csvString,
        fieldDelimiter: ',',
        eol: '\n',
      );

      if (rowsAsListOfValues.isEmpty) return [];

      List<String> headers = rowsAsListOfValues.first.map((e) => e.toString().trim()).toList();
      List<Map<String, dynamic>> parsedData = [];

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
        if (row.isEmpty || row.join('').trim().isEmpty) continue; // Skip empty rows
        
        Map<String, dynamic> rowMap = {};
        for (int j = 0; j < headers.length; j++) {
          if (j < row.length) {
            rowMap[headers[j]] = row[j];
          }
        }
        parsedData.add(rowMap);
      }
      return parsedData;
    } catch (e) {
      _logger.e("Failed to parse CSV", error: e);
      throw Exception("Format CSV tidak valid.");
    }
  }

  static Future<void> saveErrorReport(String moduleName, List<Map<String, dynamic>> errorRows) async {
    if (errorRows.isEmpty) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final errorDirPath = '${docDir.path}\\Kavarera\\Upload Errors';
      final dir = Directory(errorDirPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      String fileName = '${moduleName}_error_$timestamp.csv';
      File file = File('$errorDirPath\\$fileName');

      // Extract headers from first error row
      List<String> headers = errorRows.first.keys.toList();
      if (!headers.contains('error_message')) {
        headers.add('error_message');
      }

      List<List<dynamic>> rows = [headers];
      for (var rowMap in errorRows) {
        List<dynamic> row = [];
        for (var header in headers) {
          row.add(rowMap[header] ?? '');
        }
        rows.add(row);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      await file.writeAsString(csvData);
      _logger.w("Error report saved to: ${file.path}");
    } catch (e) {
      _logger.e("Failed to save error report", error: e);
    }
  }

  static String generateTemplate(String module) {
    List<List<dynamic>> rows = [];
    switch (module) {
      case 'categories':
        rows = [
          ["name", "description"],
          ["Minuman", "Kategori minuman dingin"],
        ];
        break;
      case 'units':
        rows = [
          ["name", "symbol"],
          ["Pieces", "Pcs"],
        ];
        break;
      case 'suppliers':
        rows = [
          ["name", "contact", "phone", "address"],
          ["PT. Supplier A", "Budi", "08123456789", "Jl. Contoh No 1"],
        ];
        break;
      case 'customers':
        rows = [
          ["name", "phone", "address", "max_credit"],
          ["Pelanggan B", "08123456789", "Jl. Contoh No 2", "1000000"],
        ];
        break;
      case 'products':
        rows = [
          ["name", "barcode", "category_id", "unit_id", "buy_price", "sell_price", "min_stock", "stock", "wholesale_qty", "wholesale_price"],
          ["Kopi Hitam", "KPH-001", "1", "1", "3000", "5000", "10", "100", "10", "4500"],
        ];
        break;
      default:
        rows = [["Unknown Module"]];
    }
    return const ListToCsvConverter().convert(rows);
  }
}
