import '../../core/constants.dart';
import '../../core/enums.dart';
import '../models/history_entry.dart';
import '../models/pronunciation_result.dart';
import '../models/word_result.dart';
import 'api_config.dart';
import 'arabic_phonetic_service.dart';
import 'dictionary_service.dart';
import 'history_repository.dart';
import 'translation_service.dart';

/// Orchestrates the full pipeline:
/// validate -> translate -> Arabic phonetic transcription -> result + history.
class PronunciationService {
  final DictionaryService _dictionary;
  final TranslationService _translation;
  final ArabicPhoneticService _phonetic;
  final HistoryRepository _history;

  PronunciationService({
    DictionaryService? dictionary,
    TranslationService? translation,
    ArabicPhoneticService? phonetic,
    HistoryRepository? history,
  })  : _dictionary = dictionary ?? DictionaryService(),
        _translation = translation ?? TranslationService(),
        _phonetic = phonetic ?? const ArabicPhoneticService(),
        _history = history ?? HistoryRepository();

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  Future<PronunciationResult> process(
    String text, {
    VoiceGender voice = VoiceGender.auto,
    double speed = 1.0,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppException(AppErrorKind.emptyInput);
    }
    if (_arabicRegex.hasMatch(trimmed)) {
      throw const AppException(AppErrorKind.arabicInput);
    }

    // 1. Word-level IPA + native audio (best effort)
    final wordResults = await _dictionary.transcribe(trimmed);
    final ipaHints = wordResults
        .map((w) => w.ipa)
        .whereType<String>()
        .map((ipa) => ipa.replaceAll('/', '').trim())
        .toList();

    // 2. Translation
    final translation = await _translation.translate(trimmed);

    // 3. Arabic phonetic transcription from actual pronunciation
    final phonetic = _phonetic.toArabicPhonetic(trimmed, ipaHints: ipaHints);

    // 4. Native audio URL if the first word has one
    final audioUrl = _firstAudioUrl(wordResults);

    final result = PronunciationResult(
      englishText: trimmed,
      arabicTranslation: translation.translatedText,
      arabicPhonetic: phonetic,
      accent: Constants.accentAmerican,
      voice: voice,
      speed: speed,
      createdAt: DateTime.now(),
      nativeAudioUrl: audioUrl,
    );

    // 5. Persist history
    await _history.add(
      HistoryEntry(
        englishText: trimmed,
        arabicTranslation: translation.translatedText,
        arabicPhonetic: phonetic,
        timestamp: DateTime.now(),
      ),
    );

    return result;
  }

  String? _firstAudioUrl(List<WordResult> results) {
    for (final r in results) {
      if (r.audioUrl != null && r.audioUrl!.isNotEmpty) return r.audioUrl;
    }
    return null;
  }
}