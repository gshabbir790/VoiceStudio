VoiceStudio corrected build files

Replace these four files in your VoiceStudio repository:
1. android/settings.gradle
2. android/app/build.gradle
3. .github/workflows/ci.yml
4. .github/workflows/release.yml

Build stack:
- Flutter 3.47.0
- JDK 17
- AGP 8.13.2
- Kotlin 2.3.20
- Gradle 8.13

The CI workflow builds a release APK and uploads it as a GitHub Actions artifact.
The release workflow builds universal/split APKs and an AAB and creates a GitHub Release on tags v*.*.*.
