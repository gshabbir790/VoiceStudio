import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the Gemini API key **the signed-in person provides themselves**.
///
/// Nothing in this app ships with a bundled/hardcoded key. Every request
/// to Gemini is billed against whichever key is saved here, on that
/// person's own device, under their own Google AI Studio account — so
/// usage and cost are always theirs, never the developer's.
class ApiKeyService {
  static const _key = 'gemini_api_key';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getKey() => _storage.read(key: _key);

  Future<void> saveKey(String value) => _storage.write(key: _key, value: value.trim());

  Future<void> clearKey() => _storage.delete(key: _key);

  Future<bool> hasKey() async {
    final k = await getKey();
    return k != null && k.trim().isNotEmpty;
  }
}
