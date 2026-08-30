class AppLanguage {
  final String code;
  final String displayName;
  final String nativeName;
  final bool isRtl;
  final String placeholder;

  const AppLanguage({
    required this.code,
    required this.displayName,
    required this.nativeName,
    required this.isRtl,
    required this.placeholder,
  });

  static const urdu = AppLanguage(
    code: 'ur',
    displayName: 'Urdu',
    nativeName: 'اردو',
    isRtl: true,
    placeholder: 'یہاں اپنا اسکرپٹ لکھیں... Voice Studio اسے ایک زندہ آواز میں بدل دے گا۔',
  );

  static const english = AppLanguage(
    code: 'en',
    displayName: 'English',
    nativeName: 'English',
    isRtl: false,
    placeholder: 'Type or paste your script here... Voice Studio will turn it into a natural voice-over.',
  );

  static const arabic = AppLanguage(
    code: 'ar',
    displayName: 'Arabic',
    nativeName: 'العربية',
    isRtl: true,
    placeholder: 'أدخل النص هنا...',
  );

  static const hindi = AppLanguage(
    code: 'hi',
    displayName: 'Hindi',
    nativeName: 'हिन्दी',
    isRtl: false,
    placeholder: 'अपनी स्क्रिप्ट यहाँ लिखें...',
  );

  static const all = <AppLanguage>[urdu, english, arabic, hindi];

  static AppLanguage fromCode(String code) =>
      all.firstWhere((l) => l.code == code, orElse: () => english);
}
