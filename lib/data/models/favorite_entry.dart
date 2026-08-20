import 'pronunciation_result.dart';

/// A saved favorite entry.
class FavoriteEntry {
  final String id;
  final PronunciationResult result;

  const FavoriteEntry({required this.id, required this.result});

  Map<String, dynamic> toJson() => {
        'id': id,
        'result': result.toJson(),
      };

  factory FavoriteEntry.fromJson(Map<String, dynamic> json) => FavoriteEntry(
        id: json['id'] as String? ?? '',
        result: PronunciationResult.fromJson(
          json['result'] as Map<String, dynamic>? ?? const {},
        ),
      );
}