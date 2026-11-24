import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../services/storage_service.dart';

class DictionariesScreen extends StatefulWidget {
  const DictionariesScreen({super.key});

  @override
  State<DictionariesScreen> createState() => _DictionariesScreenState();
}

class _DictionariesScreenState extends State<DictionariesScreen> {
  void _addEntry(List<String> targetList, StorageService storage) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t('add_item')),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppStrings.t('cancel'))),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  targetList.add(ctrl.text.trim());
                });
                await storage.saveDictionaries();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppStrings.t('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab(List<String> list, StorageService storage) {
    return Scaffold(
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) => ListTile(
          title: Text(list[i]),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              setState(() => list.removeAt(i));
              await storage.saveDictionaries();
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addEntry(list, storage),
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final dict = storage.dictionaries;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppStrings.t('dictionaries')),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: AppStrings.t('room')),
              Tab(text: AppStrings.t('contractor')),
              Tab(text: AppStrings.t('category')),
              Tab(text: AppStrings.t('defect_code')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildListTab(dict.rooms, storage),
            _buildListTab(dict.contractors, storage),
            _buildListTab(dict.categories, storage),
            _buildListTab(dict.subCodes, storage),
          ],
        ),
      ),
    );
  }
}
