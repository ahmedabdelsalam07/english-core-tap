import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/history_entry.dart';
import '../data/services/cloud_user_store.dart';
import '../data/services/history_repository.dart';
import '../data/services/user_data_merge.dart';
import 'auth_provider.dart';

/// Cloud snapshot store backing per-account sync (silent when unavailable).
final cloudUserStoreProvider = Provider<CloudUserStore>((ref) {
  return CloudUserStore();
});

/// One repository instance per signed-in account, rebuilt on login/logout.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final uid = ref.watch(authControllerProvider).valueOrNull?.uid;
  return HistoryRepository(uid: (uid == null || uid.isEmpty) ? null : uid);
});

class HistoryController extends Notifier<List<HistoryEntry>> {
  late HistoryRepository _repo;

  @override
  List<HistoryEntry> build() {
    _repo = ref.watch(historyRepositoryProvider);
    Future.microtask(_load);
    return const [];
  }

  Future<void> _load() async {
    // The device copy appears instantly…
    var items = await _repo.load();
    state = items;

    // …then reconcile with the account's cloud copy so history follows the
    // student across devices, reinstalls and app updates.
    final uid = _cloudUid;
    if (uid == null) return;
    await _repo.inheritGuestData();
    state = await _repo.load();
    try {
      final store = ref.read(cloudUserStoreProvider);
      final snapshot = await store.fetch(uid);
      final remoteLines = CloudUserStore.decodeList(snapshot?.historyJson);
      if (remoteLines != null && remoteLines.isNotEmpty) {
        final merged = UserDataMerge.histories(
          state,
          HistoryRepository.decode(remoteLines),
        );
        state = await _repo.replaceAll(merged);
      }
      unawaited(_push());
    } catch (_) {
      // Offline or Firestore not enabled yet: the local copy keeps working.
    }
  }

  Future<void> addEntry(HistoryEntry entry) async {
    state = await _repo.add(entry);
    unawaited(_push());
  }

  Future<void> removeEntry(String englishText) async {
    state = await _repo.remove(englishText);
    unawaited(_push());
  }

  Future<void> clearAll() async {
    await _repo.clear();
    state = const [];
    unawaited(_push());
  }

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
            field: 'history',
            jsonValue:
                CloudUserStore.encodeList(HistoryRepository.encode(state)),
          );
    } catch (_) {}
  }
}

final historyControllerProvider =
    NotifierProvider<HistoryController, List<HistoryEntry>>(
        HistoryController.new);
