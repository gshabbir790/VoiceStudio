import 'package:shared_preferences/shared_preferences.dart';

import '../models/project.dart';

/// Persists saved voice-over projects on-device as a simple JSON list.
/// Kept intentionally lightweight (no native database dependency) so
/// the project stays easy to build and maintain.
class ProjectStorageService {
  static const _prefsKey = 'voice_studio_projects';

  Future<List<VoiceProject>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = VoiceProject.decodeList(raw);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAll(List<VoiceProject> projects) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, VoiceProject.encodeList(projects));
  }

  Future<void> upsert(VoiceProject project) async {
    final all = await loadAll();
    final idx = all.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      all[idx] = project;
    } else {
      all.insert(0, project);
    }
    await saveAll(all);
  }

  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((p) => p.id == id);
    await saveAll(all);
  }
}
