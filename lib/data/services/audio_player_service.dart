import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';

/// Plays native audio URLs (e.g. dictionary recordings) with progress.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<String?> playingUrl = ValueNotifier<String?>(null);
  final ValueNotifier<double> progress = ValueNotifier<double>(0);
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);
  Duration _duration = Duration.zero;

  AudioPlayerService() {
    _player.onPositionChanged.listen((pos) {
      if (_duration.inMilliseconds > 0) {
        progress.value = (pos.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
      }
    });
    _player.onDurationChanged.listen((d) => _duration = d);
    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
      if (state == PlayerState.completed) {
        playingUrl.value = null;
        progress.value = 1;
      }
      if (state == PlayerState.stopped) {
        playingUrl.value = null;
      }
    });
    _player.onPlayerComplete.listen((_) {
      playingUrl.value = null;
      progress.value = 0;
      isPlaying.value = false;
    });
  }

  Future<void> play(String url) async {
    try {
      await _player.stop();
      playingUrl.value = url;
      progress.value = 0;
      await _player.play(UrlSource(url));
    } catch (e) {
      playingUrl.value = null;
      isPlaying.value = false;
      debugOnlyLog('audio play failed: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    playingUrl.value = null;
    progress.value = 0;
    isPlaying.value = false;
  }

  void dispose() {
    _player.dispose();
    playingUrl.dispose();
    progress.dispose();
    isPlaying.dispose();
  }
}