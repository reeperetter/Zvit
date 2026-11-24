import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../l10n/app_strings.dart';
import '../models/inspection_models.dart';
import '../services/storage_service.dart';
import '../services/voice_service.dart';

class DefectFormScreen extends StatefulWidget {
  final InspectionProject project;
  final double? planX;
  final double? planY;
  final DefectItem? existingDefect;

  const DefectFormScreen({
    super.key,
    required this.project,
    this.planX,
    this.planY,
    this.existingDefect,
  });

  @override
  State<DefectFormScreen> createState() => _DefectFormScreenState();
}

class _DefectFormScreenState extends State<DefectFormScreen> {
  final VoiceService _voiceService = VoiceService();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _devCtrl = TextEditingController();
  final TextEditingController _normCtrl = TextEditingController();

  late String _room;
  late String _category;
  late String _subCode;
  late String _contractor;
  String _priority = 'Normalny';
  String _status = 'W trakcie realizacji';
  String _defectType = 'Budowlana';
  List<String> _photos = [];
  bool _isListening = false;
  String _voiceLocale = 'pl_PL';

  @override
  void initState() {
    super.initState();
    final dict = context.read<StorageService>().dictionaries;
    final ex = widget.existingDefect;

    _room = ex?.room ?? dict.rooms.first;
    _category = ex?.category ?? dict.categories.first;
    _subCode = ex?.subCategoryCode ?? dict.subCodes.first;
    _contractor = ex?.contractor ?? dict.contractors.first;
    _priority = ex?.priority ?? 'Normalny';
    _status = ex?.status ?? 'W trakcie realizacji';
    _defectType = ex?.defectType ?? 'Budowlana';
    _descCtrl.text = ex?.description ?? '';
    _devCtrl.text = ex?.deviationValue ?? '';
    _normCtrl.text = ex?.normReference ?? '';
    _photos = List<String>.from(ex?.photoPaths ?? []);
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      final saved = await context.read<StorageService>().saveImageLocally(File(picked.path));
      setState(() {
        _photos.add(saved);
      });
    }
  }

  Future<void> _toggleVoice() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      final baseText = _descCtrl.text.isEmpty ? '' : '${_descCtrl.text} ';
      await _voiceService.startListening(
        localeId: _voiceLocale,
        onResult: (words) {
          setState(() {
            _descCtrl.text = '$baseText$words';
          });
        },
      );
    }
  }

  Future<void> _save() async {
    final storage = context.read<StorageService>();
    final ex = widget.existingDefect;

    final nextNum = ex?.number ??
        (widget.project.defects.isEmpty
            ? 1
            : widget.project.defects.map((e) => e.number).reduce((a, b) => a > b ? a : b) + 1);

    final item = DefectItem(
      id: ex?.id ?? const Uuid().v4(),
      number: nextNum,
      room: _room,
      category: _category,
      subCategoryCode: _subCode,
      contractor: _contractor,
      description: _descCtrl.text.trim(),
      priority: _priority,
      status: _status,
      defectType: _defectType,
      deviationValue: _devCtrl.text.trim(),
      normReference: _normCtrl.text.trim(),
      photoPaths: _photos,
      planX: ex?.planX ?? widget.planX,
      planY: ex?.planY ?? widget.planY,
      createdAt: ex?.createdAt ?? DateTime.now(),
    );

    final updatedList = List<DefectItem>.from(widget.project.defects);
    if (ex != null) {
      final idx = updatedList.indexWhere((e) => e.id == ex.id);
      if (idx >= 0) updatedList[idx] = item;
    } else {
      updatedList.add(item);
    }

    await storage.addOrUpdateProject(widget.project.copyWith(defects: updatedList));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dict = context.watch<StorageService>().dictionaries;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('add_defect')),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(AppStrings.t('take_photo')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _addPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(AppStrings.t('from_gallery')),
                  ),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 95,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  itemBuilder: (ctx, i) => Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(_photos[i]), width: 95, height: 95, fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => setState(() => _photos.removeAt(i)),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _isListening ? Colors.red.shade100 : null,
                    ),
                    onPressed: _toggleVoice,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : null),
                    label: Text(_isListening ? AppStrings.t('voice_listening') : AppStrings.t('voice_start')),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _voiceLocale,
                  items: const [
                    DropdownMenuItem(value: 'pl_PL', child: Text('Głos: PL')),
                    DropdownMenuItem(value: 'uk_UA', child: Text('Голос: UA')),
                  ],
                  onChanged: (v) => setState(() => _voiceLocale = v!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: AppStrings.t('description')),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: dict.rooms.contains(_room) ? _room : dict.rooms.first,
              decoration: InputDecoration(labelText: AppStrings.t('room')),
              items: dict.rooms.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _room = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: dict.categories.contains(_category) ? _category : dict.categories.first,
              decoration: InputDecoration(labelText: AppStrings.t('category')),
              items: dict.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: dict.subCodes.contains(_subCode) ? _subCode : dict.subCodes.first,
              decoration: InputDecoration(labelText: AppStrings.t('defect_code')),
              items: dict.subCodes.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) => setState(() => _subCode = v!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: dict.contractors.contains(_contractor) ? _contractor : dict.contractors.first,
              decoration: InputDecoration(labelText: AppStrings.t('contractor')),
              items: dict.contractors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _contractor = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _devCtrl,
                    decoration: InputDecoration(labelText: AppStrings.t('deviation')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _normCtrl,
                    decoration: const InputDecoration(labelText: 'Norma (np. PN-B-10110)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: InputDecoration(labelText: AppStrings.t('priority')),
                    items: ['Niski', 'Normalny', 'Wysoki', 'Krytyczny']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: InputDecoration(labelText: AppStrings.t('status')),
                    items: ['Nowa', 'W trakcie realizacji', 'Do odbioru', 'Usunięta']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(AppStrings.t('save'), style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
