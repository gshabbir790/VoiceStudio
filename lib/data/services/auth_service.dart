import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Google Sign-In.
///
/// This tells the app *which* Google account the person is using — it
/// does not by itself grant access to their Gemini quota (Google's
/// Generative Language API is authenticated by API key, not by a
/// consumer OAuth session). Pairing sign-in with the person's own key
/// from https://aistudio.google.com/apikey (created while signed into
/// this same account) is what keeps usage on their own account. See
/// the README for the full explanation.
class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (_) {
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
