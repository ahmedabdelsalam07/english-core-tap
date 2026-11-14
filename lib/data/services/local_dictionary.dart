import '../models/word_result.dart';

/// Offline entries for very long words the free dictionary API often cannot
/// answer. Same JSON shape as the API, so [WordResult.fromJson] parses them.
class LocalDictionary {
  const LocalDictionary._();

  static WordResult? lookup(String word) {
    final json = _entries[word.toLowerCase().trim()];
    return json == null ? null : WordResult.fromJson(json);
  }

  static const Map<String, Map<String, dynamic>> _entries = {
    'supercalifragilisticexpialidocious': {
      'word': 'supercalifragilisticexpialidocious',
      'phonetic': '/ˌsuːpəˌkælɪˌfrædʒɪˌlɪstɪkˌekspiˌælɪˈdəʊʃəs/',
      'phonetics': [
        {'text': '/ˌsuːpəˌkælɪˌfrædʒɪˌlɪstɪkˌekspiˌælɪˈdəʊʃəs/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'adjective',
          'definitions': [
            {'definition': 'Extraordinarily good; wonderful.', 'synonyms': ['wonderful', 'fantastic', 'marvellous']},
          ],
        },
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'A nonsense word popularised by the film Mary Poppins, used for something fantastic or indescribable.', 'synonyms': []},
          ],
        },
      ],
    },
    'pneumonoultramicroscopicsilicovolcanoconiosis': {
      'word': 'pneumonoultramicroscopicsilicovolcanoconiosis',
      'phonetic': '/ˌnjuːmənoʊˌʌltrəˌmaɪkrəˌskɒpɪkˌsɪlɪkoʊvɒlˌkeɪnoʊˌkoʊniˈoʊsɪs/',
      'phonetics': [
        {'text': '/ˌnjuːmənoʊˌʌltrəˌmaɪkrəˌskɒpɪkˌsɪlɪkoʊvɒlˌkeɪnoʊˌkoʊniˈoʊsɪs/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'A lung disease caused by inhaling very fine silica dust.', 'synonyms': ['silicosis']},
          ],
        },
      ],
    },
    'antidisestablishmentarianism': {
      'word': 'antidisestablishmentarianism',
      'phonetic': '/ˌæntiˌdɪsɪˌstæblɪʃmənˈteəriənɪzəm/',
      'phonetics': [
        {'text': '/ˌæntiˌdɪsɪˌstæblɪʃmənˈteəriənɪzəm/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'Opposition to the withdrawal of state support from an established church.', 'synonyms': []},
          ],
        },
      ],
    },
    'floccinaucinihilipilification': {
      'word': 'floccinaucinihilipilification',
      'phonetic': '/ˌflɒksɪˌnɔːsɪˌnaɪhɪlɪˌpaɪlɪfɪˈkeɪʃən/',
      'phonetics': [
        {'text': '/ˌflɒksɪˌnɔːsɪˌnaɪhɪlɪˌpaɪlɪfɪˈkeɪʃən/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'The act of estimating something as worthless.', 'synonyms': ['undervaluing']},
          ],
        },
      ],
    },
    'hippopotomonstrosesquippedaliophobia': {
      'word': 'hippopotomonstrosesquippedaliophobia',
      'phonetic': '/ˌhɪpəˌpɒtəˌmɒnstrəˌseskwɪpɪˌdeɪliəˈfəʊbiə/',
      'phonetics': [
        {'text': '/ˌhɪpəˌpɒtəˌmɒnstrəˌseskwɪpɪˌdeɪliəˈfəʊbiə/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'The fear of long words.', 'synonyms': []},
          ],
        },
      ],
    },
    'honorificabilitudinitatibus': {
      'word': 'honorificabilitudinitatibus',
      'phonetic': '/ˌɒnɒˌrɪfɪˌkæbɪlɪˌtjuːdɪnɪˈtɑːtɪbʊs/',
      'phonetics': [
        {'text': '/ˌɒnɒˌrɪfɪˌkæbɪlɪˌtjuːdɪnɪˈtɑːtɪbʊs/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'The state of being able to achieve honours.', 'synonyms': []},
          ],
        },
      ],
    },
    'pseudopseudohypoparathyroidism': {
      'word': 'pseudopseudohypoparathyroidism',
      'phonetic': '/ˌsjuːdəʊˌsjuːdəʊˌhaɪpəʊˌpærəˈθaɪrɔɪdɪzəm/',
      'phonetics': [
        {'text': '/ˌsjuːdəʊˌsjuːdəʊˌhaɪpəʊˌpærəˈθaɪrɔɪdɪzəm/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'An inherited condition that mimics pseudohypoparathyroidism without hormone resistance.', 'synonyms': []},
          ],
        },
      ],
    },
    'incomprehensibilities': {
      'word': 'incomprehensibilities',
      'phonetic': '/ˌɪnkɒmprɪˌhensəˈbɪlɪtiz/',
      'phonetics': [
        {'text': '/ˌɪnkɒmprɪˌhensəˈbɪlɪtiz/', 'audio': ''},
      ],
      'meanings': [
        {
          'partOfSpeech': 'noun',
          'definitions': [
            {'definition': 'Things that cannot be understood or grasped by the mind.', 'synonyms': ['unintelligibilities']},
          ],
        },
      ],
    },
  };
}
