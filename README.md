# Voice Studio

An AI voice-over studio built on Google's Gemini text-to-speech models —
rebuilt from scratch in **Flutter**, replacing two earlier native-Android
prototypes (`Voxoai-main` / `voxora-ai-studio`).

- **Package:** `com.gshabbir.voicestudio`
- **App name:** Voice Studio

---

## 1. What was wrong with the original projects

`Voxoai-main.zip` and `voxora-ai-studio.zip` turned out to be **the same
app**, packaged twice (identical Kotlin source tree, only the Gradle
wrapper/version files differed). Reviewing that source turned up several
real problems, all addressed in this rewrite:

| # | Issue in the original Kotlin app | Fix in Voice Studio |
|---|---|---|
| 1 | The Gemini API key was baked into the app at build time via `BuildConfig.GEMINI_API_KEY` (`.env` → Gradle "secrets" plugin). **Every person who installed the app spent the developer's own quota/billing.** | No key ships with the app at all. Each person signs in with their own Google account and pastes their own free key from Google AI Studio — see §2. |
| 2 | The "AI Director" feature called a model named `gemini-3.5-flash`, which isn't a real Gemini model — this would fail with a 404 in production. | Removed the speculative AI-director step for v1; the TTS calls only use the real, documented `gemini-2.5-flash-preview-tts` model. |
| 3 | Without a valid key, the app silently generated fake "demo" audio instead of failing clearly. | The app always makes a real request. A missing/invalid key is caught immediately and shown as a clear error, and the key is **verified live** before it's ever saved. |
| 4 | `applicationId` was `com.aistudio.voxora.vxstd`, not matching any deliberate identity. | Fixed to `com.gshabbir.voicestudio`, set once in `android/app/build.gradle`, referenced nowhere else (no risk of it drifting out of sync). |
| 5 | Two duplicate projects, complex multi-panel UI (audio mixer, ducking controls, usage dashboard, sample-project gallery, AI director dialog) — a lot of surface area for a first working release. | One project, one simple flow: write a script → pick language/voice/style → generate → play/share. Advanced features can be layered back in later without a redesign, since the data/service layer is already structured for it. |

## 2. Why "sign in with Google" + a pasted key (not just sign-in)

Google's Gemini API (`generativelanguage.googleapis.com`) is authenticated
by **API key**, not by a consumer OAuth session — there's no supported way
for an app to say "bill this request to whoever is signed in" the way, say,
Google Drive access works. So the honest, actually-working version of "use
each person's own account" is:

1. The person signs in with Google (confirms *which* account they're
   about to use — optional, but recommended).
2. They open [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
   **while signed into that same account** and generate a free key.
3. They paste it into Voice Studio once. It's verified with a live test
   call, then stored in `flutter_secure_storage` (Android Keystore-backed),
   on-device only, excluded from cloud backups (see
   `android/app/src/main/res/xml/backup_rules.xml`).

From that point on, every generation request is billed to *their* Google
Cloud/AI Studio quota, never the developer's.

## 3. Project structure

```
lib/
  core/
    theme/app_theme.dart       # single source of truth for all colors/text styles
    utils/wav_utils.dart       # wraps Gemini's raw PCM audio in a WAV header
  data/
    models/                    # Language, TtsVoice, VoiceProject
    services/
      api_key_service.dart     # secure on-device key storage
      auth_service.dart        # Google Sign-In wrapper
      gemini_service.dart      # REST calls to Gemini's generateContent endpoint
      project_storage_service.dart
  providers/
    session_provider.dart      # signed-in account + API key state
    studio_provider.dart       # script/voice/style state + generation + saved projects
  ui/
    splash/       onboarding/       home/        studio/        settings/
android/            # applicationId com.gshabbir.voicestudio, Kotlin, min SDK 23
.github/workflows/
  ci.yml            # analyze + test + debug build on every push/PR
  release.yml       # tag a version (v1.0.0) → signed APK/AAB → GitHub Release
```

## 4. Building it yourself

```bash
flutter pub get
dart run flutter_launcher_icons     # (already-generated icons are committed; re-run after changing assets/icon/*)
dart run flutter_native_splash:create
flutter run
```

First time opening `android/` in Android Studio: if it asks to regenerate
the Gradle wrapper, let it — the wrapper jar itself is intentionally not
committed to git (see below).

## 5. Releasing via GitHub Actions

Two workflows are included:

- **`ci.yml`** — runs on every push/PR: `flutter analyze`, `flutter test`,
  and a debug build, so a broken commit is caught immediately.
- **`release.yml`** — push a tag (`git tag v1.0.0 && git push --tags`), or
  run it manually from the **Actions** tab. It:
  1. Generates a fresh Gradle wrapper (not committed — always matches the
     Gradle version the workflow requests, so there's no stale-binary
     drift between machines).
  2. Regenerates launcher icons + splash screen from `assets/icon/`.
  3. Builds a split-per-ABI release APK, a universal APK, and an `.aab`
     for the Play Store.
  4. Publishes everything as a GitHub Release.

To get a **signed** release build instead of a debug-signed one, add these
repository secrets (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | your `.jks` keystore, base64-encoded |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | key alias |
| `KEY_PASSWORD` | key password |

Without those secrets, `release.yml` still runs end-to-end and produces a
working (debug-signed) build — nothing clashes or fails for their absence.

## 6. What's intentionally not in v1

To keep the first working release simple, per the "sadha design" brief,
these pieces from the original prototype were left out — the architecture
doesn't block adding them later:

- Background-music mixing / auto-ducking
- The "AI Director" script-analysis feature (its original model ID didn't
  exist — see §1)
- A usage/cost dashboard

## 6. Google Sign-In one-time setup (you need to do this once)

Google Sign-In on Android is tied to your **package name + your
keystore's SHA-1 fingerprint**, registered in a Google Cloud project. This
is a one-time step in the Google Cloud Console, not something that can be
hard-coded into the repo:

1. Get your release keystore's SHA-1:
   `keytool -list -v -keystore your-release-key.jks -alias <alias>`
2. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials),
   create an **OAuth 2.0 Client ID** → Android → package name
   `com.gshabbir.voicestudio` → paste the SHA-1.
3. Do the same for your **debug** keystore's SHA-1 (`~/.android/debug.keystore`,
   password `android`) so sign-in also works in local/debug builds and in
   the CI's debug build.

Until this is done, the "Sign in with Google" button will fail — but the
app still works fully without it, since sign-in is optional (see §2): the
person can skip straight to pasting their Gemini API key.

## 7. Privacy

- No API key or credential ever lives in source code, a bundled asset, or
  build config.
- The Gemini key is stored only in Android's encrypted, per-app keystore
  and is explicitly excluded from Android's auto-backup/device-transfer
  (`backup_rules.xml`, `data_extraction_rules.xml`).
- Generated audio files are stored in the app's private documents
  directory, not shared storage.
