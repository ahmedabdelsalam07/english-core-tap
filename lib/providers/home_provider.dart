import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/history_entry.dart';
import '../data/models/pronunciation_result.dart';
import '../data/models/word_result.dart';
import '../data/services/api_config.dart';
import 'favorites_provider.dart';
import 'history_provider.dart';
import 'services_provider.dart';

enum HomePhase { idle, analyzing, preparing, translating, done }

class HomeState {
  final HomePhase phase;
  final PronunciationResult? result;
  final AppErrorKind? error;
  const HomeState({
    this.phase = HomePhase.idle,
    this.result,
    this.error,
  });

  HomeState copyWith({
    HomePhase? phase,
    PronunciationResult? result,
    AppErrorKind? error,
    bool clearResult = false,
  }) {
    return HomeState(
      phase: phase ?? this.phase,
      result: clearResult ? null : (result ?? this.result),
      error: error ?? this.error,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController(this.ref) : super(const HomeState());

  final Ref ref;

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  Future<void> process(String text, {double speed = 1.0}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(phase: HomePhase.idle, error: AppErrorKind.emptyInput);
      return;
    }
    final isArabic = _arabicRegex.hasMatch(trimmed);

    state = const HomeState(phase: HomePhase.analyzing);
    try {
      // Translation is needed in both directions; start it right away.
      final translationFuture = ref
          .read(translationServiceProvider)
          .translate(trimmed);

      String englishText;
      String arabicText;
      List<WordResult> wordResults;

      if (isArabic) {
        // Arabic → English: translate first, then build the pronunciation
        // flow around the English result so audio/phonetic still work.
        state = const HomeState(phase: HomePhase.translating);
        final translation = await translationFuture;
        englishText = translation.translatedText.trim();
        if (englishText.isEmpty) {
          throw const AppException(AppErrorKind.translation);
        }
        arabicText = trimmed;
        state = const HomeState(phase: HomePhase.analyzing);
        wordResults = await ref.read(dictionaryServiceProvider).transcribe(englishText);
      } else {
        // English → Arabic: analyze words first, translation already running.
        englishText = trimmed;
        arabicText = trimmed;
        wordResults = await ref.read(dictionaryServiceProvider).transcribe(trimmed);
        await translationFuture;
      }

      // Per-word IPA hints keyed by the lower-cased word so alignment never
      // breaks when punctuation/numbers are skipped during transcription.
      final ipaHints = <String, String>{};
      for (final w in wordResults) {
        final key = w.word.toLowerCase().replaceAll(RegExp("[^a-z'-]"), '');
        final ipa = w.ipa?.replaceAll('/', '').trim() ?? '';
        if (key.isNotEmpty && ipa.isNotEmpty) {
          ipaHints[key] = ipa;
        }
      }

      // Prepare pronunciation (fast, sync) while translation runs
      state = const HomeState(phase: HomePhase.preparing);
      final phoneticService = ref.read(arabicPhoneticServiceProvider);
      final phonetic =
          phoneticService.toArabicPhonetic(englishText, ipaHints: ipaHints);

      state = const HomeState(phase: HomePhase.translating);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final translation = await translationFuture;
      final arabicTranslation = isArabic ? arabicText : translation.translatedText;

      final nativeAudioUrl = _firstAudioUrl(wordResults);
      final isFav = ref
          .read(favoritesControllerProvider.notifier)
          .isFavorite(englishText);
      final result = PronunciationResult(
        englishText: englishText,
        arabicTranslation: arabicTranslation,
        arabicPhonetic: phonetic,
        accent: 'en-US',
        speed: speed,
        createdAt: DateTime.now(),
        nativeAudioUrl: nativeAudioUrl,
        favorite: isFav,
      );

      await ref.read(historyControllerProvider.notifier).addEntry(
            HistoryEntry(
              englishText: englishText,
              arabicTranslation: arabicTranslation,
              arabicPhonetic: phonetic,
              timestamp: DateTime.now(),
            ),
          );

      state = HomeState(phase: HomePhase.done, result: result);
    } on AppException catch (e) {
      state = HomeState(phase: HomePhase.idle, error: e.kind);
    } catch (_) {
      state = const HomeState(phase: HomePhase.idle, error: AppErrorKind.unknown);
    }
  }

  String? _firstAudioUrl(List<WordResult> wordResults) {
    for (final r in wordResults) {
      if (r.audioUrl != null && r.audioUrl!.isNotEmpty) return r.audioUrl;
    }
    return null;
  }

  void reset() => state = const HomeState();
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref);
});