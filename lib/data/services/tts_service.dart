import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/enums.dart';
import 'api_config.dart';

/// A TTS voice that can be offered to the user (en-US only).
class AvailableVoice {
  final String name;
  final String locale;
  final VoiceGender gender;
  const AvailableVoice({
    required this.name,
    required this.locale,
    required this.gender,
  });
}

/// American English text-to-speech service.
///
/// Provider-based (flutter_tts) and accent-aware (en-US). Supports male /
/// female voice selection, play / pause / resume / stop / replay and speed.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isPaused = ValueNotifier<bool>(false);
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  final ValueNotifier<String> activeVoiceName = ValueNotifier<String>('');

  List<AvailableVoice> _available = <AvailableVoice>[];
  String _currentText = '';
  double _currentSpeed = 1.0;
  VoiceGender _currentGender = VoiceGender.auto;
  bool get _isPauseSupported => Platform.isIOS;
  Timer? _progressTimer;
  final int _estimatedMsPerChar = 90;
  final int _tickMs = 250;

  static const List<String> _androidMaleHints = [
    'tpf', 'tpd', 'tpc', 'tpb', 'en-us-x-iob', 'male',
  ];
  static const List<String> _androidFemaleHints = [
    'sfg', 'sfd', 'sfc', 'sfx', 'sfb', 'female',
  ];
  static const List<String> _iosMaleHints = [
    'fred', 'aaron', 'daniel', 'alex', 'nathan', 'gordon', 'thomas',
    'andrew', 'ravi', 'reed', 'rocko',
  ];
  static const List<String> _iosFemaleHints = [
    'samantha', 'karen', 'moira', 'tessa', 'zira', 'susan', 'serena',
    'katya', 'ava', 'aria', 'ana', 'allison', 'nico', 'ellen',
  ];

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
      final voices = await _tts.getVoices;
      if (voices != null) {
        _available = _parseAvailableVoices(voices);
      }
    } catch (_) {
      // voices may be unavailable on some emulators; TTS still works
    }
  }

  /// Only en-US voices, labeled male/female for the selector.
  List<AvailableVoice> get voices => _available;

  VoiceGender guessGenderOf(AvailableVoice v) => v.gender;

  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _applyRate();
  }

  Future<void> setGender(VoiceGender gender) async {
    _currentGender = gender;
    await _applyVoice();
  }

  Future<void> speak(
    String text, {
    VoiceGender gender = VoiceGender.auto,
    double speed = 1.0,
  }) async {
    if (text.trim().isEmpty) return;
    _currentText = text;
    _currentGender = gender;
    _currentSpeed = speed;
    await stop();
    try {
      await _tts.setLanguage('en-US');
      await _applyRate();
      await _applyVoice();
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
      if (Platform.isIOS) {
        await _tts.speak(_currentText);
      } else {
        await _tts.speak(_currentText);
      }
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
    await speak(
      _currentText,
      gender: _currentGender,
      speed: _currentSpeed,
    );
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

  Future<void> _applyVoice() async {
    activeVoiceName.value = '';
    if (_available.isEmpty || _currentGender == VoiceGender.auto) return;
    final match = _pickVoice(_currentGender);
    if (match == null) return;
    try {
      if (Platform.isAndroid) {
        await _tts.setVoice({'name': match.name, 'locale': 'en-US'});
      } else {
        await _tts.setVoice({'name': match.name, 'language': 'en-US'});
      }
      activeVoiceName.value = match.name;
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
  }

  AvailableVoice? _pickVoice(VoiceGender gender) {
    final candidates = _available.where((v) => v.gender == gender).toList();
    if (candidates.isEmpty) return null;
    return candidates.first;
  }

  List<AvailableVoice> _parseAvailableVoices(List<dynamic> raw) {
    final out = <AvailableVoice>[];
    for (final v in raw) {
      final map = (v is Map) ? Map<String, dynamic>.from(v) : null;
      if (map == null) continue;
      final name = (map['name'] ?? '').toString();
      final locale = ((map['locale'] ?? map['language']) ?? '')
          .toString()
          .toLowerCase();
      if (name.isEmpty || !locale.startsWith('en-us')) continue;
      final lower = name.toLowerCase();
      final maleHints =
          Platform.isAndroid ? _androidMaleHints : _iosMaleHints;
      final femaleHints =
          Platform.isAndroid ? _androidFemaleHints : _iosFemaleHints;
      final isMale = maleHints.any(lower.contains);
      final isFemale = femaleHints.any(lower.contains);
      out.add(
        AvailableVoice(
          name: name,
          locale: 'en-US',
          gender: isMale
              ? VoiceGender.male
              : (isFemale ? VoiceGender.female : VoiceGender.female),
        ),
      );
    }
    return out;
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
    activeVoiceName.dispose();
  }
}