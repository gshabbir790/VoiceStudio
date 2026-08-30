import 'package:flutter/foundation.dart';

import '../data/models/language.dart';
import '../data/models/project.dart';
import '../data/models/voice.dart';
import '../data/services/gemini_service.dart';
import '../data/services/project_storage_service.dart';

enum GenerationState { idle, generating, success, error }

const speakingStyles = <String>[
  'Narration',
  'Conversational',
  'Commercial / Ad',
  'News Anchor',
  'Documentary',
  'Storytelling',
];

/// Holds the list of saved projects plus the state of the screen the
/// person is actively working in (script, chosen voice/style/language,
/// and the current generation request).
class StudioProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final ProjectStorageService _storage = ProjectStorageService();

  List<VoiceProject> projects = [];
  bool loadingProjects = true;

  AppLanguage language = AppLanguage.english;
  TtsVoice voice = TtsVoice.all.first;
  String style = speakingStyles.first;

  GenerationState generationState = GenerationState.idle;
  String? generationError;
  VoiceProject? lastResult;

  Future<void> loadProjects() async {
    loadingProjects = true;
    notifyListeners();
    projects = await _storage.loadAll();
    loadingProjects = false;
    notifyListeners();
  }

  void setLanguage(AppLanguage l) {
    language = l;
    notifyListeners();
  }

  void setVoice(TtsVoice v) {
    voice = v;
    notifyListeners();
  }

  void setStyle(String s) {
    style = s;
    notifyListeners();
  }

  Future<bool> generate({
    required String apiKey,
    required String script,
    String? existingProjectId,
    String? title,
  }) async {
    if (script.trim().isEmpty) {
      generationError = 'Please write a script first.';
      generationState = GenerationState.error;
      notifyListeners();
      return false;
    }

    generationState = GenerationState.generating;
    generationError = null;
    notifyListeners();

    final direction =
        'Speak in ${language.displayName}. Voice character: ${voice.title}. '
        'Style: $style. Deliver a clear, natural, expressive performance. '
        'Do not read aloud any bracketed notes or formatting.';

    try {
      final result = await _gemini.generateSpeech(
        apiKey: apiKey,
        text: script,
        voiceName: voice.name,
        promptDirection: direction,
      );

      final project = VoiceProject(
        id: existingProjectId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: (title == null || title.trim().isEmpty)
            ? _autoTitle(script)
            : title.trim(),
        script: script,
        languageCode: language.code,
        voiceName: voice.name,
        style: style,
        createdAt: DateTime.now(),
        audioPath: result.audioFile.path,
        durationSeconds: result.durationSeconds,
      );

      await _storage.upsert(project);
      lastResult = project;
      generationState = GenerationState.success;
      await loadProjects();
      return true;
    } on GeminiTtsException catch (e) {
      generationError = e.message;
      generationState = GenerationState.error;
      notifyListeners();
      return false;
    } catch (e) {
      generationError = 'Something went wrong: $e';
      generationState = GenerationState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteProject(String id) async {
    await _storage.delete(id);
    await loadProjects();
  }

  void resetGenerationState() {
    generationState = GenerationState.idle;
    generationError = null;
    notifyListeners();
  }

  String _autoTitle(String script) {
    final clean = script.trim().replaceAll('\n', ' ');
    if (clean.length <= 40) return clean;
    return '${clean.substring(0, 40)}...';
  }
}
