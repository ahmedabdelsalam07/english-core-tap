import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/arabic_phonetic_service.dart';
import '../data/services/audio_player_service.dart';
import '../data/services/backend_client.dart';
import '../data/services/dictionary_service.dart';
import '../data/services/speech_service.dart';
import '../data/services/translation_service.dart';
import '../data/services/tts_service.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.dispose);
  return service;
});

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(service.dispose);
  return service;
});

final dictionaryServiceProvider = Provider<DictionaryService>((ref) {
  final service = DictionaryService();
  ref.onDispose(service.dispose);
  return service;
});

final arabicPhoneticServiceProvider =
    Provider<ArabicPhoneticService>((ref) {
  return const ArabicPhoneticService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.create();
});

/// Firebase Auth is always configured in production builds.
final authConfiguredProvider = Provider<bool>((ref) => true);