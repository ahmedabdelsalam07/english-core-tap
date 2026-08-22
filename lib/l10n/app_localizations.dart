import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'English Core TaP'**
  String get appName;

  /// No description provided for @appBrand.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH CORE'**
  String get appBrand;

  /// No description provided for @appBrandSub.
  ///
  /// In en, this message translates to:
  /// **'MR. THARWAT TAWFIQ'**
  String get appBrandSub;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'An app that helps you learn correct American English pronunciation with Arabic translation and Arabic phonetic transcription.'**
  String get appDescription;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'English Core TaP'**
  String get splashTagline;

  /// No description provided for @splashSub.
  ///
  /// In en, this message translates to:
  /// **'MR. THARWAT TAWFIQ'**
  String get splashSub;

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to English Core'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSub1.
  ///
  /// In en, this message translates to:
  /// **'Type any word or sentence and get a clear American pronunciation with its Arabic meaning.'**
  String get onboardingSub1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'You Are Safe'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSub2.
  ///
  /// In en, this message translates to:
  /// **'A safe place to learn and speak with confidence, without fear.'**
  String get onboardingSub2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'English Core'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSub3.
  ///
  /// In en, this message translates to:
  /// **'Your safe way to improve your language.'**
  String get onboardingSub3;

  /// No description provided for @onboardingBrandAr.
  ///
  /// In en, this message translates to:
  /// **'انجلشكور'**
  String get onboardingBrandAr;

  /// No description provided for @onboardingOwnerAr.
  ///
  /// In en, this message translates to:
  /// **'ثروت توفيق'**
  String get onboardingOwnerAr;

  /// No description provided for @onboardingBrandEn.
  ///
  /// In en, this message translates to:
  /// **'English Core'**
  String get onboardingBrandEn;

  /// No description provided for @onboardingOwnerEn.
  ///
  /// In en, this message translates to:
  /// **'Mr Tharwat Tawfiq'**
  String get onboardingOwnerEn;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'طريقك الآمن لتحسين لغتك'**
  String get onboardingTagline;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your private account to continue'**
  String get loginSubtitle;

  /// No description provided for @loginUsername.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginUsername;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginButton;

  /// No description provided for @loginLoading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginLoading;

  /// No description provided for @loginErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get loginErrorInvalid;

  /// No description provided for @loginErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server. Check your internet connection and try again.'**
  String get loginErrorNetwork;

  /// No description provided for @loginErrorBackend.
  ///
  /// In en, this message translates to:
  /// **'The secure backend is not configured. Please configure the API server before using the app.'**
  String get loginErrorBackend;

  /// No description provided for @loginFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get loginFieldRequired;

  /// No description provided for @loginEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get loginEmailInvalid;

  /// No description provided for @loginSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Secure private access. Only authorized accounts can sign in.'**
  String get loginSecureNote;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pronounce English'**
  String get homeTitle;

  /// No description provided for @homeAccent.
  ///
  /// In en, this message translates to:
  /// **'in American accent'**
  String get homeAccent;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Type a word or sentence and get a clear American pronunciation and its Arabic translation.'**
  String get homeSubtitle;

  /// No description provided for @inputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type English or Arabic text...'**
  String get inputPlaceholder;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. How are you today?'**
  String get inputHint;

  /// No description provided for @inputPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get inputPaste;

  /// No description provided for @inputClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get inputClear;

  /// No description provided for @inputMic.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get inputMic;

  /// No description provided for @inputMicListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... tap to stop'**
  String get inputMicListening;

  /// No description provided for @inputMicRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording in progress... speak now'**
  String get inputMicRecording;

  /// No description provided for @inputEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please type or paste an English word or sentence first.'**
  String get inputEmptyError;

  /// No description provided for @inputOnlyArabicError.
  ///
  /// In en, this message translates to:
  /// **'Please enter English text to get pronunciation and translation.'**
  String get inputOnlyArabicError;

  /// No description provided for @mainCta.
  ///
  /// In en, this message translates to:
  /// **'Pronounce & Translate'**
  String get mainCta;

  /// No description provided for @mainCtaLoading1.
  ///
  /// In en, this message translates to:
  /// **'Analyzing the word...'**
  String get mainCtaLoading1;

  /// No description provided for @mainCtaLoading2.
  ///
  /// In en, this message translates to:
  /// **'Preparing pronunciation...'**
  String get mainCtaLoading2;

  /// No description provided for @mainCtaLoading3.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get mainCtaLoading3;

  /// No description provided for @recentHistory.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearHistory;

  /// No description provided for @tryExamples.
  ///
  /// In en, this message translates to:
  /// **'Try:'**
  String get tryExamples;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @resultEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get resultEnglish;

  /// No description provided for @resultArabicPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Arabic Pronunciation'**
  String get resultArabicPronunciation;

  /// No description provided for @resultTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get resultTranslation;

  /// No description provided for @resultCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get resultCopy;

  /// No description provided for @resultShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get resultShare;

  /// No description provided for @resultCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied successfully'**
  String get resultCopied;

  /// No description provided for @resultFavoriteAdd.
  ///
  /// In en, this message translates to:
  /// **'Saved to favorites'**
  String get resultFavoriteAdd;

  /// No description provided for @resultFavoriteRemove.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get resultFavoriteRemove;

  /// No description provided for @resultAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get resultAddFavorite;

  /// No description provided for @resultAccent.
  ///
  /// In en, this message translates to:
  /// **'American English'**
  String get resultAccent;

  /// No description provided for @resultVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get resultVoice;

  /// No description provided for @resultSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get resultSpeed;

  /// No description provided for @resultPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get resultPlay;

  /// No description provided for @resultPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get resultPause;

  /// No description provided for @resultResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resultResume;

  /// No description provided for @resultReplay.
  ///
  /// In en, this message translates to:
  /// **'Replay'**
  String get resultReplay;

  /// No description provided for @resultStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get resultStop;

  /// No description provided for @resultAudioError.
  ///
  /// In en, this message translates to:
  /// **'Could not play the pronunciation. Please try again.'**
  String get resultAudioError;

  /// No description provided for @resultTtsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Text-to-speech is not available on this device.'**
  String get resultTtsUnavailable;

  /// No description provided for @speechNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition is not available on this device.'**
  String get speechNotAvailable;

  /// No description provided for @speechPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access to use this feature.'**
  String get speechPermissionDenied;

  /// No description provided for @speechListening.
  ///
  /// In en, this message translates to:
  /// **'Listening... speak now'**
  String get speechListening;

  /// No description provided for @speechNoResult.
  ///
  /// In en, this message translates to:
  /// **'Sorry, I could not hear the words. Please try again.'**
  String get speechNoResult;

  /// No description provided for @micPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission'**
  String get micPermissionTitle;

  /// No description provided for @micPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'English Core TaP needs microphone access to convert your speech into English text.'**
  String get micPermissionMessage;

  /// No description provided for @micPermissionSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get micPermissionSettings;

  /// No description provided for @micPermissionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get micPermissionCancel;

  /// No description provided for @translationError.
  ///
  /// In en, this message translates to:
  /// **'Could not translate this text right now. Check your connection and try again.'**
  String get translationError;

  /// No description provided for @ttsError.
  ///
  /// In en, this message translates to:
  /// **'Could not play the pronunciation. Please try again.'**
  String get ttsError;

  /// No description provided for @phoneticNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Arabic pronunciation could not be generated for this text.'**
  String get phoneticNotAvailable;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your connection and try again.'**
  String get networkError;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Please try again later.'**
  String get serverError;

  /// No description provided for @rateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get rateLimitError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get timeoutError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;

  /// No description provided for @favoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added any words to favorites yet.'**
  String get favoritesEmpty;

  /// No description provided for @favoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the star on any result to save it here.'**
  String get favoritesEmptyHint;

  /// No description provided for @favoritesDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get favoritesDelete;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Your searches will appear here.'**
  String get historyEmptyHint;

  /// No description provided for @historySearch.
  ///
  /// In en, this message translates to:
  /// **'Search history...'**
  String get historySearch;

  /// No description provided for @historyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDelete;

  /// No description provided for @historyDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get historyDeleteAll;

  /// No description provided for @historyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get historyDeleteConfirm;

  /// No description provided for @historyDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all history? This cannot be undone.'**
  String get historyDeleteAllConfirm;

  /// No description provided for @historyCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get historyCancel;

  /// No description provided for @historyDeleteYes.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get historyDeleteYes;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get navFavorites;

  /// No description provided for @navPronounce.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get navPronounce;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsSystem;

  /// No description provided for @settingsDefaultVoice.
  ///
  /// In en, this message translates to:
  /// **'Default Voice'**
  String get settingsDefaultVoice;

  /// No description provided for @settingsMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get settingsMale;

  /// No description provided for @settingsFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get settingsFemale;

  /// No description provided for @settingsAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsAuto;

  /// No description provided for @settingsSpeed.
  ///
  /// In en, this message translates to:
  /// **'Pronunciation Speed'**
  String get settingsSpeed;

  /// No description provided for @settingsAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get settingsAccent;

  /// No description provided for @settingsAccentUs.
  ///
  /// In en, this message translates to:
  /// **'American English'**
  String get settingsAccentUs;

  /// No description provided for @settingsArabicPhonetic.
  ///
  /// In en, this message translates to:
  /// **'Arabic Pronunciation'**
  String get settingsArabicPhonetic;

  /// No description provided for @settingsArabicPhoneticOn.
  ///
  /// In en, this message translates to:
  /// **'Show Arabic pronunciation in results'**
  String get settingsArabicPhoneticOn;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface Language'**
  String get settingsLanguage;

  /// No description provided for @settingsArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get settingsArabic;

  /// No description provided for @settingsEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsEnglish;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get settingsUsername;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get settingsClearHistory;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsTerms;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About English Core'**
  String get settingsAbout;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAppVersion;

  /// No description provided for @settingsCheckUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get settingsCheckUpdate;

  /// No description provided for @updateNewVersion.
  ///
  /// In en, this message translates to:
  /// **'New version {version} is available'**
  String updateNewVersion(String version);

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You are on the latest version'**
  String get updateUpToDate;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check for updates. Try again later.'**
  String get updateFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutName.
  ///
  /// In en, this message translates to:
  /// **'ENGLISH CORE'**
  String get aboutName;

  /// No description provided for @aboutSub.
  ///
  /// In en, this message translates to:
  /// **'MR. THARWAT TAWFIQ'**
  String get aboutSub;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'An app that helps you learn correct American English pronunciation with Arabic translation and Arabic phonetic transcription.'**
  String get aboutDescription;

  /// No description provided for @aboutProducts.
  ///
  /// In en, this message translates to:
  /// **'This application is one of English Core\'s products, developed to serve the group\'s goals in teaching English and developing pronunciation and speaking skills.'**
  String get aboutProducts;

  /// No description provided for @aboutIpRights.
  ///
  /// In en, this message translates to:
  /// **'All intellectual property and copyright rights are reserved, including the application\'s content, design, educational materials, visual identity, software, and original components, in accordance with applicable laws and regulations.'**
  String get aboutIpRights;

  /// No description provided for @aboutFounder.
  ///
  /// In en, this message translates to:
  /// **'Founder: Mr. Tharwat Tawfiq'**
  String get aboutFounder;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© English Core — All Rights Reserved.'**
  String get aboutCopyright;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyTitle;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'English Core TaP processes the text you enter to provide translation and pronunciation services. Text may be sent to external services (translation and text-to-speech providers) to fulfill your request.\n\nWe do not collect personal information beyond your account credentials, which are managed securely. Your favorites and history are stored locally on your device.\n\nFor any questions, contact the administrator.'**
  String get privacyBody;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsTitle;

  /// No description provided for @termsBody.
  ///
  /// In en, this message translates to:
  /// **'English Core TaP is a private, restricted-access application. Access is granted only to authorized accounts created by the administrator.\n\nYou agree to use the app for personal educational purposes and not to misuse the services. Sharing your credentials is prohibited.\n\nThe content and logo are the property of MR. THARWAT TAWFIQ and may not be reused without permission.'**
  String get termsBody;

  /// No description provided for @footerNote.
  ///
  /// In en, this message translates to:
  /// **'Uses Google/Apple speech + real translation services'**
  String get footerNote;

  /// No description provided for @languageSwitched.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get languageSwitched;

  /// No description provided for @themeSwitched.
  ///
  /// In en, this message translates to:
  /// **'Theme updated'**
  String get themeSwitched;

  /// No description provided for @loginExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get loginExpired;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Signed out successfully'**
  String get logoutSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
