/// SharedPreferences keys.
class StorageKeys {
  static const String settings = 'app_settings';
  static const String favorites = 'favorites_v1';
  static const String history = 'history_v1';
  static const String authSession = 'auth_session';
  static const String onboarding = 'onboarding_seen';

  /// Namespace used while no account is signed in.
  static const String guestNamespace = 'guest';

  /// Per-user keys so every account keeps its own records on this device.
  static String historyFor(String uid) => 'history_v2_$uid';

  static String favoritesFor(String uid) => 'favorites_v2_$uid';
}