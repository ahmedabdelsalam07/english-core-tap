import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'api_config.dart';

/// Speech-to-text service (English, en-US).
///
/// Two critical behaviours fixed here:
///  1. Availability is retried lazily — engines/browsers can report
///     "unavailable" on a cold first call, and the provider may not have
///     finished init when the user taps the mic.
///  2. [listen] BLOCKS until the final recognized sentence arrives (or the
///     timeout hits). The plugin's listen() only starts recognition; without
///     waiting on results, callers always saw an empty result.
class SpeechService {
  final SpeechToText _speech = SpeechToText();

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasPermission = ValueNotifier<bool>(false);

  bool _initAttempted = false;
  Completer<String?>? _pending;
  String _localeId = 'en_US';

  Future<void> init() async {
    if (_initAttempted && isAvailable.value) return;
    _initAttempted = true;
    try {
      isAvailable.value = await _speech.initialize(
        onError: (error) {
          debugOnlyLog('speech error: $error');
          _finishPending(null);
        },
        onStatus: (status) {
          debugOnlyLog('speech status: $status');
          isListening.value = status == 'listening';
        },
      );
    } catch (e) {
      debugOnlyLog('speech init failed: $e');
      isAvailable.value = false;
    }
    if (!isAvailable.value) {
      // Allow a later retry (e.g. after the browser grants mic access).
      _initAttempted = false;
      return;
    }
    try {
      final locales = await _speech.locales();
      final en = locales
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .where((l) => (l['localeId'] ?? '').toString().startsWith('en'))
          .toList();
      if (en.isNotEmpty) {
        _localeId = en.first['localeId'].toString();
      }
    } catch (_) {}
  }

  /// Ensures the engine is initialized; returns true when usable.
  Future<bool> requestPermission() async {
    if (!isAvailable.value) {
      await init();
    }
    if (!isAvailable.value) return false;
    hasPermission.value = true;
    return true;
  }

  /// Starts listening and completes with the FINAL recognized sentence,
  /// or null on silence / error / timeout.
  Future<String?> listen() async {
    if (!isAvailable.value) {
      await init();
    }
    if (!isAvailable.value) return null;
    _finishPending(null); // safety: drop any stale session

    final completer = Completer<String?>();
    _pending = completer;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: false,
          autoPunctuation: false,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 12),
          localeId: _localeId,
        ),
      );
    } catch (e) {
      debugOnlyLog('speech listen failed: $e');
      if (!completer.isCompleted) completer.complete(null);
      _pending = null;
      return null;
    }
    isListening.value = true;

    String? text;
    try {
      text = await completer.future.timeout(
        const Duration(seconds: 14),
        onTimeout: () => null,
      );
    } on TimeoutException {
      text = null;
    } finally {
      isListening.value = false;
      _pending = null;
      try {
        await _speech.stop();
      } catch (_) {}
    }
    if (text == null) return null;
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _finishPending(String? value) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) {
      pending.complete(value);
    }
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    isListening.value = false;
    _finishPending(null);
  }

  void dispose() {
    stop();
    isListening.dispose();
    isAvailable.dispose();
    hasPermission.dispose();
  }
}
