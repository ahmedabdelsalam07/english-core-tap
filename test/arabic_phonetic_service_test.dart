import 'package:flutter_test/flutter_test.dart';
import 'package:english_core_tap/data/services/arabic_phonetic_service.dart';

void main() {
  const service = ArabicPhoneticService();

  test('produces natural Arabic phonetic for common phrases', () {
    expect(service.toArabicPhonetic('how are you'), 'هاو آر يو');
    expect(service.toArabicPhonetic('hello'), 'هَلو');
    expect(service.toArabicPhonetic('good morning'), 'قود مورنينج');
  });

  test('uses IPA to produce accurate diacritic transcription', () {
    // /ˈduːɪŋ/ -> دووِنغ
    expect(service.toArabicPhonetic('doing'), 'دووِنغ');
    // /ˈbjuːtɪfəl/ -> بيوتِفُل
    expect(service.toArabicPhonetic('beautiful'), 'بيوتِفُل');
    // /ˈkʌmftərbəl/ -> كَمفْتَرَبُل
    expect(service.toArabicPhonetic('comfortable'), 'كَمفْتَرَبُل');
  });

  test('uses provided IPA hints when available', () {
    // 'better' is not in the override dictionary, so the IPA hint is used.
    final result = service.toArabicPhonetic(
      'better',
      ipaHints: {'better': 'ˈbɛtər'},
    );
    expect(result, isNotEmpty);
    expect(result.contains('ر'), isTrue);
  });

  test('empty input returns empty string', () {
    expect(service.toArabicPhonetic('   '), '');
  });

  test('nurse vowels keep their vowel sound (earth, work)', () {
    // earth /ɜːrθ/ -> أَرث (not رث)
    expect(service.toArabicPhonetic('earth'), 'أَرث');
    expect(service.toArabicPhonetic('earth science'), contains('أَرث'));
    expect(service.toArabicPhonetic('earth science'), contains('ساي'));
    // work /wɝk/ -> وارك (not رك)
    expect(service.toArabicPhonetic('work'), 'وارك');
  });

  test('science family uses the sayn form', () {
    expect(service.toArabicPhonetic('science'), 'سايْنس');
    expect(service.toArabicPhonetic('scientist'), 'سايْنتِست');
  });

  test('grapheme-to-IPA engine emits consonants', () {
    final ipa = service.graphemeToIpa('cat');
    expect(ipa, contains('æ'));
    expect(ipa, contains('k'));
    expect(ipa, contains('t'));
  });

  test('stripDiacritics removes short-vowel marks', () {
    final stripped = service.stripDiacritics('كَمفْتَرَبُل');
    expect(stripped.contains('\u064E'), isFalse);
    expect(stripped.contains('\u0650'), isFalse);
    expect(stripped, 'كمفتربل');
  });
}