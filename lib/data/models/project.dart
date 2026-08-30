import 'dart:convert';

/// A saved voice-over project. Stored locally as JSON — see
/// [ProjectStorageService].
class VoiceProject {
  final String id;
  final String title;
  final String script;
  final String languageCode;
  final String voiceName;
  final String style;
  final DateTime createdAt;
  final String? audioPath;
  final double durationSeconds;

  VoiceProject({
    required this.id,
    required this.title,
    required this.script,
    required this.languageCode,
    required this.voiceName,
    required this.style,
    required this.createdAt,
    this.audioPath,
    this.durationSeconds = 0,
  });

  VoiceProject copyWith({
    String? title,
    String? script,
    String? languageCode,
    String? voiceName,
    String? style,
    String? audioPath,
    double? durationSeconds,
  }) {
    return VoiceProject(
      id: id,
      title: title ?? this.title,
      script: script ?? this.script,
      languageCode: languageCode ?? this.languageCode,
      voiceName: voiceName ?? this.voiceName,
      style: style ?? this.style,
      createdAt: createdAt,
      audioPath: audioPath ?? this.audioPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'script': script,
        'languageCode': languageCode,
        'voiceName': voiceName,
        'style': style,
        'createdAt': createdAt.toIso8601String(),
        'audioPath': audioPath,
        'durationSeconds': durationSeconds,
      };

  factory VoiceProject.fromJson(Map<String, dynamic> json) => VoiceProject(
        id: json['id'] as String,
        title: json['title'] as String,
        script: json['script'] as String,
        languageCode: json['languageCode'] as String,
        voiceName: json['voiceName'] as String,
        style: json['style'] as String? ?? 'Narration',
        createdAt: DateTime.parse(json['createdAt'] as String),
        audioPath: json['audioPath'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      );

  static String encodeList(List<VoiceProject> projects) =>
      jsonEncode(projects.map((p) => p.toJson()).toList());

  static List<VoiceProject> decodeList(String source) {
    final list = jsonDecode(source) as List<dynamic>;
    return list
        .map((e) => VoiceProject.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
