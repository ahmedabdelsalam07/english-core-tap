import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:english_core_tap/data/services/api_config.dart';
import 'package:english_core_tap/data/services/translation_service.dart';

void main() {
  test('translation parses Google translate response', () async {
    // Body mirrors the translate_a/single response shape.
    final client = MockClient((request) async {
      expect(request.url.path, contains('translate'));
      return http.Response(
        jsonEncode([
          [
            ['مرحبا', 'hello'],
            [' بالعالم', ' world'],
          ],
          null,
          'en',
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = TranslationService(client: client);
    final result = await service.translate('hello world');
    expect(result.translatedText, 'مرحبا بالعالم');
    expect(result.sourceLang, 'en');
    expect(result.targetLang, 'ar');
  });

  test('translation throws translation error on bad response', () async {
    final client = MockClient((request) async => http.Response('', 200));
    final service = TranslationService(client: client);
    expect(
      service.translate('hello'),
      throwsA(isA<AppException>()),
    );
  });

  test('translation throws network error on socket exception', () async {
    final client = MockClient((request) async {
      throw Exception('Failed host lookup');
    });
    final service = TranslationService(client: client);
    try {
      await service.translate('hello');
      fail('should throw');
    } catch (e) {
      expect((e as AppException).kind, AppErrorKind.network);
    }
  });

  test('empty input throws emptyInput', () async {
    final service = TranslationService();
    expect(
      service.translate('   '),
      throwsA(isA<AppException>()),
    );
  });
}