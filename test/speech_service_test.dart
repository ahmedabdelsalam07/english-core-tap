import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_core_tap/data/services/speech_service.dart';

/// Simulates the speech_to_text platform channel and verifies that:
///  1. init() marks the service available (the provider previously NEVER
///     called init, so the app always said "not available").
///  2. listen() BLOCKS until the final recognized words arrive.
///
/// NOTE: SpeechToText is an app-wide singleton internally, so tests share
/// engine state — they are written to be order-independent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
  bool engineAvailable = true;

  void sendCallback(String method, String payload) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, payload)),
      (_) {},
    );
  }

  setUp(() {
    engineAvailable = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'initialize':
          return engineAvailable;
        case 'has_permission':
          return true;
        case 'locales':
          return [
            {'localeId': 'en_US', 'name': 'English (United States)'},
            {'localeId': 'ar_SA', 'name': 'Arabic'},
          ];
        case 'listen':
          // Deliver a final result shortly after listening starts.
          // Wire format: {"alternates": [...], "resultType": 2 = final}.
          Future<void>.delayed(const Duration(milliseconds: 80), () {
            sendCallback(
              'textRecognition',
              '{"alternates":'
                  '[{"recognizedWords": "hello world", "confidence": 0.95}],'
                  '"resultType": 2}',
            );
          });
          return true;
        case 'stop':
        case 'cancel':
          return true;
        default:
          return null;
      }
    });
  });

  test('unavailable engine reports not-available instead of crashing',
      () async {
    engineAvailable = false;
    final speech = SpeechService();
    await speech.init();
    expect(speech.isAvailable.value, isFalse);
    expect(await speech.listen(), isNull);
    expect(await speech.requestPermission(), isFalse);
  });

  test('init() makes the service available and listen blocks for results',
      () async {
    engineAvailable = true;
    final speech = SpeechService();
    await speech.init();
    expect(speech.isAvailable.value, isTrue);

    final watch = Stopwatch()..start();
    final text = await speech.listen();
    watch.stop();

    expect(text, 'hello world');
    // Must have waited for the simulated recognition latency — proves
    // listen() blocks instead of returning null immediately.
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(70),
        reason: 'listen must wait for the final result');
    expect(speech.isListening.value, isFalse);
  });
}
