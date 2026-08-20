import 'dart:convert';

/// Arabic Phonetic Transcription Service.
///
/// Converts English text into a natural Arabic phonetic representation
/// based on actual American English pronunciation. It does NOT do
/// letter-by-letter mapping. Instead:
///  1. A curated pronunciation dictionary handles common words/phrases.
///  2. Otherwise, real IPA phonemes (from the dictionary service or a
///     built-in grapheme-to-phoneme engine) are mapped to Arabic script
///     with light diacritics reflecting short vowels.
class ArabicPhoneticService {
  const ArabicPhoneticService();

  /// Converts [text] to Arabic phonetic text.
  ///
  /// [ipaHints] optionally provides per-word IPA (American English) aligned
  /// to the words in [text]. When available, they are used directly.
  String toArabicPhonetic(String text, {List<String>? ipaHints}) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      final raw = words[i];
      final clean = raw.replaceAll(RegExp("[^A-Za-z'-]"), '');
      if (clean.isEmpty) continue;

      final key = clean.toLowerCase();
      final override = _overrides[key];
      if (override != null) {
        buffer.write(override);
      } else {
        final ipa = (ipaHints != null && i < ipaHints.length &&
                ipaHints[i].isNotEmpty)
            ? ipaHints[i]
            : graphemeToIpa(clean);
        buffer.write(_convertIpa(ipa));
      }
      if (i < words.length - 1) buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  /// Simplified grapheme-to-phoneme engine for American English.
  /// Outputs an IPA-like string consumed by [_convertIpa].
  String graphemeToIpa(String word) {
    final w = word.toLowerCase();
    final out = StringBuffer();
    int i = 0;
    final n = w.length;

    String sub(int len) =>
        i + len <= n ? w.substring(i, i + len) : '';

    bool nextConsonant() {
      var j = i;
      while (j < n && !'aeiouy'.contains(w[j])) {
        j++;
      }
      return j >= n;
    }

    while (i < n) {
      final s2 = sub(2);
      final s3 = sub(3);
      final s4 = sub(4);
      final s6 = sub(6);

      // Multi-letter vowel & r-colored sequences
      if (s6 == 'eigh') {
        out.write('eɪ');
        i += 4;
        continue;
      }
      if (s4 == 'tion') {
        out.write('ʃ');
        i += 3;
        continue;
      }
      if (s4 == 'sion') {
        out.write('ʒ');
        i += 3;
        continue;
      }
      if (s4 == 'ight') {
        out.write('aɪ');
        i += 4;
        continue;
      }
      if (s4 == 'ough') {
        out.write('ʌ');
        i += 4;
        continue;
      }
      if (s3 == 'tion' || s3 == 'sion' || s3 == 'ssi') {
        out.write('ʃ');
        i += 3;
        continue;
      }
      if (s3 == 'ure') {
        out.write('ɚ');
        i += 2;
        continue;
      }
      if (s3 == 'tch') {
        out.write('tʃ');
        i += 3;
        continue;
      }
      if (s3 == 'dge') {
        out.write('dʒ');
        i += 3;
        continue;
      }
      if (s2 == 'th') {
        out.write('θ');
        i += 2;
        continue;
      }
      if (s2 == 'sh') {
        out.write('ʃ');
        i += 2;
        continue;
      }
      if (s2 == 'ch') {
        out.write('tʃ');
        i += 2;
        continue;
      }
      if (s2 == 'ph') {
        out.write('f');
        i += 2;
        continue;
      }
      if (s2 == 'ng') {
        out.write('ŋ');
        i += 2;
        continue;
      }
      if (s2 == 'ck' || s2 == 'qu') {
        out.write('k');
        i += 2;
        continue;
      }
      if (s2 == 'wh') {
        out.write('w');
        i += 2;
        continue;
      }
      if (s2 == 'kn' && i == 0) {
        out.write('n');
        i += 2;
        continue;
      }
      if (s2 == 'wr' && i == 0) {
        out.write('r');
        i += 2;
        continue;
      }
      if (s2 == 'gh') {
        i += 2;
        continue; // silent
      }

      // r-colored vowels
      if (s2 == 'ar') {
        out.write('ɑr');
        i += 2;
        continue;
      }
      if (s2 == 'or') {
        out.write('ɔr');
        i += 2;
        continue;
      }
      if (s2 == 'er') {
        out.write('ɚ');
        i += 2;
        continue;
      }
      if (s2 == 'ir' || s2 == 'ur') {
        out.write('ɝ');
        i += 2;
        continue;
      }

      // Long vowels & diphthongs
      if (s2 == 'ee' || s2 == 'ea') {
        out.write('iː');
        i += 2;
        continue;
      }
      if (s2 == 'oo') {
        out.write('uː');
        i += 2;
        continue;
      }
      if (s2 == 'ou' || s2 == 'ow') {
        out.write('aʊ');
        i += 2;
        continue;
      }
      if (s2 == 'ai' || s2 == 'ay') {
        out.write('eɪ');
        i += 2;
        continue;
      }
      if (s2 == 'oa') {
        out.write('oʊ');
        i += 2;
        continue;
      }
      if (s2 == 'ie') {
        out.write('iː');
        i += 2;
        continue;
      }
      if (s2 == 'ue') {
        out.write('juː');
        i += 2;
        continue;
      }
      if (s2 == 'oy' || s2 == 'oi') {
        out.write('ɔɪ');
        i += 2;
        continue;
      }

      final ch = w[i];

      // Magic-E long vowel: VCe
      if ('aeiou'.contains(ch) &&
          i + 2 < n &&
          !'aeiou'.contains(w[i + 1]) &&
          w[i + 2] == 'e' &&
          nextConsonant() &&
          sub(2) != 'ue') {
        if (ch == 'a') {
          out.write('eɪ');
        } else if (ch == 'i') {
          out.write('aɪ');
        } else if (ch == 'o') {
          out.write('oʊ');
        } else if (ch == 'e') {
          out.write('iː');
        } else {
          out.write('juː');
        }
        i++;
        continue;
      }

      // Short vowels & consonants
      if (ch == 'a') {
        out.write('æ');
      } else if (ch == 'e') {
        out.write('ɛ');
      } else if (ch == 'i') {
        out.write('ɪ');
      } else if (ch == 'o') {
        out.write('ɑ');
      } else if (ch == 'u') {
        out.write('ʌ');
      } else if (ch == 'y') {
        out.write('ɪ');
      } else if (ch == 'c' || ch == 'q') {
        out.write('k');
      } else if (ch == 'x') {
        out.write('ks');
      } else if (ch == 'j') {
        out.write('dʒ');
      } else if (ch == 'g') {
        out.write('g');
      } else {
        out.write(ch);
      }
      i++;
    }
    return out.toString();
  }

  static const Map<String, String> _overrides = {
    // Common phrases (plain, natural Arabic script)
    'how are you': 'هاو آر يو',
    'how are you doing': 'هاو آر يو دوونغ',
    'how are you today': 'هاو آر يو توداي',
    'how are you doing today': 'هاو آر يو دووِنغ توداي',
    'thank you': 'ثانك يو',
    'good morning': 'قود مورنينج',
    'good evening': 'قود إيفنينج',
    'good night': 'قود نايت',
    'nice to meet you': 'نايس تو ميت يو',
    'see you later': 'سي يو ليتر',
    'i love you': 'آي لاف يو',
    'you are welcome': 'يو آر ويلكم',
    'i am fine': 'آي آم فاين',
    'what is your name': 'وات إز يور نيم',
    'where are you from': 'وير آر يو فروم',
    'how old are you': 'هاو أولد آر يو',
    'can you help me': 'كان يو هلب مي',
    'i do not understand': 'آي دُو نوت أندرساند',
    'please speak slowly': 'بليز سبيبك سلوولي',
    'what time is it': 'وات تايم إز إت',
    // Common words
    'hello': 'هَلو',
    'hi': 'هاي',
    'hey': 'هي',
    'world': 'وورلد',
    'school': 'سكول',
    'apple': 'أَبل',
    'america': 'أمريكا',
    'american': 'أمريكن',
    'english': 'إنجليش',
    'arabic': 'عربي',
    'morning': 'مورنينج',
    'good': 'قود',
    'book': 'بوك',
    'love': 'لاف',
    'welcome': 'ويلكم',
    'please': 'بليز',
    'sorry': 'سوري',
    'friend': 'فريند',
    'family': 'فاميلي',
    'water': 'ووتر',
    'coffee': 'كافي',
    'tea': 'تي',
    'bread': 'برايد',
    'house': 'هاوس',
    'home': 'هوم',
    'car': 'كار',
    'day': 'داي',
    'night': 'نايت',
    'time': 'تايم',
    'name': 'نيم',
    'phone': 'فون',
    'computer': 'كمبيوتر',
    'internet': 'إنترنت',
    'money': 'ماني',
    'peace': 'بيز',
    'like': 'لايك',
    'think': 'ثينك',
    'want': 'وانت',
    'know': 'نوو',
    'make': 'مايك',
    'this': 'ذيس',
    'that': 'ذات',
    'with': 'ويذ',
    'from': 'فروم',
    'your': 'يور',
    'goodbye': 'جودباي',
    'bye': 'باي',
    'see': 'سي',
    'soon': 'سون',
    'miss': 'ميس',
    'okay': 'أوكي',
    'yes': 'يس',
    'no': 'نو',
    'maybe': 'مايبي',
    'always': 'أولويز',
    'never': 'نيفر',
    'again': 'أجين',
    'beautiful': 'بيوتِفُل',
    'great': 'جريت',
    'perfect': 'بيرفكت',
    'accent': 'أكسنت',
    'pronounce': 'برناونس',
    'pronunciation': 'برونانسييشن',
    'how': 'هاو',
    'are': 'آر',
    'you': 'يو',
    'doing': 'دووِنغ',
    'today': 'توداي',
    'comfortable': 'كَمفْتَرَبُل',
    'thank': 'ثانك',
    'thanks': 'ثانكس',
    'sure': 'شور',
    'not': 'نات',
    'what': 'وات',
    'why': 'واي',
    'who': 'هو',
    'where': 'وير',
    'when': 'وين',
    'which': 'ويتش',
    'very': 'فيري',
    'much': 'ماتش',
    'many': 'ماني',
    'little': 'ليتل',
    'big': 'بِق',
    'small': 'سومول',
    'happy': 'هابي',
    'sad': 'ساد',
    'bad': 'باد',
    'new': 'نيو',
    'old': 'أولد',
    'young': 'يانج',
    'fast': 'فاست',
    'slow': 'سلو',
    'man': 'مان',
    'woman': 'وومان',
    'boy': 'بوي',
    'girl': 'جيرل',
    'teacher': 'تيتشر',
    'student': 'ستودنت',
    'father': 'فاذر',
    'mother': 'ماذر',
    'brother': 'براذر',
    'sister': 'سيستر',
    'eat': 'إيت',
    'drink': 'درينك',
    'sleep': 'سليب',
    'walk': 'واك',
    'run': 'ران',
    'talk': 'توك',
    'listen': 'ليسن',
    'read': 'ريد',
    'write': 'رايت',
    'learn': 'ليرن',
    'work': 'ويرك',
    'play': 'بلاي',
    'study': 'ستادي',
    'travel': 'ترافل',
    'city': 'سيتي',
    'country': 'كانتري',
    'food': 'فود',
    'weather': 'ويذر',
    'hot': 'هات',
    'cold': 'كولد',
    'sun': 'سان',
    'rain': 'رين',
    'snow': 'سنو',
    'number': 'نمبر',
    'color': 'كولر',
    'question': 'كويششن',
    'answer': 'أنسر',
    'language': 'لانجواج',
    'people': 'بيبل',
    'feeling': 'فيليغ',
  };

  static const Map<String, String> _consonants = {
    'p': 'ب', 'b': 'ب', 't': 'ت', 'd': 'د', 'k': 'ك', 'g': 'ج',
    'm': 'م', 'n': 'ن', 'ŋ': 'نغ', 'f': 'ف', 'v': 'ف', 'θ': 'ث',
    'ð': 'ذ', 's': 'س', 'z': 'ز', 'ʃ': 'ش', 'ʒ': 'ج', 'h': 'ه',
    'r': 'ر', 'l': 'ل', 'j': 'ي', 'w': 'و', 'tʃ': 'تش', 'dʒ': 'ج',
  };

  static const Map<String, String> _shortVowelDiacritic = {
    'ɪ': '\u0650', // kasra
    'ʊ': '\u064F', // damma
    'ə': '\u064F', // damma (weak schwa)
    'ɛ': '\u064E', // fatha
    'æ': '\u064E', // fatha
    'ʌ': '\u064E', // fatha
    'ɑ': '\u064E', // fatha
    'ɔ': '\u064E', // fatha
  };

  static const Map<String, String> _wordInitialShort = {
    'ɪ': 'إِ',
    'ʊ': 'أُ',
    'ə': 'أُ',
    'ɛ': 'أَ',
    'æ': 'أَ',
    'ʌ': 'أَ',
    'ɑ': 'أَ',
    'ɔ': 'أَ',
  };

  static const Map<String, String> _longVowelLetter = {
    'iː': 'ي',
    'uː': 'و',
    'ɔː': 'او',
    'ɑː': 'ا',
    'ɚ': 'ر',
    'ɝ': 'ر',
    'ər': 'ر',
    'ɑr': 'آر',
    'ɔr': 'اور',
    'eɪ': 'ي',
    'oʊ': 'و',
    'aɪ': 'اي',
    'aʊ': 'او',
    'ɔɪ': 'أوي',
  };

  static const List<String> _ipaTokens = [
    'tʃ', 'dʒ', 'aɪ', 'aʊ', 'ɔɪ', 'eɪ', 'oʊ', 'iː', 'uː', 'ɔː', 'ɑː',
    'ɚ', 'ɝ', 'ər', 'ɑr', 'ɔr', 'ʃ', 'ʒ', 'ŋ', 'θ', 'ð', 'æ', 'ɔ', 'ʌ',
    'ə', 'ɛ', 'ɪ', 'ʊ', 'ɑ', 'i', 'u', 'e', 'o',
    'p', 'b', 't', 'd', 'k', 'g', 'm', 'n', 'f', 'v', 's', 'z', 'h',
    'r', 'l', 'j', 'w', 'c', 'x',
  ];

  String _convertIpa(String raw) {
    var s = raw.trim();
    s = s.replaceAll('ˈ', '').replaceAll('ˌ', '').replaceAll('.', '');
    final tokens = _tokenizeIpa(s);
    final buffer = StringBuffer();
    var prevWasConsonant = false;
    for (final t in tokens) {
      final consonant = _consonants[t];
      if (consonant != null) {
        buffer.write(consonant);
        prevWasConsonant = true;
        continue;
      }
      final shortD = _shortVowelDiacritic[t];
      if (shortD != null) {
        if (prevWasConsonant && buffer.isNotEmpty) {
          buffer.write(shortD);
        } else {
          buffer.write(_wordInitialShort[t] ?? 'أَ');
        }
        prevWasConsonant = false;
        continue;
      }
      final longL = _longVowelLetter[t];
      if (longL != null) {
        buffer.write(longL);
        prevWasConsonant = false;
      }
    }
    return buffer.toString();
  }

  List<String> _tokenizeIpa(String s) {
    final out = <String>[];
    int i = 0;
    while (i < s.length) {
      var matched = false;
      for (final tok in _ipaTokens) {
        if (s.startsWith(tok, i)) {
          out.add(tok);
          i += tok.length;
          matched = true;
          break;
        }
      }
      if (!matched) {
        // single leftover char (e.g. length mark handled above)
        i++;
      }
    }
    return out;
  }

  String stripDiacritics(String text) {
    final chars = text.split('');
    return chars
        .where((c) => !'\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652'
            .contains(c))
        .join();
  }
}

/// JSON cache helper kept for parity with storage architecture.
class PhoneticCacheEntry {
  final String text;
  final String result;
  const PhoneticCacheEntry({required this.text, required this.result});

  Map<String, dynamic> toJson() => {'text': text, 'result': result};

  factory PhoneticCacheEntry.fromJson(Map<String, dynamic> json) =>
      PhoneticCacheEntry(
        text: json['text'] as String? ?? '',
        result: json['result'] as String? ?? '',
      );

  String encode() => jsonEncode(toJson());
}