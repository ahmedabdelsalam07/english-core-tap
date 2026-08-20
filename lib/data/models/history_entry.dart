/// A history entry (a past search).
class HistoryEntry {
  final String englishText;
  final String? arabicTranslation;
  final String? arabicPhonetic;
  final DateTime timestamp;

  const HistoryEntry({
    required this.englishText,
    this.arabicTranslation,
    this.arabicPhonetic,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'englishText': englishText,
        'arabicTranslation': arabicTranslation,
        'arabicPhonetic': arabicPhonetic,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        englishText: json['englishText'] as String? ?? '',
        arabicTranslation: json['arabicTranslation'] as String?,
        arabicPhonetic: json['arabicPhonetic'] as String?,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}