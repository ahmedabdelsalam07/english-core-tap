import '../../core/enums.dart';

/// Persisted user settings.
class AppSettings {
  final AppThemeMode themeMode;
  final AppLocale locale;
  final double playbackSpeed;
  final bool showArabicPhonetic;
  final bool onboardingSeen;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.ar,
    this.playbackSpeed = 1.0,
    this.showArabicPhonetic = true,
    this.onboardingSeen = false,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLocale? locale,
    double? playbackSpeed,
    bool? showArabicPhonetic,
    bool? onboardingSeen,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      showArabicPhonetic: showArabicPhonetic ?? this.showArabicPhonetic,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'locale': locale.name,
        'playbackSpeed': playbackSpeed,
        'showArabicPhonetic': showArabicPhonetic,
        'onboardingSeen': onboardingSeen,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: AppThemeMode.values.asNameMap()[json['themeMode']] ??
            AppThemeMode.system,
        locale:
            AppLocale.values.asNameMap()[json['locale']] ?? AppLocale.ar,
        playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
        showArabicPhonetic: json['showArabicPhonetic'] as bool? ?? true,
        onboardingSeen: json['onboardingSeen'] as bool? ?? false,
      );
}