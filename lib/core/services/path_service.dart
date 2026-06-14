import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class PathService extends GetxService {
  final Logger _logger = Logger();

  static late final String appDataDir;
  
  static late final String dbPath;
  static late final String invoicesDir;
  static late final String attachmentsDir;
  static late final String receiptsDir;
  static late final String templatesDir;
  static late final String exportsDir;

  Future<PathService> init() async {
    try {
      // Use AppData/Roaming/... (ApplicationSupportDirectory) for ALL files
      Directory supportDir = await getApplicationSupportDirectory();
      appDataDir = supportDir.path;
      
      dbPath = p.join(appDataDir, 'kavarera_pos.db');
      invoicesDir = p.join(appDataDir, 'Invoices');
      attachmentsDir = p.join(appDataDir, 'Attachments');
      receiptsDir = p.join(appDataDir, 'Receipts');
      templatesDir = p.join(appDataDir, 'Templates');
      exportsDir = p.join(appDataDir, 'Exports');

      // Create all directories recursively if they don't exist
      await Directory(invoicesDir).create(recursive: true);
      await Directory(attachmentsDir).create(recursive: true);
      await Directory(receiptsDir).create(recursive: true);
      await Directory(templatesDir).create(recursive: true);
      await Directory(exportsDir).create(recursive: true);

      _logger.i("PathService initialized. Base path: $appDataDir");
    } catch (e) {
      _logger.e("Failed to initialize PathService", error: e);
    }
    
    return this;
  }
}
