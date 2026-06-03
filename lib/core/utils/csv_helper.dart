import 'dart:io';
import 'package:csv/csv.dart';
import 'package:logger/logger.dart';

class CsvHelper {
  static final Logger _logger = Logger();

  // This function is meant to be run in an Isolate if called via compute
  // But due to sqlite being locked, we will just parse the CSV string in isolate, 
  // and return the list of maps to the main thread to do the DB inserts.
  static Future<List<Map<String, dynamic>>> parseCsvData(String csvString) async {
    try {
      List<List<dynamic>> rowsAsListOfValues = const CsvToListConverter().convert(
        csvString,
        fieldDelimiter: ',',
        eol: '\n',
      );

      if (rowsAsListOfValues.isEmpty) return [];

      // Assuming first row is header
      List<String> headers = rowsAsListOfValues.first.map((e) => e.toString().trim()).toList();
      List<Map<String, dynamic>> parsedData = [];

      for (int i = 1; i < rowsAsListOfValues.length; i++) {
        var row = rowsAsListOfValues[i];
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
      _logger.e("Failed to parse CSV in Isolate", error: e);
      throw Exception("Format CSV tidak valid.");
    }
  }

  static String generateCsvTemplate() {
    List<List<dynamic>> rows = [
      ["name", "barcode", "category_id", "base_unit", "buy_price", "buy_price_ppn", "sell_price", "min_stock", "stock"],
      ["Contoh Barang", "123456789", "", "Pcs", "10000", "11100", "15000", "5", "100"]
    ];
    return const ListToCsvConverter().convert(rows);
  }
}
