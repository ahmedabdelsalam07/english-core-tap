import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/history_entry.dart';
import '../data/models/pronunciation_result.dart';
import '../data/models/word_meaning.dart';
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
        // flow around the English result so audio still works.
        state = const HomeState(phase: HomePhase.translating);
        final translation = await translationFuture;
        englishText = translation.translatedText.trim();
        if (englishText.isEmpty) {
          throw const AppException(AppErrorKind.translation);
        }
        arabicText = trimmed;
        state = const HomeState(phase: HomePhase.analyzing);
        wordResults =
            await ref.read(dictionaryServiceProvider).transcribe(englishText);
      } else {
        // English → Arabic: analyze words first, translation already running.
        englishText = trimmed;
        arabicText = trimmed;
        wordResults = await ref.read(dictionaryServiceProvider).transcribe(trimmed);
        await translationFuture;
      }

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
        // Arabic phonetic transcription was removed from the product; the
        // Arabic translation above is what we keep.
        arabicPhonetic: '',
        accent: 'en-US',
        speed: speed,
        createdAt: DateTime.now(),
        nativeAudioUrl: nativeAudioUrl,
        meanings: _collectMeanings(wordResults),
        favorite: isFav,
      );

      await ref.read(historyControllerProvider.notifier).addEntry(
            HistoryEntry(
              englishText: englishText,
              arabicTranslation: arabicTranslation,
              arabicPhonetic: '',
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

  /// Merges the per-word dictionary senses into one list grouped by part of
  /// speech, primary sense first, so the result screen can show every context
  /// without repeating the same label twice.
  List<WordMeaning> _collectMeanings(List<WordResult> wordResults) {
    final byPartOfSpeech = <String, WordMeaning>{};
    for (final word in wordResults) {
      for (final meaning in word.meanings) {
        final key = meaning.partOfSpeech;
        final existing = byPartOfSpeech[key];
        if (existing == null) {
          byPartOfSpeech[key] = meaning;
          continue;
        }
        final definitions = <String>[...existing.definitions];
        for (final d in meaning.definitions) {
          if (!definitions.contains(d)) definitions.add(d);
        }
        final synonyms = <String>[...existing.synonyms];
        for (final s in meaning.synonyms) {
          if (!synonyms.contains(s)) synonyms.add(s);
        }
        byPartOfSpeech[key] = WordMeaning(
          partOfSpeech: key,
          definitions: definitions.take(4).toList(),
          synonyms: synonyms.take(8).toList(),
        );
      }
    }
    return byPartOfSpeech.values.take(3).toList();
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
