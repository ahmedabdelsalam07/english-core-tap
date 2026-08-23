import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../models/favorite_entry.dart';
import 'storage_keys.dart';

/// Repository for favorites.
///
/// Records are namespaced by the signed-in account so every student keeps
/// their own favorites on this device, and everything survives restarts and
/// app updates. The first version of a user's store also adopts anything
/// saved before accounts were namespaced, so nobody loses existing data.
class FavoritesRepository {
  FavoritesRepository({String? uid})
      : _key = StorageKeys.favoritesFor(uid ?? StorageKeys.guestNamespace);

  final String _key;

  Future<List<FavoriteEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    var raw = prefs.getStringList(_key);
    if (raw == null || raw.isEmpty) {
      // First run for this user: adopt data saved before records were
      // namespaced so nobody loses their existing favorites.
      final legacy = prefs.getStringList(StorageKeys.favorites);
      if (legacy != null && legacy.isNotEmpty) {
        await prefs.setStringList(_key, legacy);
        raw = legacy;
      }
    }
    return decode(raw ?? const <String>[]);
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
    await prefs.remove(_key);
  }

  /// Replaces the whole list (used after merging with the cloud copy).
  Future<List<FavoriteEntry>> replaceAll(List<FavoriteEntry> list) async {
    final prefs = await SharedPreferences.getInstance();
    if (list.length > Constants.maxFavoritesItems) {
      list.removeRange(Constants.maxFavoritesItems, list.length);
    }
    await _persist(prefs, list);
    return list;
  }

  /// One-time adoption of favorites saved before sign-in (guest namespace),
  /// so a freshly signed-in account keeps what was saved beforehand.
  Future<void> inheritGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    final mine = prefs.getStringList(_key);
    if (mine != null && mine.isNotEmpty) return;
    final guestKey = StorageKeys.favoritesFor(StorageKeys.guestNamespace);
    final guest = prefs.getStringList(guestKey);
    if (guest == null || guest.isEmpty) return;
    await prefs.setStringList(_key, guest);
    await prefs.remove(guestKey);
  }

  Future<bool> contains(String englishText) async {
    final list = await load();
    return list.any((e) => e.result.englishText == englishText);
  }

  /// Parses stored JSON lines; invalid entries are skipped.
  static List<FavoriteEntry> decode(List<String> raw) => raw
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

  /// Encodes entries back into JSON lines for storage or cloud sync.
  static List<String> encode(List<FavoriteEntry> list) =>
      list.map((e) => jsonEncode(e.toJson())).toList();

  Future<void> _persist(
    SharedPreferences prefs,
    List<FavoriteEntry> list,
  ) async {
    await prefs.setStringList(_key, encode(list));
  }
}
