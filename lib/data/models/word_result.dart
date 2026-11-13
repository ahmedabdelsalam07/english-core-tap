import 'word_meaning.dart';

class WordResult {
  final String word;
  final String? ipa;
  final String? audioUrl;
  final String? definition;

  /// Every sense group returned by the dictionary API. The first one is the
  /// primary meaning; the rest add the other contexts and their synonyms.
  final List<WordMeaning> meanings;

  const WordResult({
    required this.word,
    this.ipa,
    this.audioUrl,
    this.definition,
    this.meanings = const <WordMeaning>[],
  });

  factory WordResult.fromJson(Map<String, dynamic> json) {
    final word = (json['word'] as String? ?? '').trim();
    final phonetics = (json['phonetics'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    String? ipa;
    String? audioUrl;
    for (final p in phonetics) {
      final text = p['text'] as String?;
      final audio = p['audio'] as String?;
      if (ipa == null &&
          text != null &&
          text.isNotEmpty &&
          (text.contains('/') || text.contains('\\'))) {
        ipa = text.replaceAll('/', '').trim();
      }
      if (audioUrl == null && audio != null && audio.isNotEmpty) {
        audioUrl = audio;
      }
    }

    if (ipa == null) {
      final phonetic = json['phonetic'] as String?;
      if (phonetic != null &&
          phonetic.isNotEmpty &&
          (phonetic.contains('/') || phonetic.contains('\\'))) {
        ipa = phonetic.replaceAll('/', '').trim();
      }
    }

    final rawMeanings = json['meanings'] as List<dynamic>? ?? const [];
    final meanings = rawMeanings
        .whereType<Map<String, dynamic>>()
        .map(WordMeaning.fromJson)
        .where((m) => m.partOfSpeech.isNotEmpty && !m.isEmpty)
        .toList();

    String? definition;
    for (final meaning in rawMeanings.whereType<Map<String, dynamic>>()) {
      final definitions = meaning['definitions'] as List<dynamic>? ?? const [];
      for (final d in definitions.whereType<Map<String, dynamic>>()) {
        final value = d['definition'] as String?;
        if (value != null && value.isNotEmpty) {
          definition = value;
          break;
        }
      }
      if (definition != null) break;
    }

    return WordResult(
      word: word,
      ipa: ipa,
      audioUrl: audioUrl,
      definition: definition,
      meanings: meanings,
    );
  }
}
