/// A prebuilt Gemini TTS voice.
///
/// Names/genders match Google's published Gemini speech-generation
/// voice list (see https://ai.google.dev/gemini-api/docs/speech-generation).
class TtsVoice {
  final String name;
  final String title;
  final String gender;
  final String description;

  const TtsVoice({
    required this.name,
    required this.title,
    required this.gender,
    required this.description,
  });

  static const all = <TtsVoice>[
    TtsVoice(name: 'Puck', title: 'Playful & Vibrant', gender: 'Male', description: 'High-energy, upbeat delivery for social and entertainment content.'),
    TtsVoice(name: 'Charon', title: 'Deep & Authoritative', gender: 'Male', description: 'Cinematic baritone for documentaries and trailers.'),
    TtsVoice(name: 'Kore', title: 'Warm & Natural', gender: 'Female', description: 'Gentle storytelling voice, great for audiobooks.'),
    TtsVoice(name: 'Fenrir', title: 'Bold & Powerful', gender: 'Male', description: 'Assertive voice for motivational and corporate content.'),
    TtsVoice(name: 'Aoede', title: 'Elegant & Smooth', gender: 'Female', description: 'Polished, premium tone for ads and podcasts.'),
    TtsVoice(name: 'Leda', title: 'Clear & Academic', gender: 'Female', description: 'Crisp, instructional voice for lessons and explainers.'),
    TtsVoice(name: 'Orus', title: 'Professional & Steady', gender: 'Male', description: 'Confident corporate and business narration.'),
    TtsVoice(name: 'Zephyr', title: 'Breezy & Casual', gender: 'Female', description: 'Conversational voice for vlogs and social clips.'),
    TtsVoice(name: 'Autonoe', title: 'Gentle & Empathetic', gender: 'Female', description: 'Soothing tone for wellness and calm narration.'),
    TtsVoice(name: 'Enceladus', title: 'Energetic Promoter', gender: 'Male', description: 'Punchy voice for sales and ads.'),
    TtsVoice(name: 'Iapetus', title: 'Documentary Narrator', gender: 'Male', description: 'Measured, evocative narration for nature/science.'),
    TtsVoice(name: 'Umbriel', title: 'Mysterious & Suspenseful', gender: 'Male', description: 'Ideal for thrillers and true-crime style content.'),
    TtsVoice(name: 'Vega', title: 'Crisp Broadcaster', gender: 'Female', description: 'Clean, modern voice for news and corporate briefs.'),
    TtsVoice(name: 'Lyra', title: 'Melodic & Emotional', gender: 'Female', description: 'Tender, expressive voice for heartfelt narration.'),
  ];

  static TtsVoice byName(String name) =>
      all.firstWhere((v) => v.name == name, orElse: () => all.first);
}
