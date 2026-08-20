import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../models/history_entry.dart';
import 'storage_keys.dart';

/// Repository for search history.
class HistoryRepository {
  Future<List<HistoryEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(StorageKeys.history) ?? <String>[];
    return raw
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
    await prefs.remove(StorageKeys.history);
  }

  Future<void> _persist(SharedPreferences prefs, List<HistoryEntry> list) async {
    await prefs.setStringList(
      StorageKeys.history,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}