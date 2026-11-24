import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_models.dart';

class ExcelService {
  static Future<void> generateAndShareExcel(InspectionProject project) async {
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
    ];

    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());

    for (final d in project.defects) {
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
      ]);
    }

    final dir = await getTemporaryDirectory();
    final safeCode = project.productCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final file = File('${dir.path}/QReport_Usterki_$safeCode.xlsx');
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'QReport — Zestawienie usterek Excel ${project.productCode}');
    }
  }
}
