import 'package:flutter/foundation.dart';

/// Central API configuration. Secrets never live in the app:
/// the base URL is injected at build time via --dart-define.
class ApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String demoUser = String.fromEnvironment(
    'DEMO_USER',
    defaultValue: '',
  );
  static const String demoPass = String.fromEnvironment(
    'DEMO_PASS',
    defaultValue: '',
  );

  static bool get hasBackend => apiBaseUrl.isNotEmpty;

  /// Dev-only fallback: allows a demo account injected at build time.
  /// Never used when a real backend is configured.
  static bool get hasDemoAccount => demoUser.isNotEmpty && demoPass.isNotEmpty;
}

/// Typed application errors (mapped to localized, user-friendly messages).
enum AppErrorKind {
  emptyInput,
  arabicInput,
  network,
  server,
  timeout,
  rateLimit,
  translation,
  tts,
  phonetic,
  speechUnavailable,
  micPermission,
  authInvalid,
  authNetwork,
  backendNotConfigured,
  sessionTaken,
  unknown,
}

class AppException implements Exception {
  final AppErrorKind kind;
  final String message;
  const AppException(this.kind, [this.message = '']);

  @override
  String toString() => 'AppException($kind)';
}

/// Maps common HTTP/network failures to [AppErrorKind].
AppErrorKind mapHttpError(Object error) {
  if (error is AppException) return error.kind;
  final s = error.toString().toLowerCase();
  if (s.contains('timeout') || s.contains('timed out')) {
    return AppErrorKind.timeout;
  }
  if (s.contains('socket') ||
      s.contains('connection') ||
      s.contains('network') ||
      s.contains('host') ||
      s.contains('internet') ||
      s.contains('failed host')) {
    return AppErrorKind.network;
  }
  return AppErrorKind.unknown;
}

/// Debug-only assertion helper. Never logs secrets.
void debugOnlyLog(String message) {
  assert(() {
    debugPrint('[EnglishCoreTaP] $message');
    return true;
  }());
}