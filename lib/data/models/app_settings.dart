import '../../core/enums.dart';

/// Persisted user settings.
class AppSettings {
  final AppThemeMode themeMode;
  final AppLocale locale;
  final VoiceGender defaultVoice;
  final double playbackSpeed;
  final bool showArabicPhonetic;
  final bool onboardingSeen;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.ar,
    this.defaultVoice = VoiceGender.auto,
    this.playbackSpeed = 1.0,
    this.showArabicPhonetic = true,
    this.onboardingSeen = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLocale? locale,
    VoiceGender? defaultVoice,
    double? playbackSpeed,
    bool? showArabicPhonetic,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      defaultVoice: defaultVoice ?? this.defaultVoice,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      showArabicPhonetic: showArabicPhonetic ?? this.showArabicPhonetic,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'locale': locale.name,
        'defaultVoice': defaultVoice.name,
        'playbackSpeed': playbackSpeed,
        'showArabicPhonetic': showArabicPhonetic,
        'onboardingSeen': onboardingSeen,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.asNameMap()[json['themeMode']] ??
            AppThemeMode.system,
        locale:
            AppLocale.values.asNameMap()[json['locale']] ?? AppLocale.ar,
        defaultVoice:
            VoiceGender.values.asNameMap()[json['defaultVoice']] ?? VoiceGender.auto,
        playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
        showArabicPhonetic: json['showArabicPhonetic'] as bool? ?? true,
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
      );
}