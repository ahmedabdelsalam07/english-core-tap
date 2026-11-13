import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'api_config.dart';

/// American English text-to-speech service.
///
/// Provider-based (flutter_tts) and accent-aware (en-US). One preferred en-US
/// voice is resolved from the engine and re-applied before every utterance so
/// a word never plays in a different voice than the last one. Supports play /
/// pause / resume / stop / replay and speed control.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  /// Preferred voices, best first. Matching is a case-insensitive substring
  /// test on the engine's voice names, so engines that expose different names
  /// fall through to the next candidate instead of failing.
  static const List<String> _preferredVoices = <String>[
    'Google US English',
    'Google US',
    'Microsoft Aria',
    'Microsoft Guy',
    'Microsoft Zira',
    'Microsoft David',
    'Samantha',
    'Alex',
    'Ava',
    'Allison',
    'Daniel',
  ];

  String _currentText = '';
  double _currentSpeed = 1.0;
  String? _voiceName;
  String? _voiceLocale;

  bool get _isPauseSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  Timer? _progressTimer;
  final int _estimatedMsPerChar = 90;
  final int _tickMs = 250;

  Future<void> init() async {
    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      isPaused.value = false;
      progress.value = 1;
      _stopProgressTimer();
    });
    _tts.setCancelHandler(() {
      isSpeaking.value = false;
      isPaused.value = false;
      progress.value = 0;
      _stopProgressTimer();
    });
    _tts.setErrorHandler((msg) {
      isSpeaking.value = false;
      isPaused.value = false;
      progress.value = 0;
      _stopProgressTimer();
      debugOnlyLog('TTS error: $msg');
    });
    try {
      await _tts.setLanguage('en-US');
      await _tts.setPitch(1.0);
    } catch (_) {}
    await _selectVoice();
  }

  /// Resolves and pins ONE English voice for the whole session.
  ///
  /// Engines expose very different voice lists (Chrome, Android TTS, Windows
  /// SAPI, iOS AVSpeech); without an explicit choice each utterance can be
  /// spoken by a different default voice. The resolved voice is stored and
  /// re-applied in [speak] because some engines reset it on cancel.
  Future<void> _selectVoice() async {
    try {
      final raw = await _tts.getVoices;
      final voices = <Map<String, String>>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is! Map) continue;
          final name = (entry['name'] ?? entry['identifier'] ?? '').toString();
          final locale =
              (entry['locale'] ?? entry['language'] ?? '').toString();
          if (name.isEmpty) continue;
          voices.add(<String, String>{'name': name, 'locale': locale});
        }
      }
      if (voices.isEmpty) return;

      List<Map<String, String>> candidates = voices
          .where((v) => v['locale']!
              .toLowerCase()
              .replaceAll('-', '_')
              .startsWith('en_us'))
          .toList();
      if (candidates.isEmpty) {
        candidates = voices
            .where((v) => v['locale']!.toLowerCase().startsWith('en'))
            .toList();
      }
      if (candidates.isEmpty) return;

      Map<String, String>? chosen;
      for (final hint in _preferredVoices) {
        final matches = candidates
            .where((v) => v['name']!.toLowerCase().contains(hint.toLowerCase()))
            .toList();
        if (matches.isNotEmpty) {
          chosen = matches.first;
          break;
        }
      }
      chosen ??= candidates.first;

      await _tts.setVoice(
        <String, String>{'name': chosen['name']!, 'locale': chosen['locale']!},
      );
      _voiceName = chosen['name'];
      _voiceLocale = chosen['locale'];
    } catch (_) {
      // No voice list available: keep the engine default.
    }
  }

  /// Re-applies the pinned voice; silent when none could be resolved.
  Future<void> _applyVoice() async {
    final name = _voiceName;
    if (name == null) return;
    try {
      await _tts.setVoice(<String, String>{
        'name': name,
        'locale': _voiceLocale ?? 'en-US',
      });
    } catch (_) {}
  }

  /// Applies speed immediately to the engine (used by settings changes).
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _applyRate();
  }

  /// Pushes persisted preferences to the engine in one call.
  Future<void> applySettings({
    required double speed,
  }) async {
    _currentSpeed = speed;
    await _applyRate();
  }

  Future<void> speak(
    String text, {
    double? speed,
  }) async {
    if (text.trim().isEmpty) return;
    _currentText = text;
    if (speed != null) _currentSpeed = speed;
    await stop();
    if (kIsWeb) {
      // flutter_tts web silently DROPS speak() while its internal state is
      // still "playing" — cancel() fires onEnd asynchronously (or not at
      // all in some browsers). Speaking a blank utterance forces onEnd to
      // fire, resetting the state so the real utterance is not dropped.
      try {
        await _tts.speak(' ');
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
    }
    try {
      await _tts.setLanguage('en-US');
      await _applyVoice();
      await _applyRate();
      isPaused.value = false;
      isSpeaking.value = true;
      _startProgressTimer(text);
      final result = await _tts.speak(text);
      if (result == 0) {
        isSpeaking.value = false;
        _stopProgressTimer();
      }
    } catch (e) {
      isSpeaking.value = false;
      _stopProgressTimer();
      throw const AppException(AppErrorKind.tts, 'tts speak failed');
    }
  }

  Future<void> pause() async {
    if (!isSpeaking.value) return;
    if (!_isPauseSupported) {
      await stop();
      return;
    }
    try {
      await _tts.pause();
      isSpeaking.value = false;
      isPaused.value = true;
      _stopProgressTimer();
    } catch (_) {
      await stop();
    }
  }

  Future<void> resume() async {
    if (!isPaused.value) return;
    try {
      await _tts.speak(_currentText);
      isPaused.value = false;
      isSpeaking.value = true;
      _startProgressTimer(_currentText);
    } catch (_) {
      isPaused.value = false;
      throw const AppException(AppErrorKind.tts, 'tts resume failed');
    }
  }

  Future<void> replay() async {
    await stop();
    await speak(_currentText, speed: _currentSpeed);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking.value = false;
    isPaused.value = false;
    progress.value = 0;
    _stopProgressTimer();
  }

  Future<void> _applyRate() async {
    try {
      await _tts.setSpeechRate((0.5 * _currentSpeed).clamp(0.0, 1.0));
    } catch (_) {}
  }

  void _startProgressTimer(String text) {
    _stopProgressTimer();
    final estimatedTotal =
        (text.length * _estimatedMsPerChar).clamp(800, 30000);
    var elapsed = 0;
    _progressTimer = Timer.periodic(
      Duration(milliseconds: _tickMs),
      (_) {
        elapsed += _tickMs;
        progress.value = (elapsed / estimatedTotal).clamp(0.0, 1.0);
      },
    );
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  void dispose() {
    _stopProgressTimer();
    _tts.stop();
    isSpeaking.dispose();
    isPaused.dispose();
    progress.dispose();
  }
}