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
/// Reliability strategy: free endpoints occasionally throttle requests
/// (Google's classic endpoint answers 429 very aggressively lately), and
/// some providers echo the input back or emit malformed Arabic (glyph
/// presentation forms). We therefore walk a chain of independent providers
/// and VALIDATE every answer before accepting it:
///   1. Google clients5 (dict-chrome-ex) — fast and rarely throttled,
///   2. Google classic translate_a/single (gtx),
///   3. MyMemory — different infrastructure entirely, normalized.
/// Only if every attempt fails (or every answer is invalid) an error is
/// surfaced to the user.
class TranslationService {
  final http.Client _client;
  TranslationService({http.Client? client}) : _client = client ?? http.Client();

  static final RegExp _arabicRegex = RegExp(r'[\u0600-\u06FF]');
  static final RegExp _latinRegex = RegExp(r'[A-Za-z]');

  bool isArabic(String text) => _arabicRegex.hasMatch(text);

  Future<TranslationResult> translate(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw const AppException(AppErrorKind.emptyInput);
    }
    final source = isArabic(trimmed) ? 'ar' : 'en';
    final target = source == 'ar' ? 'en' : 'ar';

    final attempts = <Future<TranslationResult> Function()>[
      () => _translateClients5(trimmed, source, target),
      () => _translateGoogleSingle(trimmed, source, target),
      () => _translateMyMemory(trimmed, source, target),
    ];

    Object? lastError;
    for (var i = 0; i < attempts.length; i++) {
      // Small back-off so a throttled provider gets a moment to breathe.
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      try {
        final result = await attempts[i]();
        if (_outputLooksValid(result.translatedText, target)) {
          return result;
        }
        // Untrusted output (echo / garbage) — try the next provider.
        lastError = const AppException(AppErrorKind.translation);
      } on AppException catch (e) {
        if (e.kind == AppErrorKind.emptyInput) rethrow;
        lastError = e;
      } catch (e) {
        // Preserve the network/server distinction for honest error banners.
        lastError = AppException(mapHttpError(e));
      }
    }
    throw lastError ?? const AppException(AppErrorKind.translation);
  }

  /// Guards against the two known failure modes: echoing the input back
  /// untranslated, and emitting Arabic in glyph presentation forms that
  /// renders as disconnected/reversed letters.
  bool _outputLooksValid(String text, String target) {
    final t = text.trim();
    if (t.isEmpty) return false;
    if (t.toUpperCase().startsWith('MYMEMORY WARNING')) return false;
    if (RegExp(r'[\uFE70-\uFEFF]').hasMatch(t)) return false;
    if (target == 'ar') return _arabicRegex.hasMatch(t);
    return _latinRegex.hasMatch(t);
  }

  /// Primary provider — the Chrome-dictionary Google endpoint. Same engine
  /// as the classic one behind a much lighter rate limit.
  Future<TranslationResult> _translateClients5(
    String text,
    String source,
    String target,
  ) async {
    final uri = Uri.parse(
      'https://clients5.google.com/translate_a/t'
      '?client=dict-chrome-ex&sl=$source&tl=$target'
      '&q=${Uri.encodeComponent(text)}',
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
    final buffer = StringBuffer();
    for (final segment in data) {
      if (segment is String) {
        buffer.write(segment);
      } else if (segment is List &&
          segment.isNotEmpty &&
          segment.first is String) {
        buffer.write(segment.first as String);
      }
    }
    final translated = buffer.toString().trim();
    if (translated.isEmpty) {
      throw const AppException(AppErrorKind.translation);
    }
    return TranslationResult(
      translatedText: translated,
      sourceLang: source,
      targetLang: target,
    );
  }

  /// Secondary provider — the classic free Google endpoint.
  Future<TranslationResult> _translateGoogleSingle(
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

  /// Last-resort provider — different infrastructure entirely. Its Arabic
  /// sometimes arrives in presentation forms; those are normalized here and
  /// anything still malformed is rejected by the caller's validation.
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
    translated = _decodeHtmlEntities(_normalizeArabicForms(translated)).trim();
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

  /// Maps Arabic Presentation Forms-B (U+FE70–U+FEFF) back to their standard
  /// letters so the output renders correctly everywhere.
  static const Map<String, String> _arabicPresentationForms = {
    '\uFE70': '\u064B', '\uFE71': '\u064B', '\uFE72': '\u064E',
    '\uFE74': '\u064F', '\uFE76': '\u0650', '\uFE78': '\u0651',
    '\uFE7A': '\u0652', '\uFE7C': '\u0653', '\uFE7E': '\u0654',
    '\uFE80': '\u0621', '\uFE81': '\u0622', '\uFE82': '\u0622',
    '\uFE83': '\u0623', '\uFE84': '\u0623', '\uFE85': '\u0624',
    '\uFE86': '\u0624', '\uFE87': '\u0625', '\uFE88': '\u0625',
    '\uFE89': '\u0626', '\uFE8A': '\u0626', '\uFE8B': '\u0626',
    '\uFE8C': '\u0626', '\uFE8D': '\u0627', '\uFE8E': '\u0627',
    '\uFE8F': '\u0628', '\uFE90': '\u0628', '\uFE91': '\u0628',
    '\uFE92': '\u0628', '\uFE93': '\u0629', '\uFE94': '\u0629',
    '\uFE95': '\u062A', '\uFE96': '\u062A', '\uFE97': '\u062A',
    '\uFE98': '\u062A', '\uFE99': '\u062B', '\uFE9A': '\u062B',
    '\uFE9B': '\u062B', '\uFE9C': '\u062B', '\uFE9D': '\u062C',
    '\uFE9E': '\u062C', '\uFE9F': '\u062C', '\uFEA0': '\u062C',
    '\uFEA1': '\u062D', '\uFEA2': '\u062D', '\uFEA3': '\u062D',
    '\uFEA4': '\u062D', '\uFEA5': '\u062E', '\uFEA6': '\u062E',
    '\uFEA7': '\u062E', '\uFEA8': '\u062E', '\uFEA9': '\u062F',
    '\uFEAA': '\u062F', '\uFEAB': '\u0630', '\uFEAC': '\u0630',
    '\uFEAD': '\u0631', '\uFEAE': '\u0631', '\uFEAF': '\u0632',
    '\uFEB0': '\u0632', '\uFEB1': '\u0633', '\uFEB2': '\u0633',
    '\uFEB3': '\u0633', '\uFEB4': '\u0633', '\uFEB5': '\u0634',
    '\uFEB6': '\u0634', '\uFEB7': '\u0634', '\uFEB8': '\u0634',
    '\uFEB9': '\u0635', '\uFEBA': '\u0635', '\uFEBB': '\u0635',
    '\uFEBC': '\u0635', '\uFEBD': '\u0636', '\uFEBE': '\u0636',
    '\uFEBF': '\u0636', '\uFEC0': '\u0636', '\uFEC1': '\u0637',
    '\uFEC2': '\u0637', '\uFEC3': '\u0637', '\uFEC4': '\u0637',
    '\uFEC5': '\u0638', '\uFEC6': '\u0638', '\uFEC7': '\u0638',
    '\uFEC8': '\u0638', '\uFEC9': '\u0639', '\uFECA': '\u0639',
    '\uFECB': '\u0639', '\uFECC': '\u0639', '\uFECD': '\u063A',
    '\uFECE': '\u063A', '\uFECF': '\u063A', '\uFED0': '\u063A',
    '\uFED1': '\u0641', '\uFED2': '\u0641', '\uFED3': '\u0641',
    '\uFED4': '\u0641', '\uFED5': '\u0642', '\uFED6': '\u0642',
    '\uFED7': '\u0642', '\uFED8': '\u0642', '\uFED9': '\u0643',
    '\uFEDA': '\u0643', '\uFEDB': '\u0643', '\uFEDC': '\u0643',
    '\uFEDD': '\u0644', '\uFEDE': '\u0644', '\uFEDF': '\u0644',
    '\uFEE0': '\u0644', '\uFEE1': '\u0645', '\uFEE2': '\u0645',
    '\uFEE3': '\u0645', '\uFEE4': '\u0645', '\uFEE5': '\u0646',
    '\uFEE6': '\u0646', '\uFEE7': '\u0646', '\uFEE8': '\u0646',
    '\uFEE9': '\u0647', '\uFEEA': '\u0647', '\uFEEB': '\u0647',
    '\uFEEC': '\u0647', '\uFEED': '\u0648', '\uFEEE': '\u0648',
    '\uFEEF': '\u0649', '\uFEF0': '\u0649', '\uFEF1': '\u064A',
    '\uFEF2': '\u064A', '\uFEF3': '\u064A', '\uFEF4': '\u064A',
    '\uFEF5': '\u0644\u0627', '\uFEF6': '\u0644\u0622',
    '\uFEF7': '\u0644\u0623', '\uFEF8': '\u0644\u0623',
    '\uFEF9': '\u0644\u0625', '\uFEFA': '\u0644\u0625',
    '\uFEFB': '\u0644\u0627', '\uFEFC': '\u0644\u0627',
  };

  static String _normalizeArabicForms(String input) => input.splitMapJoin(
        RegExp('[\uFE70-\uFEFF]'),
        onMatch: (m) => _arabicPresentationForms[m[0]] ?? (m[0] ?? ''),
        onNonMatch: (s) => s,
      );

  static String _decodeHtmlEntities(String input) => input
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');

  void dispose() => _client.close();
}
