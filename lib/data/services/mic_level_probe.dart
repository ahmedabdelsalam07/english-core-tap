import 'dart:async';

import 'package:flutter/foundation.dart';

import 'mic_level_probe_stub.dart'
    if (dart.library.html) 'mic_level_probe_web.dart' as impl;

/// Streams live microphone loudness for the recording-feedback UI.
///
/// The Web Speech API never reports sound levels in browsers, so on web this
/// probe opens its own audio capture pipeline (WebAudio AnalyserNode) and
/// samples real loudness while recognition is active. On other platforms the
/// stub is inert — engines there report levels natively.
class MicLevelProbe {
  final dynamic _probe = impl.createProbe();

  bool get isRunning => _probe.isRunning as bool;

  /// Starts sampling; returns false when unsupported/denied (caller then
  /// keeps the breathing-pulse-only fallback).
  Future<bool> start(void Function(double level) onLevel) async {
    if (!kIsWeb) return false;
    try {
      return await (_probe.start(onLevel) as Future<bool>);
    } catch (_) {
      return false;
    }
  }

  void stop() {
    try {
      _probe.stop();
    } catch (_) {}
  }
}
