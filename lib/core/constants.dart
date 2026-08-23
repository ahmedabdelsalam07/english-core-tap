class Constants {
  static const String appName = 'English Core TaP';
  static const String brand = 'ENGLISH CORE';
  static const String brandSub = 'MR. THARWAT TAWFIQ';
  /// Bump on every release (must match the GitHub release tag, without 'v').
  static const String appVersion = '1.0.31';
  static const String githubRepo =
      'ahmedabdelsalam07/english-core-tap';
  static const String websiteUrl = 'https://www.quickpronounce.site/';
  static const String dictionaryApiBase =
      'https://api.dictionaryapi.dev/api/v2/entries/en/';
  static const int maxHistoryItems = 100;
  static const int maxFavoritesItems = 200;
  static const int maxInputChars = 300;
  static const Duration apiTimeout = Duration(seconds: 20);

  // Accents (architecture-ready for future: British, Australian, Canadian)
  static const String accentAmerican = 'en-US';
  static const List<String> supportedAccents = [accentAmerican];
}