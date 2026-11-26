import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/inspection_models.dart';
import 'file_saver_service.dart';

class PdfService {
  static Future<Uint8List> _buildPdfBytes(InspectionProject project) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(project.date);

    pw.MemoryImage? planImage;
    if (project.floorPlanPath != null &&
        File(project.floorPlanPath!).existsSync()) {
      planImage = pw.MemoryImage(File(project.floorPlanPath!).readAsBytesSync());
    }

    final Map<String, List<pw.MemoryImage>> defectPhotos = {};
    for (final d in project.defects) {
      final list = <pw.MemoryImage>[];
      for (final p in d.photoPaths) {
        final f = File(p);
        if (f.existsSync()) {
          list.add(pw.MemoryImage(f.readAsBytesSync()));
        }
      }
      defectPhotos[d.id] = list;
    }

    final pinnedDefects = project.defects
        .where((d) => d.planX != null && d.planY != null)
        .toList();

    const double planBoxWidth = 760;
    const double planBoxHeight = 250;
    const double pinSize = 20;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'QReport | Usterki — ${project.protocolType} ${project.protocolNumber} — produkt ${project.productCode} (${project.defects.length})',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('Data: $dateStr', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Adres: ${project.address} | Deweloper: ${project.developerName} | Nabywca: ${project.clientName} | Inspektor: ${project.inspectorName}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            if (project.weatherAndMeter.isNotEmpty)
              pw.Text(
                'Warunki / Liczniki: ${project.weatherAndMeter}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Podpis Inspektora / Nabywcy: ________________________     Podpis Przedstawiciela Wykonawcy: ________________________',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'Strona ${context.pageNumber} z ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          if (planImage != null) ...[
            pw.Text(
              'Rzut lokalu z lokalizacją usterek (${pinnedDefects.length} punktów):',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Container(
              width: planBoxWidth,
              height: planBoxHeight,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(planImage, fit: pw.BoxFit.fill),
                  ),
                  ...pinnedDefects.map((d) {
                    final clampedX = (d.planX ?? 0).clamp(0.0, 1.0);
                    final clampedY = (d.planY ?? 0).clamp(0.0, 1.0);
                    final left = (clampedX * planBoxWidth) - (pinSize / 2);
                    final top = (clampedY * planBoxHeight) - (pinSize / 2);
                    return pw.Positioned(
                      left: left.clamp(0.0, planBoxWidth - pinSize),
                      top: top.clamp(0.0, planBoxHeight - pinSize),
                      child: pw.Container(
                        width: pinSize,
                        height: pinSize,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.red,
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColors.white, width: 1.5),
                        ),
                        child: pw.Text(
                          '${d.number}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
          ],
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(24),
              1: const pw.FixedColumnWidth(68),
              2: const pw.FixedColumnWidth(75),
              3: const pw.FixedColumnWidth(72),
              4: const pw.FixedColumnWidth(90),
              5: const pw.FlexColumnWidth(2.2),
              6: const pw.FixedColumnWidth(48),
              7: const pw.FixedColumnWidth(58),
              8: const pw.FixedColumnWidth(58),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cellHeader('Nr'),
                  _cellHeader('Pomieszczenie'),
                  _cellHeader('Wykonawca'),
                  _cellHeader('Kategoria'),
                  _cellHeader('Podkategoria / Kod'),
                  _cellHeader('Opis usterki / Pomiary (PN) / Dokumentacja foto'),
                  _cellHeader('Priorytet'),
                  _cellHeader('Status'),
                  _cellHeader('Typ / Data'),
                ],
              ),
              ...project.defects.map((d) {
                final photos = defectPhotos[d.id] ?? [];
                final dDate = DateFormat('yyyy-MM-dd').format(d.createdAt);
                return pw.TableRow(
                  children: [
                    _cellText('${d.number}', bold: true),
                    _cellText(d.room, bold: true),
                    _cellText(d.contractor),
                    _cellText(d.category),
                    _cellText(d.subCategoryCode),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(d.description, style: const pw.TextStyle(fontSize: 8)),
                          if (d.deviationValue.isNotEmpty || d.normReference.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 2),
                              child: pw.Text(
                                'Pomiar/Norma: ${d.deviationValue} ${d.normReference}',
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.red900,
                                ),
                              ),
                            ),
                          if (photos.isNotEmpty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(top: 4),
                              child: pw.Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: photos
                                    .map(
                                      (img) => pw.Container(
                                        width: 85,
                                        height: 65,
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border.all(color: PdfColors.grey300),
                                        ),
                                        child: pw.Image(img, fit: pw.BoxFit.cover),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _cellText(d.priority),
                    _cellText(d.status),
                    _cellText('${d.defectType}\n$dDate'),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static String _fileName(InspectionProject project) {
    final safeCode = project.productCode.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeProto = project.protocolNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    return 'QReport_${safeCode}_$safeProto.pdf';
  }

  static Future<void> generateAndSharePdf(InspectionProject project) async {
    final bytes = await _buildPdfBytes(project);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(project)}');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'QReport — Protokół odbioru ${project.productCode}');
  }

  static Future<String> downloadPdfToDevice(InspectionProject project) async {
    final bytes = await _buildPdfBytes(project);
    return FileSaverService.saveToDeviceDownloads(
      fileName: _fileName(project),
      bytes: bytes,
    );
  }

  static pw.Widget _cellHeader(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _cellText(String text, {bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
}
