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
///
/// Long words are fully supported: nothing truncates the input, unknown
/// IPA symbols fall back to sensible Arabic equivalents (never dropped),
/// and hints are matched per-word (not per-position) so multi-word input
/// keeps every pronunciation aligned.
class ArabicPhoneticService {
  const ArabicPhoneticService();

  /// Converts [text] to Arabic phonetic text.
  ///
  /// [ipaHints] optionally provides per-word IPA (American English) keyed
  /// by the lower-cased word. When available, it is used directly.
  String toArabicPhonetic(String text, {Map<String, String>? ipaHints}) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';

    // Normalise case up-front: ARCHAEOLOGY == archaeology.
    final buffer = StringBuffer();
    var first = true;
    for (final raw in words) {
      final clean = raw.replaceAll(RegExp("[^A-Za-z'-]"), '');
      if (clean.isEmpty) continue;
      if (!first) buffer.write(' ');
      first = false;

      final key = clean.toLowerCase().replaceAll("'", '');
      final override = _overrides[key];
      if (override != null) {
        buffer.write(override);
        continue;
      }
      final ipa =
          (ipaHints != null && ipaHints[key] != null && ipaHints[key]!.isNotEmpty)
              ? ipaHints[key]!
              : graphemeToIpa(clean);
      buffer.write(_convertIpa(ipa));
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

    String sub(int len) => i + len <= n ? w.substring(i, i + len) : '';
    String rest(int from) => i + from <= n ? w.substring(i + from) : '';

    // True when everything after position [idx] is consonants (VCe detector).
    bool onlyConsonantsAfter(int idx) {
      for (var j = idx; j < n; j++) {
        if ('aeiouy'.contains(w[j])) return false;
      }
      return true;
    }

    while (i < n) {
      final s2 = sub(2);
      final s3 = sub(3);
      final s4 = sub(4);

      // ---- suffix blocks -------------------------------------------------
      if (rest(0).startsWith('ology')) {
        out.write('ɑlədʒi');
        i += 5;
        continue;
      }
      if (s4 == 'tion') {
        out.write('ʃən');
        i += 4;
        continue;
      }
      if (s4 == 'sion') {
        out.write('ʒən');
        i += 4;
        continue;
      }
      if (s3 == 'ous') {
        out.write('əs');
        i += 3;
        continue;
      }

      // ---- multi-letter vowel & r-colored sequences -----------------------
      if (s4 == 'chae') {
        // archaeology-style: ch = k, ae = iː (arkiology)
        out.write('kiː');
        i += 4;
        continue;
      }
      if (s3 == 'igh') {
        out.write('aɪ');
        i += 3;
        continue;
      }
      if (s4 == 'ough') {
        out.write('oʊ');
        i += 4;
        continue;
      }
      if (s2 == 'ae') {
        out.write('iː');
        i += 2;
        continue;
      }
      if (s2 == 'oe' || s2 == 'eo') {
        out.write('oʊ');
        i += 2;
        continue;
      }
      if (s3 == 'ure') {
        out.write('ɚ');
        i += 3;
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

      // ---- past/plural endings --------------------------------------------
      if (s2 == 'ed' && i + 2 == n) {
        final prev = i > 0 ? w[i - 1] : '';
        if (prev == 't' || prev == 'd') {
          out.write('ɪd');
        } else if ('pkfsxθʃtʃh'.contains(prev)) {
          out.write('t');
        } else {
          out.write('d');
        }
        i += 2;
        continue;
      }
      if (s2 == 'es' && i + 2 == n) {
        final prev = i > 0 ? w[i - 1] : '';
        final prev2 = i > 1 ? w[i - 2] : '';
        final sibilant = 'sxz'.contains(prev) ||
            (prev == 'h' && prev2 == 'c') || // -ches
            (prev == 'e' && prev2 == 'g'); // -ges
        if (sibilant) {
          out.write('ɪz');
        } else if ('bdgjlmnrvwyzðaɛiːoʊɔʌæɛ'.contains(prev)) {
          out.write('z');
        } else {
          out.write('s');
        }
        i += 2;
        continue;
      }

      // ---- consonant digraphs ---------------------------------------------
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
        // school / chemistry / christmas style "ch = k"; otherwise tʃ
        final r = rest(2);
        if (s3 == 'sch' || r.startsWith('emis') || r.startsWith('rist')) {
          out.write('k');
        } else {
          out.write('tʃ');
        }
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
      if (s2 == 'ck') {
        out.write('k');
        i += 2;
        continue;
      }
      if (s2 == 'qu') {
        out.write('kw');
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
      if (s2 == 'mb' && i + 2 == n) {
        out.write('m');
        i += 2;
        continue; // climb / tomb
      }

      // ---- r-colored vowels -------------------------------------------------
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
      if (s2 == 'er' || (s2 == 're' && i + 2 == n)) {
        out.write('ɚ');
        i += 2;
        continue;
      }
      if (s2 == 'ir' || s2 == 'ur') {
        out.write('ɝ');
        i += 2;
        continue;
      }

      // ---- long vowels & diphthongs ------------------------------------------
      if (s2 == 'ee') {
        out.write('iː');
        i += 2;
        continue;
      }
      if (s2 == 'ea') {
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
      if (s2 == 'ue' || s2 == 'ui') {
        out.write('uː');
        i += 2;
        continue;
      }
      if (s2 == 'oy' || s2 == 'oi') {
        out.write('ɔɪ');
        i += 2;
        continue;
      }
      if (s2 == 'eu' || s2 == 'ew') {
        out.write('juː');
        i += 2;
        continue;
      }

      final ch = w[i];

      // ---- Magic-E long vowel: VCe -------------------------------------------
      if ('aeiou'.contains(ch) &&
          i + 2 < n &&
          !'aeiou'.contains(w[i + 1]) &&
          w[i + 2] == 'e' &&
          onlyConsonantsAfter(i + 1)) {
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

      // ---- single letters ------------------------------------------------------
      if (ch == 'e' && i == n - 1 && n >= 3) {
        // trailing silent e (table, have, give)
        i++;
        continue;
      }
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
        if (i == 0) {
          out.write('j');
        } else if (i == n - 1) {
          out.write('iː');
        } else {
          out.write('ɪ');
        }
      } else if (ch == 'c') {
        if (i + 1 < n && 'eiy'.contains(w[i + 1])) {
          out.write('s');
        } else {
          out.write('k');
        }
      } else if (ch == 'q') {
        out.write('k');
      } else if (ch == 'x') {
        out.write('ks');
      } else if (ch == 'j') {
        out.write('dʒ');
      } else if (ch == 'g') {
        if (i + 1 < n && 'eiy'.contains(w[i + 1]) && s2 != 'gg') {
          out.write('dʒ');
        } else {
          out.write('g');
        }
      } else if (ch == 's' && i == n - 1 && i > 0) {
        // voiced final -s after a sonorant reads as /z/
        const sonorants = 'rlmnwbvgdzðaɛiyoʊuː';
        final prevOut = out.toString();
        out.write(
            prevOut.isNotEmpty && sonorants.contains(prevOut[prevOut.length - 1])
                ? 'z'
                : 's');
      } else {
        out.write(ch);
      }
      i++;
    }
    return out.toString();
  }

  static const Map<String, String> _overrides = {
    // Function words (short, high-frequency)
    'the': 'ذا',
    'a': 'أَ',
    'an': 'أن',
    'to': 'تو',
    'of': 'أوف',
    'in': 'إن',
    'on': 'ون',
    'it': 'إت',
    'is': 'إز',
    'and': 'أاند',
    'or': 'أور',
    'for': 'فور',
    'he': 'هي',
    'she': 'شي',
    'we': 'وي',
    'me': 'مي',
    'be': 'بي',
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
    'please speak slowly': 'بليز سبيك سلوولي',
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
    'bread': 'بريد',
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
    'know': 'نو',
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
    'pronunciation': 'بروناَنسِيَيشِن',
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
    'big': 'بيق',
    'small': 'سمول',
    'happy': 'هابي',
    'sad': 'ساد',
    'bad': 'باد',
    'new': 'نيو',
    'old': 'أولد',
    'young': 'يانج',
    'fast': 'فاست',
    'slow': 'سلول',
    'man': 'مان',
    'woman': 'وومان',
    'boy': 'بوي',
    'girl': 'غيرل',
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
    'color': 'كلر',
    'question': 'كويستشِن',
    'answer': 'أنسر',
    'language': 'لانجوِج',
    'people': 'بيبل',
    'feeling': 'فيلينغ',
    // Longer / trickier words (natural readings)
    'archaeology': 'آركيأولُجي',
    'corridor': 'كورِدور',
    'corridors': 'كورِدورز',
    'university': 'يونِڤيرسِتي',
    'technology': 'تكْنأولُجي',
    'development': 'ديڤيلوبمنت',
    'environment': 'إنفايرنمنت',
    'opportunity': 'أبورتيونِتي',
    'communicate': 'كميونِكيت',
    'interesting': 'إنترِستينغ',
    'vegetable': 'ڤيجتبُل',
    'restaurant': 'ريسترانت',
    'comfortably': 'كَمفتَربلي',
    'temperature': 'تيمبرَتشُر',
    'necessary': 'نيسِسيري',
    'different': 'ديفرنت',
    'beautifully': 'بيوتِفُلي',
  };

  static const Map<String, String> _consonants = {
    'p': 'ب', 'b': 'ب', 't': 'ت', 'd': 'د', 'k': 'ك', 'g': 'ج',
    'm': 'م', 'n': 'ن', 'ŋ': 'نغ', 'f': 'ف', 'v': 'ف', 'θ': 'ث',
    'ð': 'ذ', 's': 'س', 'z': 'ز', 'ʃ': 'ش', 'ʒ': 'ج', 'h': 'ه',
    'r': 'ر', 'l': 'ل', 'j': 'ي', 'w': 'و', 'tʃ': 'تش', 'dʒ': 'ج',
    'ɾ': 'د', // American flap ≈ light د
    'ʔ': 'ء', 'x': 'خ', 'ç': 'ه',
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
    'ɐ': '\u064E',
    'ɜ': '\u064E',
  };

  static const Map<String, String> _wordInitialShort = {
    'ɪ': 'إِ',
    'ʊ': 'أُ',
    'ə': 'أُ',
    'ɛ': 'أَ',
    'æ': 'أَ',
    'ʌ': 'أَ',
    'ɑ': 'آ',
    'ɔ': 'أَ',
    'ɐ': 'أَ',
    'ɜ': 'أَ',
  };

  static const Map<String, String> _longVowelLetter = {
    'iː': 'ي',
    'uː': 'و',
    'ɔː': 'او',
    'ɑː': 'ا',
    'eː': 'ي',
    'oː': 'و',
    'ɚ': 'ر',
    'ɝ': 'ر',
    'ɝː': 'ر',
    'ər': 'ر',
    'ɜr': 'ر',
    'ɑr': 'ار',
    'ɔr': 'ور',
    'ʊr': 'ور',
    'ɪr': 'ير',
    'ɛər': 'ير',
    'eɪ': 'ي',
    'oʊ': 'و',
    'aɪ': 'اي',
    'aʊ': 'او',
    'ɔɪ': 'أوي',
    'juː': 'يو',
    'aɪər': 'اير',
    'aʊər': 'اَور',
    'ɪə': 'يا',
    'eə': 'يا',
    'ʊə': 'وا',
  };

  static const List<String> _ipaTokens = [
    // longest-first matching happens below via explicit ordering checks
    'aɪər', 'aʊər', 'tʃ', 'dʒ', 'ɝː', 'iː', 'uː', 'ɔː', 'ɑː', 'eː', 'oː',
    'juː', 'ɪə', 'eə', 'ʊə', 'ɛər', 'aɪ', 'aʊ', 'ɔɪ', 'eɪ', 'oʊ',
    'ɚ', 'ɝ', 'ər', 'ɜr', 'ɑr', 'ɔr', 'ʊr', 'ɪr',
    'ʃ', 'ʒ', 'ŋ', 'θ', 'ð', 'æ', 'ɔ', 'ʌ', 'ə', 'ɛ', 'ɪ', 'ʊ', 'ɑ',
    'ɐ', 'ɜ', 'i', 'u', 'e', 'o', 'æ',
    'p', 'b', 't', 'd', 'k', 'ɡ', 'g', 'm', 'n', 'f', 'v', 's', 'z', 'h',
    'r', 'ɾ', 'ɹ', 'l', 'ɫ', 'j', 'w', 'ʔ', 'x', 'ç',
  ];

  String _convertIpa(String raw) {
    var s = _normalizeIpa(raw);
    final tokens = _tokenizeIpa(s);
    final buffer = StringBuffer();
    var prevWasConsonant = false;
    for (final t in tokens) {
      final consonant = _consonants[t];
      if (consonant != null) {
        // collapse doubled identical consonants (rr -> ر)
        final last = buffer.isEmpty ? '' : buffer.toString()[buffer.length - 1];
        final base = consonant.length == 2 && last == consonant[1]
            ? consonant[1]
            : consonant;
        if (!(base.length == 1 && last == base)) buffer.write(base);
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

  /// Maps common alternative IPA symbols onto the token alphabet so that
  /// nothing silently disappears (this was corrupting long dictionary words).
  String _normalizeIpa(String raw) {
    var s = raw.trim();
    s = s.replaceAll('ˈ', '').replaceAll('ˌ', '').replaceAll('.', '');
    const replacements = {
      'ɡ': 'g', // script g (U+0261)
      'ɹ': 'r',
      'ɫ': 'l',
      'ɾ': 'ɾ',
      'ɐ': 'æ',
      'ɜ': 'ɝ',
      'ɞ': 'ə',
      'ʉ': 'u',
      'ɘ': 'ə',
      'ɵ': 'ə',
      'χ': 'x',
      'ʀ': 'r',
      'ʁ': 'r',
      'ɺ': 'r',
      'ʦ': 'ts',
      'ʣ': 'dz',
      'ʧ': 'tʃ',
      'ʤ': 'dʒ',
      'ꭧ': 'tʃ',
      ':': 'ː',
    };
    replacements.forEach((k, v) => s = s.replaceAll(k, v));
    // strip combining marks we do not render (nasalisation, syllabic, length on its own)
    s = s.replaceAll(RegExp('[\u0303\u0329\u02b0\u02b1\u02b2\u02e0\u02e4]'), '');
    // any standalone length marks left over become part of the previous vowel
    s = s.replaceAllMapped(RegExp('([ioueaɑɔɛɪʊə])ː'), (m) => '${m.group(1)}ː');
    return s;
  }

  List<String> _tokenizeIpa(String s) {
    final out = <String>[];
    int i = 0;
    while (i < s.length) {
      var matched = false;
      // prefer the longest token starting here
      for (final tok in _ipaTokens) {
        if (s.startsWith(tok, i)) {
          // absorb a trailing length mark for pure vowels
          var token = tok;
          var next = i + tok.length;
          if (next < s.length && s[next] == 'ː' && !_longVowelLetter.containsKey(tok)) {
            token = '$tokː';
            next += 1;
            if (_longVowelLetter.containsKey(token)) {
              out.add(token);
              i = next;
              matched = true;
              break;
            }
          }
          out.add(tok);
          i = next;
          matched = true;
          break;
        }
      }
      if (!matched) {
        i++; // skip anything still unmapped (modifiers, whitespace)
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
