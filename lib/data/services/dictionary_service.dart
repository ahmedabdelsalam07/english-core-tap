import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../models/word_result.dart';
import 'api_config.dart';

/// Provides per-word American IPA + native audio URLs + definitions.
class DictionaryService {
  final http.Client _client;
  DictionaryService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<WordResult>> transcribe(String text) async {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return <WordResult>[];

    final results = <WordResult>[];
    for (final word in words) {
      final clean = word.replaceAll(RegExp("[^A-Za-z']"), '');
      if (clean.isEmpty) continue;
      WordResult? entry;
      try {
        entry = await _fetchWord(clean);
      } catch (e) {
        entry = null;
        // ignore per-word failures; fall back to phonetic engine
      }
      results.add(entry ?? WordResult(word: word));
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return results;
  }

  Future<WordResult?> _fetchWord(String word) async {
    try {
      final uri = Uri.parse(
        '${Constants.dictionaryApiBase}${Uri.encodeComponent(word.toLowerCase())}',
      );
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return null;
      return WordResult.fromJson(data.first as Map<String, dynamic>);
    } on FormatException {
      return null;
    } catch (e) {
      throw AppException(mapHttpError(e));
    }
  }

  void dispose() => _client.close();
}