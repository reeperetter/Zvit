import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/inspection_models.dart';

class StorageService extends ChangeNotifier {
  List<InspectionProject> projects = [];
  AppDictionaries dictionaries = AppDictionaries.defaultPolish();

  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final qDir = Directory('${dir.path}/qreport_data');
    if (!await qDir.exists()) {
      await qDir.create(recursive: true);
    }
    return qDir;
  }

  Future<void> init() async {
    final dir = await _appDir;
    final projFile = File('${dir.path}/projects.json');
    if (await projFile.exists()) {
      final raw = await projFile.readAsString();
      final List<dynamic> decoded = jsonDecode(raw);
      projects = decoded.map((e) => InspectionProject.fromJson(e)).toList();
    }

    final dictFile = File('${dir.path}/dictionaries.json');
    if (await dictFile.exists()) {
      final raw = await dictFile.readAsString();
      dictionaries = AppDictionaries.fromJson(jsonDecode(raw));
    } else {
      await saveDictionaries();
    }
    notifyListeners();
  }

  Future<void> saveProjects() async {
    final dir = await _appDir;
    final projFile = File('${dir.path}/projects.json');
    await projFile.writeAsString(
      jsonEncode(projects.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> saveDictionaries() async {
    final dir = await _appDir;
    final dictFile = File('${dir.path}/dictionaries.json');
    await dictFile.writeAsString(jsonEncode(dictionaries.toJson()));
    notifyListeners();
  }

  Future<String> saveImageLocally(File tempFile) async {
    final dir = await _appDir;
    final photosDir = Directory('${dir.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await tempFile.copy('${photosDir.path}/$fileName');
    return saved.path;
  }

  Future<void> addOrUpdateProject(InspectionProject project) async {
    final idx = projects.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      projects[idx] = project;
    } else {
      projects.insert(0, project);
    }
    await saveProjects();
  }

  Future<void> deleteProject(String id) async {
    projects.removeWhere((p) => p.id == id);
    await saveProjects();
  }
}
