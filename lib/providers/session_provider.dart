import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/services/api_key_service.dart';
import '../data/services/auth_service.dart';
import '../data/services/gemini_service.dart';

enum SessionStatus { loading, needsSetup, ready }

/// Tracks whether the current person has (a) optionally signed into a
/// Google account and (b) saved their own working Gemini API key.
/// Both live only on this device.
class SessionProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ApiKeyService _apiKeyService = ApiKeyService();
  final GeminiService _geminiService = GeminiService();

  SessionStatus status = SessionStatus.loading;
  GoogleSignInAccount? account;
  String? apiKey;
  bool isVerifying = false;
  String? lastError;

  Future<void> bootstrap() async {
    account = await _auth.signInSilently();
    apiKey = await _apiKeyService.getKey();
    status = (apiKey != null && apiKey!.isNotEmpty) ? SessionStatus.ready : SessionStatus.needsSetup;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    final result = await _auth.signIn();
    account = result;
    notifyListeners();
    return result != null;
  }

  Future<void> skipSignIn() async {
    account = null;
    notifyListeners();
  }

  /// Verifies the key with a live call, then saves it locally. Returns
  /// an error message on failure, or null on success.
  Future<String?> saveApiKey(String rawKey) async {
    final key = rawKey.trim();
    if (key.isEmpty) return 'Please enter your Gemini API key.';

    isVerifying = true;
    lastError = null;
    notifyListeners();

    final valid = await _geminiService.verifyKey(key);

    isVerifying = false;
    if (!valid) {
      lastError = 'This key was rejected by Google. Double-check you copied it correctly from Google AI Studio.';
      notifyListeners();
      return lastError;
    }

    await _apiKeyService.saveKey(key);
    apiKey = key;
    status = SessionStatus.ready;
    notifyListeners();
    return null;
  }

  Future<void> signOutAndClearKey() async {
    await _auth.signOut();
    await _apiKeyService.clearKey();
    account = null;
    apiKey = null;
    status = SessionStatus.needsSetup;
    notifyListeners();
  }

  Future<void> clearKeyOnly() async {
    await _apiKeyService.clearKey();
    apiKey = null;
    status = SessionStatus.needsSetup;
    notifyListeners();
  }
}
