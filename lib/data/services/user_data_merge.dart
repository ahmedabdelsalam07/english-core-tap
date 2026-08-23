import '../../core/constants.dart';
import '../models/favorite_entry.dart';
import '../models/history_entry.dart';

/// Pure merge rules used when combining the device copy of a student's data
/// with their cloud copy: duplicates collapse, the newest entry wins, and
/// both lists stay capped at the same limits used locally.
class UserDataMerge {
  UserDataMerge._();

  /// Merges [local] with [remote]; on identical timestamps local wins.
  static List<HistoryEntry> histories(
    List<HistoryEntry> local,
    List<HistoryEntry> remote,
  ) {
    final byKey = <String, HistoryEntry>{};
    for (final entry in local) {
      final key = _historyKey(entry.englishText);
      if (key != null) byKey[key] = entry;
    }
    for (final entry in remote) {
      final key = _historyKey(entry.englishText);
      if (key == null) continue;
      final current = byKey[key];
      if (current == null || entry.timestamp.isAfter(current.timestamp)) {
        byKey[key] = entry;
      }
    }
    final merged =
        byKey.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (merged.length > Constants.maxHistoryItems) {
      merged.removeRange(Constants.maxHistoryItems, merged.length);
    }
    return merged;
  }

  /// Merges [local] with [remote]; on identical timestamps local wins.
  static List<FavoriteEntry> favorites(
    List<FavoriteEntry> local,
    List<FavoriteEntry> remote,
  ) {
    final byKey = <String, FavoriteEntry>{};
    for (final entry in local) {
      final key = _favoriteKey(entry.result.englishText);
      if (key != null) byKey[key] = entry;
    }
    for (final entry in remote) {
      final key = _favoriteKey(entry.result.englishText);
      if (key == null) continue;
      final current = byKey[key];
      final candidate = entry.result.createdAt;
      if (current == null || candidate.isAfter(current.result.createdAt)) {
        byKey[key] = entry;
      }
    }
    final merged = byKey.values.toList()
      ..sort(
        (a, b) => b.result.createdAt.compareTo(a.result.createdAt),
      );
    if (merged.length > Constants.maxFavoritesItems) {
      merged.removeRange(Constants.maxFavoritesItems, merged.length);
    }
    return merged;
  }

  static String? _historyKey(String englishText) {
    final key = englishText.trim().toLowerCase();
    return key.isEmpty ? null : key;
  }

  static String? _favoriteKey(String englishText) => _historyKey(englishText);
}
