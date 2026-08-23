import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_entry.dart';
import '../data/models/pronunciation_result.dart';
import '../data/services/cloud_user_store.dart';
import '../data/services/favorites_repository.dart';
import '../data/services/user_data_merge.dart';
import 'auth_provider.dart';
import 'history_provider.dart';

/// One repository instance per signed-in account, rebuilt on login/logout.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final uid = ref.watch(authControllerProvider).valueOrNull?.uid;
  return FavoritesRepository(uid: (uid == null || uid.isEmpty) ? null : uid);
});

class FavoritesController extends Notifier<List<FavoriteEntry>> {
  late FavoritesRepository _repo;

  @override
  List<FavoriteEntry> build() {
    _repo = ref.watch(favoritesRepositoryProvider);
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    // The device copy appears instantly…
    var items = await _repo.load();
    state = items;

    // …then reconcile with the account's cloud copy so favorites follow the
    // student across devices, reinstalls and app updates.
    final uid = _cloudUid;
    if (uid == null) return;
    await _repo.inheritGuestData();
    state = await _repo.load();
    try {
      final store = ref.read(cloudUserStoreProvider);
      final snapshot = await store.fetch(uid);
      final remoteLines = CloudUserStore.decodeList(snapshot?.favoritesJson);
      if (remoteLines != null && remoteLines.isNotEmpty) {
        final merged = UserDataMerge.favorites(
          state,
          FavoritesRepository.decode(remoteLines),
        );
        state = await _repo.replaceAll(merged);
      }
      unawaited(_push());
    } catch (_) {
      // Offline or Firestore not enabled yet: the local copy keeps working.
    }
  }

  Future<void> toggle(PronunciationResult result) async {
    final exists = state.any(
      (e) => e.result.englishText == result.englishText,
    );
    if (exists) {
      await remove(result.englishText);
    } else {
      await add(result);
    }
  }

  Future<void> add(PronunciationResult result) async {
    final entry = FavoriteEntry(
      id: result.englishText,
      result: result.copyWith(favorite: true),
    );
    state = await _repo.add(entry);
    unawaited(_push());
  }

  Future<void> remove(String englishText) async {
    state = await _repo.removeByEnglish(englishText);
    unawaited(_push());
  }

  bool isFavorite(String englishText) =>
      state.any((e) => e.result.englishText == englishText);

  String? get _cloudUid {
    final uid = ref.read(authControllerProvider).valueOrNull?.uid;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  /// Fire-and-forget upload of the current list; failures are silent.
  Future<void> _push() async {
    try {
      final uid = _cloudUid;
      if (uid == null) return;
      await ref.read(cloudUserStoreProvider).saveField(
            uid,
            field: 'favorites',
            jsonValue:
                CloudUserStore.encodeList(FavoritesRepository.encode(state)),
          );
    } catch (_) {}
  }
}

final favoritesControllerProvider = NotifierProvider<FavoritesController,
    List<FavoriteEntry>>(FavoritesController.new);
