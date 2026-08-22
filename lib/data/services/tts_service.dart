import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/enums.dart';
import 'api_config.dart';

/// A TTS voice that can be offered to the user (English only).
class AvailableVoice {
  final String name;
  final String locale;
  final String rawLocale; // exact string reported by the engine
  final VoiceGender gender; // male / female / auto (= undetected)
  const AvailableVoice({
    required this.name,
    required this.locale,
    required this.rawLocale,
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
  String _lastAppliedVoiceName = '';
  double _activePitch = 1.0;
  bool get _isPauseSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  Timer? _progressTimer;
  final int _estimatedMsPerChar = 90;
  final int _tickMs = 250;

  // Gender markers that appear directly in engine-provided voice metadata.
  static const List<String> _maleMarkers = ['male', 'man', 'boy'];
  static const List<String> _femaleMarkers = ['female', 'woman', 'girl'];

  // Known engine voice name fragments (Google TTS + Samsung + iOS).
  // One combined table — the fragments are distinctive enough that a single
  // platform-independent lookup is safe and far more robust.
  static const List<String> _maleHints = [
    '-iom', 'iob', 'tpd', 'tpc', 'tpb', 'g-d', 'rda',
    'fred', 'aaron', 'daniel', 'alex', 'nathan', 'gordon', 'thomas',
    'andrew', 'ravi', 'reed', 'rocko', 'grandpa', 'eddy',
    // Chrome / Edge / Safari browser voices
    'david', 'mark', 'guy', 'james', 'ryan', 'george', 'william',
    'eric', 'christopher', 'roger', 'brian', 'matthew', 'joey',
    'justin', 'kevin', 'arthur',
  ];
  static const List<String> _femaleHints = [
    'iol', 'iac', 'iuf', 'sfg', 'sfd', 'sfc', 'sfx', 'sfb', 'tpf', 'rmc',
    'g-f',
    'samantha', 'karen', 'moira', 'tessa', 'zira', 'susan', 'serena',
    'katya', 'ava', 'aria', 'ana', 'allison', 'nico', 'ellen', 'grandma',
    'shelley', 'sandy', 'flo',
    // Chrome / Edge / Safari browser voices
    'hazel', 'jenny', 'libby', 'clara', 'olivia', 'joanna', 'kendra',
    'kimberly', 'salli', 'ivy', 'nicole', 'emma', 'amy', 'sonia',
    'michelle', 'natasha', 'sonya', 'elsa', 'maria', 'linda', 'heather',
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
    } catch (_) {}
    await refreshVoices();
  }

  /// (Re)queries the engine for available voices. Safe to call multiple
  /// times — Android engines are often still warming up when first asked.
  Future<void> refreshVoices() async {
    try {
      final voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        final parsed = _parseAvailableVoices(voices);
        if (parsed.isNotEmpty) {
          _available = parsed;
        }
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
  /// Strategy: try EVERY candidate voice of the requested gender until the
  /// engine accepts one, then apply a strong pitch layer on top so the
  /// male/female switch is always clearly audible even when the engine has
  /// only a single voice installed.
  Future<void> _applyVoice() async {
    if (_currentGender == VoiceGender.auto) {
      _activePitch = 1.0;
      try {
        await _tts.setPitch(1.0);
      } catch (_) {}
      activeVoiceName.value = '';
      return;
    }

    // The engine list can arrive late on cold start — retry once.
    if (_available.isEmpty) {
      await refreshVoices();
    }

    var applied = false;
    final candidates = _candidatesFor(_currentGender);
    for (final voice in candidates.take(5)) {
      if (await _tryApplyVoice(voice)) {
        applied = true;
        _lastWorkingVoice[_currentGender] = voice.name;
        activeVoiceName.value = voice.name;
        debugOnlyLog('TTS applied voice: ${voice.name}');
        break;
      }
    }

    // Strong pitch per gender: this is the guaranteed-audible layer that
    // works even when the engine exposes a single English voice.
    final natural = _currentGender == VoiceGender.male ? 0.65 : 1.40;
    _activePitch = applied ? natural : (natural == 1.40 ? 1.50 : 0.55);
    try {
      await _tts.setPitch(_activePitch);
    } catch (_) {}
    if (!applied && activeVoiceName.value.isEmpty) {
      activeVoiceName.value =
          '${_currentGender.name} (pitch ${_activePitch.toStringAsFixed(2)})';
    }
  }

  final Map<VoiceGender, String> _lastWorkingVoice = {};

  /// Ordered candidate voices: previously-working voice first, then all
  /// voices of the requested gender, then any other voice than the last
  /// applied one.
  List<AvailableVoice> _candidatesFor(VoiceGender gender) {
    final preferred = _lastWorkingVoice[gender];
    int rank(AvailableVoice v) {
      if (preferred != null && v.name == preferred) return 0;
      if (v.gender == gender) return 1;
      return 2;
    }

    final sorted = [..._available]..sort((a, b) {
        final r = rank(a) - rank(b);
        if (r != 0) return r;
        return a.name.compareTo(b.name);
      });
    if (_lastAppliedVoiceName.isEmpty || sorted.length <= 1) return sorted;
    // When switching genders make sure the top candidate differs from the
    // currently applied voice whenever possible.
    final rotated = [
      ...sorted.where((v) => v.name != _lastAppliedVoiceName),
      ...sorted.where((v) => v.name == _lastAppliedVoiceName),
    ];
    return rotated;
  }

  Future<bool> _tryApplyVoice(AvailableVoice voice) async {
    try {
      await _tts.setLanguage(voice.locale == 'en' ? 'en-US' : voice.locale);
      // Each platform implementation reads its own key:
      //  - Android / web: "name" + "locale"
      //  - iOS / macOS:   "name" + "language"
      // Sending all keys keeps one universal code path; extras are ignored.
      await _tts.setVoice({
        'name': voice.name,
        'locale': voice.rawLocale,
        'language': voice.rawLocale,
      });
      _lastAppliedVoiceName = voice.name;
      return true;
    } catch (_) {
      return false;
    }
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
    for (final h in _maleHints) {
      if (lowerName.contains(h)) return VoiceGender.male;
    }
    for (final h in _femaleHints) {
      if (lowerName.contains(h)) return VoiceGender.female;
    }
    return VoiceGender.auto;
  }

  List<AvailableVoice> _parseAvailableVoices(List<dynamic> raw) {
    final out = <AvailableVoice>[];
    for (final v in raw) {
      final map = (v is Map) ? Map<String, dynamic>.from(v) : null;
      if (map == null) continue;
      final name = (map['name'] ?? '').toString();
      final rawLocale = ((map['locale'] ?? map['language']) ?? '').toString();
      final locale = rawLocale.toLowerCase().replaceAll('_', '-');
      if (name.isEmpty || !locale.startsWith('en')) continue;
      out.add(
        AvailableVoice(
          name: name,
          locale: locale.startsWith('en-us') ? 'en-US' : 'en',
          rawLocale: rawLocale,
          gender: _detectGender(name.toLowerCase()),
        ),
      );
    }
    // Prefer en-US voices first, then any other English variant.
    out.sort((a, b) {
      final aUs = a.locale == 'en-US' ? 0 : 1;
      final bUs = b.locale == 'en-US' ? 0 : 1;
      if (aUs != bUs) return aUs - bUs;
      return a.name.compareTo(b.name);
    });
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
