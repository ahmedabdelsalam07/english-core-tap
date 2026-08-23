import 'package:flutter_test/flutter_test.dart';
import 'package:english_core_tap/data/services/arabic_phonetic_service.dart';

void main() {
  const service = ArabicPhoneticService();

  test('produces natural Arabic phonetic for common phrases', () {
    expect(service.toArabicPhonetic('how are you'), 'هاو آر يو');
    expect(service.toArabicPhonetic('hello'), 'هَلو');
    expect(service.toArabicPhonetic('good morning'), 'جود مورنينج');
  });

  test('english g is always written with jeem, never qaf', () {
    expect(service.toArabicPhonetic('good'), 'جود');
    expect(service.toArabicPhonetic('good night'), 'جود نايت');
    expect(service.toArabicPhonetic('big'), 'بيج');
    expect(service.toArabicPhonetic('compare'), 'كمبير');
    // engine path too: g -> dʒ -> ج
    expect(service.toArabicPhonetic('gadget').contains('ق'), isFalse);
    expect(service.toArabicPhonetic('gadget').contains('ج'), isTrue);
  });

  test('output never ends on a bare short-vowel mark', () {
    const marks = ['\u064E', '\u0650', '\u064F'];
    for (final word in ['compare', 'better', 'computer', 'water']) {
      final out = service.toArabicPhonetic(word);
      for (final m in marks) {
        expect(out.endsWith(m), isFalse, reason: word);
      }
    }
    // IPA hint missing the final r still yields readable letters
    final hinted = service.toArabicPhonetic(
      'compare',
      ipaHints: {'compare': 'kəmˈpɛə'},
    );
    for (final m in marks) {
      expect(hinted.endsWith(m), isFalse);
    }
  });

  test('uses IPA to produce accurate diacritic transcription', () {
    // /ˈduːɪŋ/ -> دوينج
    expect(service.toArabicPhonetic('doing'), 'دوينج');
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