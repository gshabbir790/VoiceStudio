import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/wav_utils.dart';

class GeminiTtsException implements Exception {
  final String message;
  final bool isInvalidKey;
  final bool isQuotaExceeded;
  GeminiTtsException(this.message, {this.isInvalidKey = false, this.isQuotaExceeded = false});
  @override
  String toString() => message;
}

class GeminiTtsResult {
  final File audioFile;
  final double durationSeconds;
  GeminiTtsResult(this.audioFile, this.durationSeconds);
}

/// Calls Google's Gemini speech-generation endpoint directly with the
/// key stored on-device for the signed-in person (see [ApiKeyService]).
/// No key ever lives in source code, build config, or a bundled asset.
class GeminiService {
  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const defaultModel = 'gemini-2.5-flash-preview-tts';

  /// Quick round-trip that verifies a key actually works before we
  /// save it, so people get an immediate, clear error instead of a
  /// silent failure later during generation.
  Future<bool> verifyKey(String apiKey) async {
    final uri = Uri.parse('$_baseUrl/gemini-2.5-flash-preview-tts:generateContent?key=$apiKey');
    try {
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Hello'}
              ]
            }
          ],
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {'voiceName': 'Kore'}
              }
            }
          }
        }),
      ).timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) return true;
      if (res.statusCode == 400 || res.statusCode == 403) return false;
      // Other errors (429, 5xx) don't necessarily mean the key is bad.
      return res.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  Future<GeminiTtsResult> generateSpeech({
    required String apiKey,
    required String text,
    required String voiceName,
    required String promptDirection,
    String model = defaultModel,
  }) async {
    final uri = Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey');

    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': text}
                  ]
                }
              ],
              'systemInstruction': {
                'parts': [
                  {'text': promptDirection}
                ]
              },
              'generationConfig': {
                'responseModalities': ['AUDIO'],
                'speechConfig': {
                  'voiceConfig': {
                    'prebuiltVoiceConfig': {'voiceName': voiceName}
                  }
                },
                'temperature': 0.7,
              },
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on SocketException {
      throw GeminiTtsException('No internet connection. Please check your network and try again.');
    } catch (e) {
      throw GeminiTtsException('Network error: $e');
    }

    final Map<String, dynamic> body = _safeDecode(res.body);

    if (res.statusCode != 200) {
      final err = body['error'] as Map<String, dynamic>?;
      final msg = err?['message']?.toString() ?? 'Request failed (HTTP ${res.statusCode}).';
      final isKeyError = res.statusCode == 400 || res.statusCode == 403;
      final isQuota = res.statusCode == 429;
      throw GeminiTtsException(
        isKeyError
            ? 'Your Gemini API key was rejected: $msg'
            : isQuota
                ? 'Your Gemini account has hit its quota/rate limit. Please check your billing at Google AI Studio.'
                : msg,
        isInvalidKey: isKeyError,
        isQuotaExceeded: isQuota,
      );
    }

    final candidates = body['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw GeminiTtsException('Gemini returned no audio. Try adjusting the script and try again.');
    }
    final parts = (candidates.first['content']?['parts'] as List<dynamic>?) ?? [];
    Map<String, dynamic>? audioPart;
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['inlineData'] != null) {
        audioPart = p['inlineData'] as Map<String, dynamic>;
        break;
      }
    }
    if (audioPart == null) {
      throw GeminiTtsException('No audio data returned by Gemini.');
    }

    final base64Data = audioPart['data'] as String;
    final pcmBytes = base64Decode(base64Data);
    final wavBytes = WavUtils.pcm16ToWav(Uint8List.fromList(pcmBytes));

    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/voice_studio_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.wav';
    final file = File('${audioDir.path}/$fileName');
    await file.writeAsBytes(wavBytes);

    // 16-bit mono PCM @ 24kHz -> 48000 bytes/second.
    final durationSeconds = pcmBytes.length / 48000.0;

    return GeminiTtsResult(file, durationSeconds);
  }

  Map<String, dynamic> _safeDecode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }
}
