import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../models/history_entry.dart';
import 'storage_keys.dart';

/// Repository for search history.
///
/// Records are namespaced by the signed-in account so every student keeps
/// their own history on this device, and everything survives restarts and
/// app updates. The first version of a user's store also adopts anything
/// saved before accounts were namespaced, so nobody loses existing data.
class HistoryRepository {
  HistoryRepository({String? uid})
      : _key = StorageKeys.historyFor(uid ?? StorageKeys.guestNamespace);

  final String _key;

  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      // First run for this user: adopt data saved before records were
      // namespaced so nobody loses their existing history.
      final legacy = prefs.getStringList(StorageKeys.history);
      if (legacy != null && legacy.isNotEmpty) {
        await prefs.setStringList(_key, legacy);
        raw = legacy;
      }
    }
    return decode(raw ?? const <String>[]);
  }

  Future<List<HistoryEntry>> add(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere(
      (e) => e.englishText.toLowerCase() == entry.englishText.toLowerCase(),
    );
    list.insert(0, entry);
    if (list.length > Constants.maxHistoryItems) {
      list.removeRange(Constants.maxHistoryItems, list.length);
    }
    await _persist(prefs, list);
    return list;
  }

  Future<List<HistoryEntry>> remove(String englishText) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere((e) => e.englishText == englishText);
    await _persist(prefs, list);
    return list;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Replaces the whole list (used after merging with the cloud copy).
  Future<List<HistoryEntry>> replaceAll(List<HistoryEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    if (list.length > Constants.maxHistoryItems) {
      list.removeRange(Constants.maxHistoryItems, list.length);
    }
    await _persist(prefs, list);
    return list;
  }

  /// One-time adoption of searches saved before sign-in (guest namespace),
  /// so a freshly signed-in account keeps what was looked up beforehand.
  Future<void> inheritGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    final mine = prefs.getStringList(_key);
    if (mine != null && mine.isNotEmpty) return;
    final guestKey = StorageKeys.historyFor(StorageKeys.guestNamespace);
    final guest = prefs.getStringList(guestKey);
    if (guest == null || guest.isEmpty) return;
    await prefs.setStringList(_key, guest);
    await prefs.remove(guestKey);
  }

  /// Parses stored JSON lines; invalid entries are skipped.
  static List<HistoryEntry> decode(List<String> raw) => raw
      .map((item) {
        try {
          return HistoryEntry.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          );
        } catch (_) {
          return null;
        }
      })
      .whereType<HistoryEntry>()
      .toList();

  /// Encodes entries back into JSON lines for storage or cloud sync.
  static List<String> encode(List<HistoryEntry> list) =>
      list.map((e) => jsonEncode(e.toJson())).toList();

  Future<void> _persist(
    SharedPreferences prefs,
    List<HistoryEntry> list,
  ) async {
    await prefs.setStringList(_key, encode(list));
  }
}
