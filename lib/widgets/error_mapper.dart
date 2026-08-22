import 'package:flutter/material.dart';

import '../data/services/api_config.dart';
import '../l10n/app_localizations.dart';

/// Maps [AppErrorKind] to a friendly localized message.
String errorMessage(BuildContext context, AppErrorKind kind) {
  final l10n = AppLocalizations.of(context);
  switch (kind) {
    case AppErrorKind.emptyInput:
      return l10n.inputEmptyError;
    case AppErrorKind.arabicInput:
      return l10n.inputOnlyArabicError;
    case AppErrorKind.network:
      return l10n.networkError;
    case AppErrorKind.server:
      return l10n.serverError;
    case AppErrorKind.timeout:
      return l10n.timeoutError;
    case AppErrorKind.rateLimit:
      return l10n.rateLimitError;
    case AppErrorKind.translation:
      return l10n.translationError;
    case AppErrorKind.tts:
      return l10n.ttsError;
    case AppErrorKind.phonetic:
      return l10n.phoneticNotAvailable;
    case AppErrorKind.speechUnavailable:
      return l10n.speechNotAvailable;
    case AppErrorKind.micPermission:
      return l10n.speechPermissionDenied;
    case AppErrorKind.authInvalid:
      return l10n.loginErrorInvalid;
    case AppErrorKind.authNetwork:
      return l10n.loginErrorNetwork;
    case AppErrorKind.backendNotConfigured:
      return l10n.loginErrorBackend;
    case AppErrorKind.unknown:
      return l10n.unknownError;
  }
}
