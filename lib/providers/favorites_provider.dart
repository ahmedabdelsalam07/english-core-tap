import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/favorite_entry.dart';
import '../data/models/pronunciation_result.dart';
import '../data/services/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository();
});

class FavoritesController extends Notifier<List<FavoriteEntry>> {
  late final FavoritesRepository _repo;

  @override
  List<FavoriteEntry> build() {
    _repo = ref.read(favoritesRepositoryProvider);
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    state = await _repo.load();
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
  }

  Future<void> remove(String englishText) async {
    state = await _repo.removeByEnglish(englishText);
  }

  bool isFavorite(String englishText) =>
      state.any((e) => e.result.englishText == englishText);
}

final favoritesControllerProvider = NotifierProvider<FavoritesController,
    List<FavoriteEntry>>(FavoritesController.new);