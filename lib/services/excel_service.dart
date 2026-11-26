import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_models.dart';
import 'file_saver_service.dart';

class ExcelService {
  static Uint8List? _buildExcelBytes(InspectionProject project) {
    final excel = Excel.createExcel();
    final sheet = excel['Usterki'];
    excel.delete('Sheet1');

    final headers = [
      'Produkt',
      'Typ protokołu',
      'Wykonawca',
      'Nr',
      'Pomieszczenie',
      'Kategoria',
      'Podkategoria / Kod',
      'Opis usterki',
      'Pomiary / Odchyłka',
      'Norma PN/WT',
      'Priorytet',
      'Status',
      'Autor',
      'Typ usterki',
      'Data',
      'Liczba zdjęć',
      'Punkt na rzucie (X;Y)',
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final d in project.defects) {
      final pinCoords = (d.planX != null && d.planY != null)
          ? '\${d.planX!.toStringAsFixed(2)};\${d.planY!.toStringAsFixed(2)}'
          : '';
      sheet.appendRow([
        TextCellValue(project.productCode),
        TextCellValue(project.protocolType),
        TextCellValue(d.contractor),
        IntCellValue(d.number),
        TextCellValue(d.room),
        TextCellValue(d.category),
        TextCellValue(d.subCategoryCode),
        TextCellValue(d.description),
        TextCellValue(d.deviationValue),
        TextCellValue(d.normReference),
        TextCellValue(d.priority),
        TextCellValue(d.status),
        TextCellValue(project.inspectorName),
        TextCellValue(d.defectType),
        TextCellValue(DateFormat('yyyy-MM-dd').format(d.createdAt)),
        IntCellValue(d.photoPaths.length),
        TextCellValue(pinCoords),
      ]);
    }

    final encoded = excel.encode();
    if (encoded == null) return null;
    return Uint8List.fromList(encoded);
  }

  static String _fileName(InspectionProject project) {
    final safeCode = project.productCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'QReport_Usterki_$safeCode.xlsx';
  }

  static Future<void> generateAndShareExcel(InspectionProject project) async {
    final bytes = _buildExcelBytes(project);
    if (bytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(project)}');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'QReport — Zestawienie usterek Excel ${project.productCode}');
  }

  static Future<String?> downloadExcelToDevice(InspectionProject project) async {
    final bytes = _buildExcelBytes(project);
    if (bytes == null) return null;

    return FileSaverService.saveToDeviceDownloads(
      fileName: _fileName(project),
      bytes: bytes,
    );
  }
}
