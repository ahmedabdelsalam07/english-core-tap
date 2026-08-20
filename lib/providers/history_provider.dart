import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/history_entry.dart';
import '../data/services/history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

class HistoryController extends Notifier<List<HistoryEntry>> {
  late final HistoryRepository _repo;

  @override
  List<HistoryEntry> build() {
    _repo = ref.read(historyRepositoryProvider);
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    state = await _repo.load();
  }

  Future<void> addEntry(HistoryEntry entry) async {
    state = await _repo.add(entry);
  }

  Future<void> removeEntry(String englishText) async {
    state = await _repo.remove(englishText);
  }

  Future<void> clearAll() async {
    await _repo.clear();
    state = const [];
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, List<HistoryEntry>>(HistoryController.new);