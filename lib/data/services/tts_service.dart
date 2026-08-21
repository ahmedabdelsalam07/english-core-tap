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
  final VoiceGender gender; // male / female / auto (= undetected)
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
///
/// Voice strategy (robust across Android/iOS):
///  1. Query the engine for available voices at init.
///  2. Detect gender dynamically from voice names/markers.
///  3. Pick requested gender → any gendered en-US voice → any en-US voice.
///  4. If no distinct voice exists, apply a real pitch differentiation so the
///     engine output audibly changes (documented fallback, never a fake UI).
///  5. Never crash when a voice is unavailable.
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
  double _activePitch = 1.0;
  bool get _isPauseSupported => Platform.isIOS;
  Timer? _progressTimer;
  final int _estimatedMsPerChar = 90;
  final int _tickMs = 250;

  // Gender markers that appear directly in engine-provided voice metadata.
  static const List<String> _maleMarkers = ['male', 'man', 'boy'];
  static const List<String> _femaleMarkers = ['female', 'woman', 'girl'];

  // Known Android (Google TTS) voice name fragments.
  static const List<String> _androidMaleHints = [
    '-iom', 'iol', 'iob', 'tpd', 'tpc', 'tpb', 'g-d', 'rda',
    'male', // substring of "female" too — order matters, see detection below
  ];
  static const List<String> _androidFemaleHints = [
    'sfg', 'sfd', 'sfc', 'sfx', 'sfb', 'tpf', 'rmc', 'g-f',
  ];
  static const List<String> _iosMaleHints = [
    'fred', 'aaron', 'daniel', 'alex', 'nathan', 'gordon', 'thomas',
    'andrew', 'ravi', 'reed', 'rocko', 'grandpa', 'eddy',
  ];
  static const List<String> _iosFemaleHints = [
    'samantha', 'karen', 'moira', 'tessa', 'zira', 'susan', 'serena',
    'katya', 'ava', 'aria', 'ana', 'allison', 'nico', 'ellen', 'grandma',
    'shelley', 'sandy', 'flo',
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
    debugOnlyLog('TTS voices found: ${_available.length}');
  }

  /// Only en-US voices, labeled male/female/auto.
  List<AvailableVoice> get voices => _available;

  bool get hasMaleVoice => _available.any((v) => v.gender == VoiceGender.male);
  bool get hasFemaleVoice =>
      _available.any((v) => v.gender == VoiceGender.female);

  VoiceGender guessGenderOf(AvailableVoice v) => v.gender;

  /// Applies speed immediately to the engine (used by settings changes).
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;
    await _applyRate();
  }

  /// Applies voice/pitch immediately to the engine (settings changes).
  Future<void> setGender(VoiceGender gender) async {
    _currentGender = gender;
    await _applyVoice();
  }

  /// Pushes both persisted preferences to the engine in one call.
  Future<void> applySettings({
    required VoiceGender gender,
    required double speed,
  }) async {
    _currentGender = gender;
    _currentSpeed = speed;
    await _applyRate();
    await _applyVoice();
  }

  Future<void> speak(
    String text, {
    VoiceGender gender = VoiceGender.auto,
    double? speed,
  }) async {
    if (text.trim().isEmpty) return;
    _currentText = text;
    _currentGender = gender;
    if (speed != null) _currentSpeed = speed;
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

  /// Resolves and applies the closest matching voice for [_currentGender].
  ///
  /// Fallback chain: exact gender → any en-US voice → system default with a
  /// pitch-based differentiation so the selection is always audible.
  Future<void> _applyVoice() async {
    if (_currentGender == VoiceGender.auto) {
      _activePitch = 1.0;
      try {
        await _tts.setPitch(1.0);
      } catch (_) {}
      activeVoiceName.value = '';
      return;
    }

    final match = _pickVoice(_currentGender);
    var applied = false;
    if (match != null) {
      try {
        if (Platform.isAndroid) {
          await _tts.setVoice({'name': match.name, 'locale': 'en-US'});
        } else {
          await _tts.setVoice({'name': match.name, 'language': 'en-US'});
        }
        applied = true;
        activeVoiceName.value = match.name;
      } catch (_) {
        try {
          await _tts.setLanguage('en-US');
        } catch (_) {}
      }
    }

    // Natural pitch per gender; slightly emphasised when only the fallback
    // path is available so the change remains clearly audible.
    final natural = _currentGender == VoiceGender.male ? 0.85 : 1.15;
    _activePitch = applied ? natural : (natural == 1.15 ? 1.25 : 0.75);
    try {
      await _tts.setPitch(_activePitch);
    } catch (_) {}
    if (!applied && activeVoiceName.value.isEmpty) {
      activeVoiceName.value =
          '${_currentGender.name} (pitch ${_activePitch.toStringAsFixed(2)})';
    }
  }

  AvailableVoice? _pickVoice(VoiceGender gender) {
    final exact =
        _available.where((v) => v.gender == gender).toList();
    if (exact.isNotEmpty) return exact.first;
    // Safe fallback: any available en-US voice (prefer undetected-gender
    // ones before the opposite gender).
    final neutral =
        _available.where((v) => v.gender == VoiceGender.auto).toList();
    if (neutral.isNotEmpty) return neutral.first;
    return _available.isEmpty ? null : _available.first;
  }

  VoiceGender _detectGender(String lowerName) {
    // Explicit markers win first ("female" contains "male", so check it
    // before generic "male").
    for (final m in _femaleMarkers) {
      if (lowerName.contains(m)) return VoiceGender.female;
    }
    for (final m in _maleMarkers) {
      if (lowerName.contains(m)) return VoiceGender.male;
    }
    final hints = Platform.isAndroid ? _androidMaleHints : _iosMaleHints;
    for (final h in hints.skip(Platform.isAndroid ? 1 : 0)) {
      if (lowerName.contains(h)) return VoiceGender.male;
    }
    final fHints = Platform.isAndroid ? _androidFemaleHints : _iosFemaleHints;
    for (final h in fHints) {
      if (lowerName.contains(h)) return VoiceGender.female;
    }
    if (!Platform.isAndroid) {
      // Android list keeps 'male' last to avoid matching "female".
      if (lowerName.contains('male')) return VoiceGender.male;
    }
    return VoiceGender.auto;
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
      out.add(
        AvailableVoice(
          name: name,
          locale: 'en-US',
          gender: _detectGender(name.toLowerCase()),
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
