import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'api_config.dart';
import 'mic_level_probe.dart';

/// Dictation language for a speech session.
enum SpeechLang { english, arabic }

/// Speech-to-text service (English en-US + Arabic ar-EG).
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

  /// Web-only: real mic loudness via WebAudio (Web Speech API never
  /// reports levels in browsers). Inert on other platforms.
  final MicLevelProbe _levelProbe = MicLevelProbe();

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasPermission = ValueNotifier<bool>(false);

  /// Live microphone loudness while listening (engine decibel-ish units).
  /// Drives the real-time recording feedback UI; resets to 0 when idle.
  final ValueNotifier<double> soundLevel = ValueNotifier<double>(0);

  bool _initAttempted = false;
  Completer<String?>? _pending;
  String _enLocaleId = 'en_US';
  String _arLocaleId = 'ar_EG';

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
      final ids = await _speech.locales().then(
            (locales) => locales
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .map((l) => (l['localeId'] ?? '').toString())
                .toList(),
          );
      final en = ids.where((id) => id.startsWith('en')).toList();
      if (en.isNotEmpty) {
        _enLocaleId =
            en.firstWhere((id) => id == 'en_US', orElse: () => en.first);
      }
      final ar = ids.where((id) => id.startsWith('ar')).toList();
      if (ar.isNotEmpty) {
        _arLocaleId =
            ar.firstWhere((id) => id == 'ar_EG', orElse: () => ar.first);
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

  /// Starts listening in the requested language and completes with the
  /// FINAL recognized sentence, or null on silence / error / timeout.
  Future<String?> listen({SpeechLang lang = SpeechLang.english}) async {
    if (!isAvailable.value) {
      await init();
    }
    if (!isAvailable.value) return null;
    _finishPending(null); // safety: drop any stale session
    soundLevel.value = 0;

    final completer = Completer<String?>();
    _pending = completer;
    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          if (!completer.isCompleted) {
            completer.complete(result.recognizedWords);
          }
        },
        onSoundLevelChange: (double level) {
          soundLevel.value = level;
        },
        listenOptions: SpeechListenOptions(
          partialResults: false,
          cancelOnError: false,
          autoPunctuation: false,
          pauseFor: const Duration(seconds: 4),
          listenFor: const Duration(seconds: 12),
          localeId:
              lang == SpeechLang.arabic ? _arLocaleId : _enLocaleId,
        ),
      );
    } catch (e) {
      debugOnlyLog('speech listen failed: $e');
      if (!completer.isCompleted) completer.complete(null);
      _pending = null;
      soundLevel.value = 0;
      return null;
    }
    isListening.value = true;
    // Web: recognition itself streams no levels — sample the mic directly
    // so the recording UI reacts to the real voice. Failure here just keeps
    // the breathing-pulse fallback.
    await _levelProbe.start((level) => soundLevel.value = level);

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
      _levelProbe.stop();
      soundLevel.value = 0;
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
    _levelProbe.stop();
    isListening.value = false;
    soundLevel.value = 0;
    _finishPending(null);
  }

  void dispose() {
    stop();
    isListening.dispose();
    isAvailable.dispose();
    hasPermission.dispose();
    soundLevel.dispose();
  }
}
