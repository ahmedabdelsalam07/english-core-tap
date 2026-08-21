import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_core_tap/core/enums.dart';
import 'package:english_core_tap/data/services/tts_service.dart';

/// Simulates the platform TTS engine and verifies that switching between
/// male/female actually changes the applied voice AND pitch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_tts');
  List<Map<String, String>> engineVoices = [];
  String? lastVoiceName;
  String? lastVoiceLocaleKey;
  double? lastPitch;

  setUp(() {
    engineVoices = [];
    lastVoiceName = null;
    lastVoiceLocaleKey = null;
    lastPitch = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getVoices':
          return engineVoices;
        case 'setPitch':
          lastPitch = (call.arguments as num?)?.toDouble();
          return 1;
        case 'setVoice':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          lastVoiceName = args['name'] as String?;
          lastVoiceLocaleKey =
              (args['locale'] ?? args['language']) as String?;
          return 1;
        default:
          return 1;
      }
    });
  });

  test('male vs female applies different engine voices + opposite pitch',
      () async {
    engineVoices = [
      {'name': 'en-us-x-iom-local', 'locale': 'en-US'},
      {'name': 'en-us-x-iol-local', 'locale': 'en-US'},
    ];
    final tts = TtsService();
    await tts.init();

    await tts.speak('hello world', gender: VoiceGender.male, speed: 1.0);
    final maleVoice = lastVoiceName;
    final malePitch = lastPitch!;
    expect(maleVoice, 'en-us-x-iom-local',
        reason: 'male marker -iom must be detected');
    expect(malePitch, lessThan(1.0), reason: 'male pitch must be lower');

    await tts.speak('hello world', gender: VoiceGender.female, speed: 1.0);
    final femaleVoice = lastVoiceName;
    final femalePitch = lastPitch!;
    expect(femaleVoice, isNot(maleVoice),
        reason: 'switching gender must change the engine voice');
    expect(femaleVoice, 'en-us-x-iol-local');
    expect(femalePitch, greaterThan(1.0), reason: 'female pitch must be higher');

    await tts.speak('hello world', gender: VoiceGender.male, speed: 1.0);
    expect(lastVoiceName, maleVoice,
        reason: 'toggling back must restore the male voice');
    expect(lastPitch!, lessThan(1.0));
    tts.dispose();
  });

  test('web-style voices (browser names) are detected and locale key sent',
      () async {
    engineVoices = [
      {'name': 'Microsoft David - English (United States)', 'locale': 'en-US'},
      {'name': 'Microsoft Zira - English (United States)', 'locale': 'en-US'},
      {'name': 'Google US English', 'locale': 'en-US'},
    ];
    final tts = TtsService();
    await tts.init();

    await tts.speak('hi', gender: VoiceGender.male, speed: 1.0);
    expect(lastVoiceName, 'Microsoft David - English (United States)',
        reason: 'David must be detected as male');
    // flutter_tts web reads ONLY the "locale" key — it must always be sent.
    expect(lastVoiceLocaleKey, 'en-US');

    await tts.speak('hi', gender: VoiceGender.female, speed: 1.0);
    expect(
        lastVoiceName, 'Microsoft Zira - English (United States)',
        reason: 'Zira must win over undetected Google US English');
    tts.dispose();
  });

  test('setVoice sends both locale and language keys with raw value',
      () async {
    engineVoices = [
      {'name': 'eng-USA-female', 'locale': 'en_US'},
    ];
    String? localeKey;
    String? languageKey;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getVoices':
          return engineVoices;
        case 'setVoice':
          final args = Map<String, dynamic>.from(call.arguments as Map);
          lastVoiceName = args['name'] as String?;
          localeKey = args['locale'] as String?;
          languageKey = args['language'] as String?;
          return 1;
        case 'setPitch':
          lastPitch = (call.arguments as num?)?.toDouble();
          return 1;
        default:
          return 1;
      }
    });
    final tts = TtsService();
    await tts.init();

    await tts.speak('hi', gender: VoiceGender.female, speed: 1.0);
    expect(localeKey, 'en_US',
        reason: 'Android + web read "locale"');
    expect(languageKey, 'en_US', reason: 'iOS reads "language"');
    tts.dispose();
  });

  test('engine with zero voices still switches audibly via strong pitch',
      () async {
    engineVoices = [];
    final tts = TtsService();
    await tts.init();

    await tts.speak('hi', gender: VoiceGender.male, speed: 1.0);
    final malePitch = lastPitch!;
    await tts.speak('hi', gender: VoiceGender.female, speed: 1.0);
    final femalePitch = lastPitch!;

    expect(malePitch, lessThan(0.8));
    expect(femalePitch, greaterThan(1.2));
    expect((femalePitch - malePitch).abs(), greaterThan(0.5),
        reason: 'pitch gap must be clearly audible');
    tts.dispose();
  });
}
