import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:english_core_tap/data/services/api_config.dart';
import 'package:english_core_tap/data/services/translation_service.dart';

void main() {
  test('primary clients5 provider parses flat array answer', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'clients5.google.com');
      return http.Response(
        jsonEncode(['مرحبًا']),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = TranslationService(client: client);
    final result = await service.translate('hello');
    expect(result.translatedText, 'مرحبًا');
    expect(result.sourceLang, 'en');
    expect(result.targetLang, 'ar');
  });

  test('falls back to classic Google when clients5 fails', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'clients5.google.com') {
        return http.Response('', 500);
      }
      expect(request.url.host, 'translate.googleapis.com');
      // Body mirrors the translate_a/single response shape.
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
  });

  test('rejects echo answer and uses next provider', () async {
    final client = MockClient((request) async {
      if (request.url.host == 'api.mymemory.translated.net') {
        return http.Response(
          jsonEncode({
            'responseData': {'translatedText': 'صباح الخير'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      // Both Google endpoints echo the input back untranslated.
      if (request.url.host == 'clients5.google.com') {
        return http.Response(jsonEncode(['good morning']), 200);
      }
      return http.Response(
        jsonEncode([
          [
            ['good morning', 'good morning'],
          ],
          null,
          'en',
        ]),
        200,
      );
    });

    final service = TranslationService(client: client);
    final result = await service.translate('good morning');
    expect(result.translatedText, 'صباح الخير');
  });

  test('throws translation error when every answer is invalid', () async {
    final client = MockClient((request) async => http.Response('', 200));
    final service = TranslationService(client: client);
    await expectLater(
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
      expect(e, isA<AppException>());
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
