/// Unified pronunciation result model.
class PronunciationResult {
  final String englishText;
  final String arabicTranslation;
  final String arabicPhonetic;
  final String accent;
  final double speed;
  final DateTime createdAt;
  final String? nativeAudioUrl;
  bool favorite;

  PronunciationResult({
    required this.englishText,
    required this.arabicTranslation,
    required this.arabicPhonetic,
    required this.accent,
    required this.speed,
    required this.createdAt,
    this.nativeAudioUrl,
    this.favorite = false,
  });

  PronunciationResult copyWith({
    String? englishText,
    String? arabicTranslation,
    String? arabicPhonetic,
    String? accent,
    double? speed,
    DateTime? createdAt,
    String? nativeAudioUrl,
    bool? favorite,
  }) {
    return PronunciationResult(
      englishText: englishText ?? this.englishText,
      arabicTranslation: arabicTranslation ?? this.arabicTranslation,
      arabicPhonetic: arabicPhonetic ?? this.arabicPhonetic,
      accent: accent ?? this.accent,
      speed: speed ?? this.speed,
      createdAt: createdAt ?? this.createdAt,
      nativeAudioUrl: nativeAudioUrl ?? this.nativeAudioUrl,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'englishText': englishText,
        'arabicTranslation': arabicTranslation,
        'arabicPhonetic': arabicPhonetic,
        'accent': accent,
        'speed': speed,
        'createdAt': createdAt.toIso8601String(),
        'favorite': favorite,
        'nativeAudioUrl': nativeAudioUrl,
      };

  factory PronunciationResult.fromJson(Map<String, dynamic> json) {
    return PronunciationResult(
      englishText: json['englishText'] as String? ?? '',
      arabicTranslation: json['arabicTranslation'] as String? ?? '',
      arabicPhonetic: json['arabicPhonetic'] as String? ?? '',
      accent: json['accent'] as String? ?? 'en-US',
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      nativeAudioUrl: json['nativeAudioUrl'] as String?,
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}