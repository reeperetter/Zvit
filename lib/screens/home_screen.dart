import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_strings.dart';
import '../models/inspection_models.dart';
import '../services/storage_service.dart';
import 'dictionaries_screen.dart';
import 'project_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _changeLang(String lang) {
    setState(() {
      AppStrings.currentLang = lang;
    });
  }

  void _showCreateProjectDialog(BuildContext context) {
    final storage = context.read<StorageService>();
    final codeCtrl = TextEditingController(text: '1-12.A.1.1');
    final protoNumCtrl = TextEditingController(text: '#${101 + storage.projects.length}');
    final addressCtrl = TextEditingController();
    final inspectorCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    final devCtrl = TextEditingController();
    final meterCtrl = TextEditingController();
    String selectedType = storage.dictionaries.protocolTypes.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text(AppStrings.t('new_project')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('product_code')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: protoNumCtrl,
                  decoration: const InputDecoration(labelText: 'Nr protokołu (np. #101)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(labelText: AppStrings.t('protocol_type')),
                  items: storage.dictionaries.protocolTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('address')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: inspectorCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('inspector')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: clientCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('client_name')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: devCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t('developer')),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: meterCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Liczniki / Pogoda (opcjonalnie)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppStrings.t('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                final proj = InspectionProject(
                  id: const Uuid().v4(),
                  protocolNumber: protoNumCtrl.text.trim(),
                  productCode: codeCtrl.text.trim(),
                  protocolType: selectedType,
                  address: addressCtrl.text.trim(),
                  inspectorName: inspectorCtrl.text.trim(),
                  clientName: clientCtrl.text.trim(),
                  developerName: devCtrl.text.trim(),
                  weatherAndMeter: meterCtrl.text.trim(),
                  date: DateTime.now(),
                );
                await storage.addOrUpdateProject(proj);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(AppStrings.t('save')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('app_title'), style: const TextStyle(fontSize: 18)),
        actions: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'pl', label: Text('PL')),
              ButtonSegment(value: 'ua', label: Text('UA')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {AppStrings.currentLang},
            onSelectionChanged: (set) => _changeLang(set.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: AppStrings.t('dictionaries'),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DictionariesScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: storage.projects.isEmpty
          ? Center(
              child: Text(
                AppStrings.t('new_project'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: storage.projects.length,
              itemBuilder: (context, index) {
                final proj = storage.projects[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${proj.defects.length}'),
                    ),
                    title: Text(
                      '${proj.productCode} (${proj.protocolNumber})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${proj.protocolType}\n${proj.address} • ${DateFormat('yyyy-MM-dd').format(proj.date)}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => storage.deleteProject(proj.id),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectScreen(projectId: proj.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProjectDialog(context),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.t('new_project')),
      ),
    );
  }
}
