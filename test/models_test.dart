import 'package:flutter_test/flutter_test.dart';

import 'package:english_core_tap/core/enums.dart';
import 'package:english_core_tap/data/models/app_settings.dart';
import 'package:english_core_tap/data/models/pronunciation_result.dart';

void main() {
  test('AppSettings default is Arabic, RTL-first', () {
    const settings = AppSettings();
    expect(settings.locale, AppLocale.ar);
    expect(settings.themeMode, AppThemeMode.system);
    expect(settings.playbackSpeed, 1.0);
    expect(settings.showArabicPhonetic, isTrue);
  });

  test('AppSettings JSON round-trip', () {
    const settings = AppSettings(
      locale: AppLocale.en,
      themeMode: AppThemeMode.dark,
      playbackSpeed: 1.25,
      showArabicPhonetic: false,
      onboardingSeen: true,
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.locale, AppLocale.en);
    expect(restored.themeMode, AppThemeMode.dark);
    expect(restored.playbackSpeed, 1.25);
    expect(restored.showArabicPhonetic, isFalse);
    expect(restored.onboardingSeen, isTrue);
  });

  test('PronunciationResult JSON round-trip preserves fields', () {
    final result = PronunciationResult(
      englishText: 'How are you?',
      arabicTranslation: 'كيف حالك؟',
      arabicPhonetic: 'هاو آر يو؟',
      accent: 'en-US',
      speed: 1.5,
      createdAt: DateTime(2026, 1, 1),
      nativeAudioUrl: 'https://example.com/a.mp3',
      favorite: true,
    );
    final restored = PronunciationResult.fromJson(result.toJson());
    expect(restored.englishText, result.englishText);
    expect(restored.arabicTranslation, result.arabicTranslation);
    expect(restored.arabicPhonetic, result.arabicPhonetic);
    expect(restored.accent, 'en-US');
    expect(restored.speed, 1.5);
    expect(restored.nativeAudioUrl, result.nativeAudioUrl);
    expect(restored.favorite, isTrue);
  });
}
