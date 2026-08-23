import 'dart:convert';

import 'package:english_core_tap/core/constants.dart';
import 'package:english_core_tap/data/models/favorite_entry.dart';
import 'package:english_core_tap/data/models/history_entry.dart';
import 'package:english_core_tap/data/models/pronunciation_result.dart';
import 'package:english_core_tap/data/services/cloud_user_store.dart';
import 'package:english_core_tap/data/services/favorites_repository.dart';
import 'package:english_core_tap/data/services/history_repository.dart';
import 'package:english_core_tap/data/services/storage_keys.dart';
import 'package:english_core_tap/data/services/user_data_merge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

HistoryEntry _history(String text, DateTime at) => HistoryEntry(
      englishText: text,
      arabicTranslation: 'ترجمة',
      timestamp: at,
    );

PronunciationResult _result(String text, DateTime createdAt) =>
    PronunciationResult(
      englishText: text,
      arabicTranslation: 'ترجمة',
      arabicPhonetic: 'فونيتك',
      accent: 'en-US',
      speed: 1.0,
      createdAt: createdAt,
    );

FavoriteEntry _favorite(String text, DateTime createdAt) => FavoriteEntry(
      id: text,
      result: _result(text, createdAt),
    );

void main() {
  group('UserDataMerge.histories', () {
    test('unions disjoint sets newest first', () {
      final local = [_history('cat', DateTime(2026, 1, 1))];
      final remote = [
        _history('dog', DateTime(2026, 2, 1)),
        _history('bird', DateTime(2026, 3, 1)),
      ];
      final merged = UserDataMerge.histories(local, remote);
      expect(merged.map((e) => e.englishText).toList(),
          ['bird', 'dog', 'cat']);
    });

    test('remote wins only when strictly newer', () {
      final local = [_history('cat', DateTime(2026, 5, 1))];
      final remote = [_history('cat', DateTime(2026, 4, 1))];
      expect(UserDataMerge.histories(local, remote).first.timestamp,
          DateTime(2026, 5, 1));

      final newerRemote = [_history('cat', DateTime(2026, 6, 1))];
      expect(UserDataMerge.histories(local, newerRemote).first.timestamp,
          DateTime(2026, 6, 1));
    });

    test('identical timestamps keep the local copy', () {
      final at = DateTime(2026, 5, 1);
      final local = [
        HistoryEntry(
          englishText: 'cat',
          arabicTranslation: 'محلي',
          timestamp: at,
        ),
      ];
      final remote = [
        HistoryEntry(
          englishText: 'cat',
          arabicTranslation: 'سحابي',
          timestamp: at,
        ),
      ];
      expect(UserDataMerge.histories(local, remote).first.arabicTranslation,
          'محلي');
    });

    test('matching is case-insensitive and trimmed', () {
      final local = [_history('Cat ', DateTime(2026, 1, 1))];
      final remote = [_history(' cat', DateTime(2026, 2, 1))];
      final merged = UserDataMerge.histories(local, remote);
      expect(merged.length, 1);
    });

    test('caps the merged list', () {
      final base = DateTime(2026, 1, 1);
      final local = List.generate(Constants.maxHistoryItems + 20,
          (i) => _history('w$i', base.add(Duration(minutes: i))));
      final merged = UserDataMerge.histories(local, const []);
      expect(merged.length, Constants.maxHistoryItems);
      expect(merged.first.englishText,
          'w${Constants.maxHistoryItems + 19}');
    });
  });

  group('UserDataMerge.favorites', () {
    test('merges by text keeping the newest save', () {
      final local = [_favorite('apple', DateTime(2026, 5, 1))];
      final remote = [
        _favorite('apple', DateTime(2026, 4, 1)),
        _favorite('kiwi', DateTime(2026, 6, 1)),
      ];
      final merged = UserDataMerge.favorites(local, remote);
      expect(merged.map((e) => e.result.englishText).toList(), ['kiwi', 'apple']);
    });

    test('caps the merged list', () {
      final base = DateTime(2026, 1, 1);
      final local = List.generate(Constants.maxFavoritesItems + 5,
          (i) => _favorite('f$i', base.add(Duration(minutes: i))));
      final merged = UserDataMerge.favorites(local, const []);
      expect(merged.length, Constants.maxFavoritesItems);
    });
  });

  group('CloudUserStore', () {
    test('fetch parses stored fields', () async {
      final store = CloudUserStore(
        tokenProvider: () async => 'tok',
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/documents/users/u1'));
          return http.Response(
            jsonEncode({
              'fields': {
                'history': {'stringValue': '["line1"]'},
                'favorites': {'stringValue': '[]'},
              },
            }),
            200,
          );
        }),
      );
      final snapshot = await store.fetch('u1');
      expect(snapshot?.historyJson, '["line1"]');
      expect(snapshot?.favoritesJson, '[]');
    });

    test('fetch returns null when unavailable', () async {
      var called = false;
      final store = CloudUserStore(
        tokenProvider: () async => 'tok',
        client: MockClient((request) async {
          called = true;
          return http.Response('{"error": "denied"}', 403);
        }),
      );
      expect(await store.fetch('u1'), isNull);
      expect(called, isTrue);

      final noToken = CloudUserStore(
        tokenProvider: () async => null,
        client: MockClient((request) async {
          fail('client must not be called without a token');
        }),
      );
      expect(await noToken.fetch('u1'), isNull);
    });

    test('saveField patches only its field', () async {
      Uri? seenUri;
      String? seenBody;
      final store = CloudUserStore(
        tokenProvider: () async => 'tok',
        client: MockClient((request) async {
          expect(request.method, 'PATCH');
          seenUri = request.url;
          seenBody = request.body;
          return http.Response('{}', 200);
        }),
      );
      final ok = await store.saveField(
        'u1',
        field: 'history',
        jsonValue: '["a"]',
      );
      expect(ok, isTrue);
      expect(seenUri!.queryParameters['updateMask.fieldPaths'], 'history');
      expect(seenBody, contains('"history"'));
      expect(seenBody, contains('"stringValue"'));
    });

    test('saveField reports failure on error status', () async {
      final store = CloudUserStore(
        tokenProvider: () async => 'tok',
        client: MockClient((request) async =>
            http.Response('{"error": "not found"}', 404)),
      );
      expect(
        await store.saveField('u1', field: 'history', jsonValue: '[]'),
        isFalse,
      );
    });

    test('list codec round-trips and rejects garbage', () {
      final lines = [jsonEncode({'a': 1}), jsonEncode({'b': 2})];
      final packed = CloudUserStore.encodeList(lines);
      expect(CloudUserStore.decodeList(packed), lines);
      expect(CloudUserStore.decodeList(null), isNull);
      expect(CloudUserStore.decodeList(''), isNull);
      expect(CloudUserStore.decodeList('{broken'), isNull);
    });
  });

  group('HistoryRepository persistence', () {
    test('adopts pre-namespace data so updates lose nothing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.history: [
          jsonEncode(_history('legacy', DateTime(2026, 1, 1)).toJson()),
        ],
      });
      final repo = HistoryRepository(uid: 'user1');
      final items = await repo.load();
      expect(items.single.englishText, 'legacy');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(StorageKeys.historyFor('user1')) ?? const [],
        isNotEmpty,
      );
    });

    test('keeps accounts isolated from each other', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = HistoryRepository(uid: 'user1');
      await first.add(_history('mine', DateTime(2026, 1, 1)));

      final second = HistoryRepository(uid: 'user2');
      expect(await second.load(), isEmpty);
      expect((await first.load()).single.englishText, 'mine');
    });

    test('guest data is inherited once when signing in', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.historyFor(StorageKeys.guestNamespace): [
          jsonEncode(_history('pre-login', DateTime(2026, 1, 1)).toJson()),
        ],
      });
      final repo = HistoryRepository(uid: 'user9');
      await repo.inheritGuestData();

      final items = await repo.load();
      expect(items.single.englishText, 'pre-login');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(StorageKeys.historyFor(StorageKeys.guestNamespace)),
        isNull,
      );
    });

    test('inheritance never overwrites existing user data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.historyFor('user9'): [
          jsonEncode(_history('kept', DateTime(2026, 2, 1)).toJson()),
        ],
        StorageKeys.historyFor(StorageKeys.guestNamespace): [
          jsonEncode(_history('ignored', DateTime(2026, 1, 1)).toJson()),
        ],
      });
      final repo = HistoryRepository(uid: 'user9');
      await repo.inheritGuestData();
      final items = await repo.load();
      expect(items.single.englishText, 'kept');
    });
  });

  group('FavoritesRepository persistence', () {
    test('adopts pre-namespace data per account', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.favorites: [
          jsonEncode(_favorite('old-fav', DateTime(2026, 1, 1)).toJson()),
        ],
      });
      final repo = FavoritesRepository(uid: 'user3');
      final items = await repo.load();
      expect(items.single.result.englishText, 'old-fav');
      expect(await repo.contains('old-fav'), isTrue);
    });

    test('guest favorites are inherited once when signing in', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        StorageKeys.favoritesFor(StorageKeys.guestNamespace): [
          jsonEncode(_favorite('fav-pre', DateTime(2026, 1, 1)).toJson()),
        ],
      });
      final repo = FavoritesRepository(uid: 'user8');
      await repo.inheritGuestData();
      expect((await repo.load()).single.result.englishText, 'fav-pre');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs
            .getStringList(StorageKeys.favoritesFor(StorageKeys.guestNamespace)),
        isNull,
      );
    });
  });
}
