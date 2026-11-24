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

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final project = storage.projects.firstWhere((p) => p.id == widget.projectId);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('\${project.productCode} (\${project.protocolNumber})'),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              tooltip: AppStrings.t('export_pdf'),
              onPressed: () => PdfService.generateAndSharePdf(project),
            ),
            IconButton(
              icon: const Icon(Icons.table_chart, color: Colors.green),
              tooltip: AppStrings.t('export_excel'),
              onPressed: () => ExcelService.generateAndShareExcel(project),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(Icons.list_alt), text: '\${AppStrings.t('defects')} (\${project.defects.length})'),
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
                      child: Text('#\${d.number}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    title: Text('\${d.room} • \${d.subCategoryCode}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(
                      '\${d.description}\n\${d.contractor} | \${d.priority} | Фото: \${d.photoPaths.length}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
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
                                final dx = details.localPosition.dx / constraints.maxWidth;
                                final dy = details.localPosition.dy / constraints.maxHeight;
                                _openDefectForm(project, planX: dx, planY: dy);
                              },
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.file(
                                      File(project.floorPlanPath!),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  ...project.defects
                                      .where((d) => d.planX != null && d.planY != null)
                                      .map(
                                        (d) => Positioned(
                                          left: d.planX! * constraints.maxWidth - 14,
                                          top: d.planY! * constraints.maxHeight - 14,
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
                                                '\${d.number}',
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
