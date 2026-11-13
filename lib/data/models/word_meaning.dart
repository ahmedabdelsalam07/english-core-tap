/// One sense group of a word: its part of speech, the definitions under it and
/// the synonyms that belong to that context.
///
/// Mirrors the shape of the free dictionary API (dictionaryapi.dev) that the
/// app already calls, so no extra service, key or payment is involved.
class WordMeaning {
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> synonyms;

  const WordMeaning({
    this.partOfSpeech = '',
    this.definitions = const <String>[],
    this.synonyms = const <String>[],
  });

  bool get isEmpty => definitions.isEmpty && synonyms.isEmpty;

  /// Parses one `meanings[]` entry of the dictionary API response.
  factory WordMeaning.fromJson(Map<String, dynamic> json) {
    final synonyms = <String>[];

    void addSynonym(Object? value) {
      final s = (value ?? '').toString().trim();
      if (s.isEmpty) return;
      if (!synonyms.contains(s)) synonyms.add(s);
    }

    for (final s in json['synonyms'] as List<dynamic>? ?? const []) {
      addSynonym(s);
    }

    final definitions = <String>[];
    final rawDefinitions =
        json['definitions'] as List<dynamic>? ?? const <dynamic>[];
    for (final d in rawDefinitions.whereType<Map<String, dynamic>>()) {
      final text = (d['definition'] ?? '').toString().trim();
      if (text.isNotEmpty && !definitions.contains(text)) {
        definitions.add(text);
      }
      // Related words are frequently listed per definition rather than per
      // meaning, so collect them here too.
      for (final s in d['synonyms'] as List<dynamic>? ?? const []) {
        addSynonym(s);
      }
    }

    return WordMeaning(
      partOfSpeech: (json['partOfSpeech'] ?? '').toString().trim(),
      definitions: definitions.take(4).toList(),
      synonyms: synonyms.take(8).toList(),
    );
  }

  /// Parses the compact shape persisted in favorites/history JSON.
  factory WordMeaning.fromStorage(Map<String, dynamic> json) => WordMeaning(
        partOfSpeech: (json['partOfSpeech'] ?? '').toString(),
        definitions: (json['definitions'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        synonyms: (json['synonyms'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'partOfSpeech': partOfSpeech,
        'definitions': definitions,
        'synonyms': synonyms,
      };
}
