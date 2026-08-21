import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../data/models/app_settings.dart';
import '../data/services/settings_repository.dart';
import 'services_provider.dart';

/// Repository provider.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// App settings state (theme, locale, voice, speed, ...).
class SettingsController extends Notifier<AppSettings> {
  late final SettingsRepository _repo;

  @override
  AppSettings build() {
    _repo = ref.read(settingsRepositoryProvider);
    Future.microtask(_load);
    return const AppSettings();
  }

  Future<void> _load() async {
    final loaded = await _repo.load();
    state = loaded;
    // Push restored preferences into the TTS engine so playback uses them
    // from the very first utterance.
    try {
      await ref.read(ttsServiceProvider).applySettings(
            gender: loaded.defaultVoice,
            speed: loaded.playbackSpeed,
          );
    } catch (_) {}
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    await _repo.save(next);
  }

  /// Theme/locale only affect MaterialApp — no router refresh, so the user
  /// stays exactly where they are.
  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> setLocale(AppLocale locale) =>
      _persist(state.copyWith(locale: locale));

  /// Applies the voice to the TTS engine immediately and persists it.
  Future<void> setDefaultVoice(VoiceGender voice) async {
    await _persist(state.copyWith(defaultVoice: voice));
    try {
      await ref.read(ttsServiceProvider).setGender(voice);
    } catch (_) {}
  }

  /// Applies the speed to the TTS engine immediately and persists it.
  Future<void> setPlaybackSpeed(double speed) async {
    await _persist(state.copyWith(playbackSpeed: speed));
    try {
      await ref.read(ttsServiceProvider).setSpeed(speed);
    } catch (_) {}
  }

  Future<void> setShowArabicPhonetic(bool value) =>
      _persist(state.copyWith(showArabicPhonetic: value));

  Future<void> setOnboardingSeen() =>
      _persist(state.copyWith(onboardingSeen: true));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
