import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import 'api_config.dart';

class TranslationResult {
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  const TranslationResult({
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
  });
}

/// Translation service. Provider-based so it can be swapped without
/// touching the UI. Default provider: Google's free translate endpoint
/// (no API key required). A real backend can replace this later.
class TranslationService {
  final http.Client _client;
  TranslationService({http.Client? client}) : _client = client ?? http.Client();

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  bool isArabic(String text) => _arabicRegex.hasMatch(text);

  Future<TranslationResult> translate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppException(AppErrorKind.emptyInput);
    }
    final isArabicText = isArabic(trimmed);
    final source = isArabicText ? 'ar' : 'en';
    final target = isArabicText ? 'en' : 'ar';

    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
        '?client=gtx&sl=$source&tl=$target&dt=t&q=${Uri.encodeComponent(trimmed)}',
      );
      final response = await _client
          .get(uri)
          .timeout(Constants.apiTimeout);

      if (response.statusCode == 429) {
        throw const AppException(AppErrorKind.rateLimit);
      }
      if (response.statusCode != 200) {
        throw AppException(AppErrorKind.server, 'status ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is! List || data.isEmpty) {
        throw const AppException(AppErrorKind.translation);
      }
      final segments = data[0] as List<dynamic>? ?? const <dynamic>[];
      final buffer = StringBuffer();
      for (final segment in segments.whereType<List<dynamic>>()) {
        if (segment.isEmpty) continue;
        final value = segment[0] as String?;
        if (value != null && value.isNotEmpty) buffer.write(value);
      }
      final translated = buffer.toString().trim();
      if (translated.isEmpty) {
        throw const AppException(AppErrorKind.translation);
      }
      final detected = data.length > 2 ? data[2] as String? : null;
      return TranslationResult(
        translatedText: translated,
        sourceLang: detected ?? source,
        targetLang: target,
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(mapHttpError(e));
    }
  }

  void dispose() => _client.close();
}