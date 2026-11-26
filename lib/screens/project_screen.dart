import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../models/inspection_models.dart';
import '../services/excel_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import 'defect_form_screen.dart';

class ProjectScreen extends StatefulWidget {
  final String projectId;
  const ProjectScreen({super.key, required this.projectId});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  Future<void> _pickFloorPlan(StorageService storage, InspectionProject project) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final savedPath = await storage.saveImageLocally(File(picked.path));
      await storage.addOrUpdateProject(project.copyWith(floorPlanPath: savedPath));
    }
  }

  void _openDefectForm(InspectionProject project, {double? planX, double? planY, DefectItem? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DefectFormScreen(
          project: project,
          planX: planX,
          planY: planY,
          existingDefect: existing,
        ),
      ),
    );
  }

  void _showExportMenu(BuildContext context, InspectionProject project) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download, color: Colors.red),
              title: Text(AppStrings.t('download_pdf')),
              onTap: () async {
                Navigator.pop(ctx);
                final savedPath = await PdfService.downloadPdfToDevice(project);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppStrings.t('saved_to')}: $savedPath')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.red),
              title: Text(AppStrings.t('export_pdf')),
              onTap: () {
                Navigator.pop(ctx);
                PdfService.generateAndSharePdf(project);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: Text(AppStrings.t('download_excel')),
              onTap: () async {
                Navigator.pop(ctx);
                final savedPath = await ExcelService.downloadExcelToDevice(project);
                if (context.mounted && savedPath != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppStrings.t('saved_to')}: $savedPath')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: Text(AppStrings.t('export_excel')),
              onTap: () {
                Navigator.pop(ctx);
                ExcelService.generateAndShareExcel(project);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final project = storage.projects.firstWhere((p) => p.id == widget.projectId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${project.productCode} (${project.protocolNumber})'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_for_offline_outlined),
              tooltip: AppStrings.t('download'),
              onPressed: () async {
                final savedPath = await PdfService.downloadPdfToDevice(project);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppStrings.t('saved_to')}: $savedPath')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: '${AppStrings.t('download')} / ${AppStrings.t('share')}',
              onPressed: () => _showExportMenu(context, project),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.list_alt), text: '${AppStrings.t('defects')} (${project.defects.length})'),
              Tab(icon: const Icon(Icons.map_outlined), text: AppStrings.t('floor_plan')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: project.defects.length,
              itemBuilder: (context, index) {
                final d = project.defects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: d.priority == 'Krytyczny' || d.priority == 'Wysoki'
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                      child: Text('#${d.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      '${d.room} • ${d.subCategoryCode}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${d.description}\n${d.contractor} | ${AppStrings.localizeValue(d.priority)} | ${AppStrings.t('photos_count')}: ${d.photoPaths.length}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: AppStrings.t('delete'),
                      onPressed: () async {
                        final updated = List<DefectItem>.from(project.defects)..removeAt(index);
                        await storage.addOrUpdateProject(project.copyWith(defects: updated));
                      },
                    ),
                    onTap: () => _openDefectForm(project, existing: d),
                  ),
                );
              },
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          AppStrings.t('tap_plan_hint'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _pickFloorPlan(storage, project),
                        icon: const Icon(Icons.upload_file),
                        label: Text(AppStrings.t('upload_plan')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: project.floorPlanPath == null
                      ? Center(child: Text(AppStrings.t('upload_plan')))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              onTapUp: (details) {
                                final dx = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                                final dy = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0);
                                _openDefectForm(project, planX: dx, planY: dy);
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      File(project.floorPlanPath!),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                  ...project.defects
                                      .where((d) => d.planX != null && d.planY != null)
                                      .map(
                                        (d) => Positioned(
                                          left: (d.planX! * constraints.maxWidth) - 14,
                                          top: (d.planY! * constraints.maxHeight) - 14,
                                          child: GestureDetector(
                                            onTap: () => _openDefectForm(project, existing: d),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${d.number}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openDefectForm(project),
          icon: const Icon(Icons.add_a_photo),
          label: Text(AppStrings.t('add_defect')),
        ),
      ),
    );
  }
}
