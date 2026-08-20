// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'English Core TaP';

  @override
  String get appBrand => 'ENGLISH CORE';

  @override
  String get appBrandSub => 'MR. THARWAT TAWFIQ';

  @override
  String get appDescription =>
      'An app that helps you learn correct American English pronunciation with Arabic translation and Arabic phonetic transcription.';

  @override
  String get splashTagline => 'English Core TaP';

  @override
  String get splashSub => 'MR. THARWAT TAWFIQ';

  @override
  String get onboardingTitle1 => 'Learn American pronunciation easily';

  @override
  String get onboardingSub1 =>
      'Type any word or sentence and get a clear American pronunciation with its Arabic meaning.';

  @override
  String get onboardingTitle2 => 'Hear clear, natural voices';

  @override
  String get onboardingSub2 =>
      'Listen to words and sentences with a natural American voice, male or female.';

  @override
  String get onboardingTitle3 => 'Translate, pronounce, and save';

  @override
  String get onboardingSub3 =>
      'Translate, pronounce, and save your favorite words to review anytime.';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get loginTitle => 'Welcome';

  @override
  String get loginSubtitle => 'Sign in to your private account to continue';

  @override
  String get loginUsername => 'Username';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get loginLoading => 'Signing in...';

  @override
  String get loginErrorInvalid => 'Username or password is incorrect.';

  @override
  String get loginErrorNetwork =>
      'Could not connect to the server. Check your internet connection and try again.';

  @override
  String get loginErrorBackend =>
      'The secure backend is not configured. Please configure the API server before using the app.';

  @override
  String get loginFieldRequired => 'Please enter username and password.';

  @override
  String get loginSecureNote =>
      'Secure private access. Only authorized accounts can sign in.';

  @override
  String get homeTitle => 'Pronounce English';

  @override
  String get homeAccent => 'in American accent';

  @override
  String get homeSubtitle =>
      'Type a word or sentence and get a clear American pronunciation and its Arabic translation.';

  @override
  String get inputPlaceholder => 'Type English or Arabic text...';

  @override
  String get inputHint => 'e.g. How are you today?';

  @override
  String get inputPaste => 'Paste';

  @override
  String get inputClear => 'Clear';

  @override
  String get inputMic => 'Speak';

  @override
  String get inputMicListening => 'Listening... tap to stop';

  @override
  String get inputEmptyError =>
      'Please type or paste an English word or sentence first.';

  @override
  String get inputOnlyArabicError =>
      'Please enter English text to get pronunciation and translation.';

  @override
  String get mainCta => 'Pronounce & Translate';

  @override
  String get mainCtaLoading1 => 'Analyzing the word...';

  @override
  String get mainCtaLoading2 => 'Preparing pronunciation...';

  @override
  String get mainCtaLoading3 => 'Translating...';

  @override
  String get recentHistory => 'Recent';

  @override
  String get clearHistory => 'Clear';

  @override
  String get tryExamples => 'Try:';

  @override
  String get resultTitle => 'Result';

  @override
  String get resultEnglish => 'English';

  @override
  String get resultArabicPronunciation => 'Arabic Pronunciation';

  @override
  String get resultTranslation => 'Translation';

  @override
  String get resultCopy => 'Copy';

  @override
  String get resultShare => 'Share';

  @override
  String get resultCopied => 'Copied successfully';

  @override
  String get resultFavoriteAdd => 'Saved to favorites';

  @override
  String get resultFavoriteRemove => 'Removed from favorites';

  @override
  String get resultAddFavorite => 'Save to favorites';

  @override
  String get resultAccent => 'American English';

  @override
  String get resultVoice => 'Voice';

  @override
  String get resultSpeed => 'Speed';

  @override
  String get resultPlay => 'Play';

  @override
  String get resultPause => 'Pause';

  @override
  String get resultResume => 'Resume';

  @override
  String get resultReplay => 'Replay';

  @override
  String get resultStop => 'Stop';

  @override
  String get resultAudioError =>
      'Could not play the pronunciation. Please try again.';

  @override
  String get resultTtsUnavailable =>
      'Text-to-speech is not available on this device.';

  @override
  String get speechNotAvailable =>
      'Speech recognition is not available on this device.';

  @override
  String get speechPermissionDenied =>
      'Please allow microphone access to use this feature.';

  @override
  String get speechListening => 'Listening... speak now';

  @override
  String get speechNoResult =>
      'Sorry, I could not hear the words. Please try again.';

  @override
  String get micPermissionTitle => 'Microphone Permission';

  @override
  String get micPermissionMessage =>
      'English Core TaP needs microphone access to convert your speech into English text.';

  @override
  String get micPermissionSettings => 'Open Settings';

  @override
  String get micPermissionCancel => 'Cancel';

  @override
  String get translationError =>
      'Could not translate this text right now. Check your connection and try again.';

  @override
  String get ttsError => 'Could not play the pronunciation. Please try again.';

  @override
  String get phoneticNotAvailable =>
      'Arabic pronunciation could not be generated for this text.';

  @override
  String get networkError =>
      'No internet connection. Please check your connection and try again.';

  @override
  String get serverError =>
      'Something went wrong on the server. Please try again later.';

  @override
  String get rateLimitError =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String get timeoutError => 'The request took too long. Please try again.';

  @override
  String get unknownError => 'Something went wrong. Please try again.';

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get favoritesEmpty => 'You haven\'t added any words to favorites yet.';

  @override
  String get favoritesEmptyHint =>
      'Tap the star on any result to save it here.';

  @override
  String get favoritesDelete => 'Remove';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No history yet.';

  @override
  String get historyEmptyHint => 'Your searches will appear here.';

  @override
  String get historySearch => 'Search history...';

  @override
  String get historyDelete => 'Delete';

  @override
  String get historyDeleteAll => 'Delete all';

  @override
  String get historyDeleteConfirm => 'Delete this item?';

  @override
  String get historyDeleteAllConfirm =>
      'Delete all history? This cannot be undone.';

  @override
  String get historyCancel => 'Cancel';

  @override
  String get historyDeleteYes => 'Delete';

  @override
  String get navHome => 'Home';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navPronounce => 'Speak';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsSystem => 'Automatic';

  @override
  String get settingsDefaultVoice => 'Default Voice';

  @override
  String get settingsMale => 'Male';

  @override
  String get settingsFemale => 'Female';

  @override
  String get settingsAuto => 'Automatic';

  @override
  String get settingsSpeed => 'Pronunciation Speed';

  @override
  String get settingsAccent => 'Accent';

  @override
  String get settingsAccentUs => 'American English';

  @override
  String get settingsArabicPhonetic => 'Arabic Pronunciation';

  @override
  String get settingsArabicPhoneticOn => 'Show Arabic pronunciation in results';

  @override
  String get settingsLanguage => 'Interface Language';

  @override
  String get settingsArabic => 'Arabic';

  @override
  String get settingsEnglish => 'English';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsUsername => 'Username';

  @override
  String get settingsLogout => 'Log Out';

  @override
  String get settingsLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get settingsClearHistory => 'Clear History';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Use';

  @override
  String get settingsAbout => 'About English Core';

  @override
  String get settingsAppVersion => 'Version';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutName => 'ENGLISH CORE';

  @override
  String get aboutSub => 'MR. THARWAT TAWFIQ';

  @override
  String get aboutDescription =>
      'An app that helps you learn correct American English pronunciation with Arabic translation and Arabic phonetic transcription.';

  @override
  String get privacyTitle => 'Privacy Policy';

  @override
  String get privacyBody =>
      'English Core TaP processes the text you enter to provide translation and pronunciation services. Text may be sent to external services (translation and text-to-speech providers) to fulfill your request.\n\nWe do not collect personal information beyond your account credentials, which are managed securely. Your favorites and history are stored locally on your device.\n\nFor any questions, contact the administrator.';

  @override
  String get termsTitle => 'Terms of Use';

  @override
  String get termsBody =>
      'English Core TaP is a private, restricted-access application. Access is granted only to authorized accounts created by the administrator.\n\nYou agree to use the app for personal educational purposes and not to misuse the services. Sharing your credentials is prohibited.\n\nThe content and logo are the property of MR. THARWAT TAWFIQ and may not be reused without permission.';

  @override
  String get footerNote =>
      'Uses Google/Apple speech + real translation services';

  @override
  String get languageSwitched => 'Language updated';

  @override
  String get themeSwitched => 'Theme updated';

  @override
  String get loginExpired => 'Your session has expired. Please sign in again.';

  @override
  String get logoutSuccess => 'Signed out successfully';
}
