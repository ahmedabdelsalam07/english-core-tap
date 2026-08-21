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

/// Translation service with automatic direction detection
/// (Arabic→English AND English→Arabic).
///
/// Reliability strategy: Google's free endpoint occasionally rejects
/// requests (403/429 suspicion throttling). We therefore:
///   1. retry the primary endpoint once after a short back-off,
///   2. fall back to a secondary provider (MyMemory),
///   3. only surface an error if every attempt fails.
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

    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      try {
        return await _translateGoogle(trimmed, source, target);
      } on AppException catch (e) {
        // Empty input never benefits from a retry.
        if (e.kind == AppErrorKind.emptyInput) rethrow;
      } catch (_) {
        // Network/timeout — fall through to retry & secondary provider.
      }
    }
    // Secondary provider before giving up.
    try {
      return await _translateMyMemory(trimmed, source, target);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(mapHttpError(e));
    }
  }

  Future<TranslationResult> _translateGoogle(
    String text,
    String source,
    String target,
  ) async {
    final uri = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx&sl=$source&tl=$target&dt=t&q=${Uri.encodeComponent(text)}',
    );
    final response = await _client.get(uri).timeout(Constants.apiTimeout);

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
  }

  /// Fallback provider — different infrastructure entirely.
  Future<TranslationResult> _translateMyMemory(
    String text,
    String source,
    String target,
  ) async {
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get'
      '?langpair=$source|$target&q=${Uri.encodeComponent(text)}',
    );
    final response = await _client.get(uri).timeout(Constants.apiTimeout);
    if (response.statusCode != 200) {
      throw AppException(AppErrorKind.server, 'status ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final payload =
        (data['responseData'] as Map<String, dynamic>? ?? const {});
    var translated = (payload['translatedText'] ?? '').toString();
    translated = _decodeHtmlEntities(translated).trim();
    if (translated.isEmpty ||
        translated.toUpperCase().startsWith('MYMEMORY WARNING')) {
      throw const AppException(AppErrorKind.translation);
    }
    return TranslationResult(
      translatedText: translated,
      sourceLang: source,
      targetLang: target,
    );
  }

  static String _decodeHtmlEntities(String input) => input
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  void dispose() => _client.close();
}
