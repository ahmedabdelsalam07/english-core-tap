import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../models/favorite_entry.dart';
import 'storage_keys.dart';

/// Repository for favorites (persisted JSON via SharedPreferences).
class FavoritesRepository {
  Future<List<FavoriteEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(StorageKeys.favorites) ?? <String>[];
    return raw
        .map((item) {
          try {
            return FavoriteEntry.fromJson(
              jsonDecode(item) as Map<String, dynamic>,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteEntry>()
        .toList();
  }

  Future<List<FavoriteEntry>> add(FavoriteEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere((e) => e.result.englishText == entry.result.englishText);
    list.insert(0, entry);
    if (list.length > Constants.maxFavoritesItems) {
      list.removeRange(Constants.maxFavoritesItems, list.length);
    }
    await _persist(prefs, list);
    return list;
  }

  Future<List<FavoriteEntry>> removeByEnglish(String englishText) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await load();
    list.removeWhere((e) => e.result.englishText == englishText);
    await _persist(prefs, list);
    return list;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.favorites);
  }

  Future<bool> contains(String englishText) async {
    final list = await load();
    return list.any((e) => e.result.englishText == englishText);
  }

  Future<void> _persist(
    SharedPreferences prefs,
    List<FavoriteEntry> list,
  ) async {
    await prefs.setStringList(
      StorageKeys.favorites,
      list.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}