import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'api_config.dart';

/// Speech-to-text service (English, en-US).
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isAvailable = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasPermission = ValueNotifier<bool>(false);

  String _localeId = 'en_US';

  Future<void> init() async {
    isAvailable.value = await _speech.initialize(
      onError: (error) {
        debugOnlyLog('speech error: $error');
      },
      onStatus: (status) {
        if (status == 'listening') {
          isListening.value = true;
        } else {
          isListening.value = false;
        }
      },
    );
    if (isAvailable.value) {
      try {
        final locales = await _speech.locales();
        final en = locales.where((l) => l.localeId.startsWith('en')).toList();
        if (en.isNotEmpty) {
          _localeId = en.first.localeId;
        }
      } catch (_) {}
    }
  }

  Future<bool> requestPermission() async {
    final available = await _speech.initialize();
    isAvailable.value = available;
    if (!available) return false;
    hasPermission.value = true;
    return true;
  }

  Future<String?> listen() async {
    if (!isAvailable.value) return null;
    String? resultText;
    await _speech.listen(
      localeId: _localeId,
      listenFor: const Duration(seconds: 15),
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          resultText = result.recognizedWords;
        }
      },
    );
    isListening.value = true;
    return resultText;
  }

  Future<void> stop() async {
    await _speech.stop();
    isListening.value = false;
  }

  void dispose() {
    _speech.stop();
    isListening.dispose();
    isAvailable.dispose();
    hasPermission.dispose();
  }
}