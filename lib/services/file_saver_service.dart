import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileSaverService {
  /// Saves bytes directly to Android /storage/emulated/0/Download (when accessible)
  /// or app external/documents directory fallback, returning the saved file path.
  static Future<String> saveToDeviceDownloads({
    required String fileName,
    required List<int> bytes,
  }) async {
    Directory? targetDir;

    if (Platform.isAndroid) {
      final publicDownloads = Directory('/storage/emulated/0/Download');
      if (await publicDownloads.exists()) {
        targetDir = publicDownloads;
      } else {
        targetDir = await getExternalStorageDirectory();
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }

    targetDir ??= await getApplicationDocumentsDirectory();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final outFile = File('${targetDir.path}/$fileName');
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile.path;
  }
}
