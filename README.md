# English Core TaP

Production-ready Flutter app for learning **American English pronunciation**,
with **Arabic translation** and **Arabic phonetic transcription**. Built for
Mr. Tharwat Tawfiq's "English Core" program. Arabic-first (RTL) with a full
Arabic/English interface, private login, dark mode, favorites, history, and
offline-safe local storage.

- Package / app id: `com.englishcore.tap`
- Minimum SDK: Android 23 (6.0), iOS 13
- Flutter: 3.47 / Dart 3.13 (uses `C:\flutter` on this machine)

## Features

- **Pronunciation**: type, paste, or speak English → hear it via en-US TTS
  (male/female voice selection, play/pause/resume/replay, speed control).
- **Arabic translation**: real translation via Google's free endpoint
  (no API key); service is swappable for a backend later.
- **Arabic phonetic transcription**: natural Arabic script based on actual
  pronunciation (override dictionary + real IPA mapped with diacritics),
  e.g. `comfortable → كَمفْتَرَبُل`, `beautiful → بيوتِفُل`,
  `how are you doing today → هاو آر يو دووِنغ توداي`.
- **Native audio card** for verified word pronunciations (dictionary API).
- **Favorites & history** (searchable, per-account), **settings**, onboarding,
  about/privacy/terms screens.
- **Localization**: `lib/l10n/app_ar.arb` + `app_en.arb`, generated via
  `flutter gen-l10n` into `lib/l10n/app_localizations.dart`. Arabic default,
  RTL/LTR switch persisted in settings.
- **Theme**: brand colors (`#4338CA`, `#6D28D9`, lavender `#EEF0FF`, cream
  `#F6EEDF`), Cairo variable font, light/dark/system modes.

## Get started

```sh
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
```

Run with a demo account (no backend needed, dev only):

```sh
flutter run --dart-define=DEMO_USER=demo --dart-define=DEMO_PASS=demo123
```

Run pointing at a real backend:

```sh
flutter run --dart-define=API_BASE_URL=https://your-api.example.com
```

> No credentials are compiled into the app. The backend URL and demo account
> are injected with `--dart-define`; without them the app shows a clear
> "backend not configured" message. `LocalDevAuthService` is disabled whenever
> `API_BASE_URL` is present.

## Reference backend (`server/`)

Private login only — users are created by an admin, there is **no** public
registration. See `server/README.md`.

```sh
cd server
npm install
npm run seed -- <username> <password>   # admin creates a user
JWT_SECRET=... npm start                 # defaults to :8080
```

Endpoints: `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/logout`,
`GET /health`. The Flutter client contract lives in
`lib/data/services/backend_client.dart`.

## Android release build

```sh
flutter build appbundle --release     # or: flutter build apk --release
```

Release signing: create `android/key.properties` (documented in
`android/app/build.gradle`). When the file is absent the release build falls
back to the debug key so the build always works; add `key.properties` for a
store-published build.

Permissions declared: `INTERNET`, `RECORD_AUDIO` (speech input). iOS declares
`NSMicrophoneUsageDescription` + `NSSpeechRecognitionUsageDescription`.

## Layout

- `lib/core` — theme (colors, typography, spacing, radius, shadows, theme),
  constants, enums.
- `lib/data/models` — `PronunciationResult`, `FavoriteEntry`, `HistoryEntry`,
  `AppSettings`.
- `lib/data/services` — translation, dictionary, Arabic phonetic, TTS, audio
  player, speech, auth/backend, settings/favorites/history repositories.
- `lib/providers` — Riverpod controllers (settings, favorites, history, auth,
  home flow, service wiring).
- `lib/features` — splash, onboarding, login, shell, home, result, favorites,
  history, settings, about, privacy, terms.
- `lib/widgets` — logo, buttons, language switcher, empty state, copy button,
  error banner/mapper, section card.
- `assets/logo`, `assets/fonts` — brand assets and Cairo font.