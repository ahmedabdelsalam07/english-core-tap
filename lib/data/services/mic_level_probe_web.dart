import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation: samples real microphone loudness through a dedicated
/// getUserMedia stream + WebAudio AnalyserNode, because the Web Speech API
/// does not expose sound levels.
class MicLevelProbeImpl {
  bool get isRunning => _timer != null;

  Timer? _timer;
  web.MediaStream? _stream;
  web.AudioContext? _ctx;

  /// RMS of speech typically sits around 0.01 (quiet) – 0.3 (loud).
  /// Scaled so the UI's 0..45 "dB-like" range matches the Android feel.
  static const double _rmsToLevel = 150.0;

  Future<bool> start(void Function(double level) onLevel) async {
    stop();
    final media = web.window.navigator.mediaDevices;

    final web.MediaStream stream;
    try {
      stream = await media
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
    } catch (_) {
      return false; // denied / unsupported → breathing-only fallback
    }
    _stream = stream;

    final web.AudioContext ctx;
    final web.AnalyserNode analyser;
    try {
      ctx = web.AudioContext();
      final source = ctx.createMediaStreamSource(stream);
      analyser = ctx.createAnalyser();
      analyser.fftSize = 1024;
      analyser.smoothingTimeConstant = 0.5;
      // Deliberately NOT connected to destination → no echo to the user.
      source.connect(analyser);
    } catch (_) {
      _releaseStream();
      return false;
    }
    _ctx = ctx;

    final binCount = analyser.frequencyBinCount;
    final samples = Float32List(binCount);
    final jsArray = samples.toJS;

    _timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      try {
        analyser.getFloatTimeDomainData(jsArray);
        var sum = 0.0;
        for (var i = 0; i < binCount; i++) {
          final v = samples[i];
          sum += v * v;
        }
        final rms = math.sqrt(sum / binCount);
        onLevel((rms * _rmsToLevel).clamp(0.0, 45.0));
      } catch (_) {}
    });
    return true;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    try {
      _ctx?.close().toDart;
    } catch (_) {}
    _ctx = null;
    _releaseStream();
  }

  void _releaseStream() {
    try {
      _stream?.getTracks().toDart.forEach((track) => track.stop());
    } catch (_) {}
    _stream = null;
  }
}

MicLevelProbeImpl createProbe() => MicLevelProbeImpl();
