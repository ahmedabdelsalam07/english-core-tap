import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/enums.dart';
import '../data/models/app_settings.dart';
import '../data/services/settings_repository.dart';

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
    state = await _repo.load();
  }

  Future<void> _persist(AppSettings next) async {
    state = next;
    await _repo.save(next);
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.copyWith(themeMode: mode));

  Future<void> setLocale(AppLocale locale) =>
      _persist(state.copyWith(locale: locale));

  Future<void> setDefaultVoice(voice) =>
      _persist(state.copyWith(defaultVoice: voice));

  Future<void> setPlaybackSpeed(double speed) =>
      _persist(state.copyWith(playbackSpeed: speed));

  Future<void> setShowArabicPhonetic(bool value) =>
      _persist(state.copyWith(showArabicPhonetic: value));

  Future<void> setOnboardingSeen() =>
      _persist(state.copyWith(onboardingSeen: true));
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);