import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import 'api_config.dart';
import 'storage_keys.dart';

/// Accounts sign in with the email + password pair created for them in the
/// Firebase console by the admin (teacher). No local email mapping is done.
const String authEmailDomain = 'englishcore.app';

/// Authenticated account (never stores the password).
class UserAccount {
  final String username;
  const UserAccount({required this.username});

  Map<String, dynamic> toJson() => {'username': username};
  factory UserAccount.fromJson(Map<String, dynamic> json) =>
      UserAccount(username: json['username'] as String? ?? '');
}

/// Secure token storage (Keystore / Keychain backed).
class SecureTokenStore {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    webOptions: WebOptions(),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.authSession, value: token);
  }

  Future<String?> readToken() async =>
      _storage.read(key: StorageKeys.authSession);

  Future<void> clear() async =>
      _storage.delete(key: StorageKeys.authSession);
}

/// Authentication abstraction. Swappable implementation; no credentials
/// are ever embedded in the app.
abstract class AuthService {
  Future<UserAccount?> get currentUser;
  Future<UserAccount> login(String username, String password);
  Future<void> logout();

  /// Creates the appropriate implementation:
  /// Firebase Auth everywhere (web and native). No secrets live in the app.
  factory AuthService.create() => FirebaseAuthService();
}

/// Auth backed by Firebase Auth: passwords are checked server-side by
/// Firebase, so nothing sensitive ships with the app bundle.
class FirebaseAuthService implements AuthService {
  @override
  Future<UserAccount?> get currentUser async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return UserAccount(username: usernameFrom(user));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserAccount> login(String username, String password) async {
    // Accounts are Firebase Auth email+password users; the login field is the
    // plain email address exactly as created in the Firebase console.
    final email = username.trim();
    if (email.isEmpty || password.isEmpty) {
      throw const AppException(AppErrorKind.emptyInput);
    }
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AppException(AppErrorKind.authInvalid);
      }
      return UserAccount(username: usernameFrom(user));
    } on FirebaseAuthException catch (e) {
      throw mapAuthError(e);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(mapHttpError(e));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}

/// Display name derived from the account email (the part before '@').
String usernameFrom(User user) {
  final email = user.email;
  if (email == null || email.isEmpty) return user.uid;
  return email.split('@').first;
}

AppException mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'wrong-password':
    case 'user-not-found':
    case 'user-disabled':
      return const AppException(AppErrorKind.authInvalid);
    case 'too-many-requests':
      return const AppException(AppErrorKind.rateLimit);
    case 'network-request-failed':
      return const AppException(AppErrorKind.network);
    case 'operation-not-allowed':
      return const AppException(AppErrorKind.server);
    default:
      return AppException(AppErrorKind.server, e.message ?? e.code);
  }
}

class BackendAuthService implements AuthService {
  final http.Client _client = http.Client();
  final SecureTokenStore _store = SecureTokenStore();

  @override
  Future<UserAccount?> get currentUser async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return null;
    if (!ApiConfig.hasBackend) return null;
    try {
      final response = await _client.get(
        Uri.parse('${ApiConfig.apiBaseUrl}/api/auth/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(Constants.apiTimeout);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final user = body['user'] as Map<String, dynamic>? ?? const {};
        return UserAccount.fromJson(user);
      }
      await _store.clear();
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserAccount> login(String username, String password) async {
    if (!ApiConfig.hasBackend) {
      throw const AppException(AppErrorKind.backendNotConfigured);
    }
    final trimmed = username.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      throw const AppException(AppErrorKind.emptyInput);
    }
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.apiBaseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': trimmed, 'password': password}),
          )
          .timeout(Constants.apiTimeout);
      if (response.statusCode == 401) {
        throw const AppException(AppErrorKind.authInvalid);
      }
      if (response.statusCode == 429) {
        throw const AppException(AppErrorKind.rateLimit);
      }
      if (response.statusCode != 200) {
        throw AppException(AppErrorKind.server, 'login status ${response.statusCode}');
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final token = body['token'] as String?;
      if (token == null || token.isEmpty) {
        throw const AppException(AppErrorKind.authInvalid);
      }
      await _store.saveToken(token);
      final user = UserAccount.fromJson(
        body['user'] as Map<String, dynamic>? ?? {'username': trimmed},
      );
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException(mapHttpError(e));
    }
  }

  @override
  Future<void> logout() async {
    final token = await _store.readToken();
    if (token != null && ApiConfig.hasBackend) {
      try {
        await _client.post(
          Uri.parse('${ApiConfig.apiBaseUrl}/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(Constants.apiTimeout);
      } catch (_) {}
    }
    await _store.clear();
  }
}

/// Dev-only implementation. Enabled ONLY when DEMO_USER/DEMO_PASS are
/// injected via --dart-define and no backend is configured. This exists so
/// the app can be tested before the backend is deployed. It is never used
/// in a production build that points to a real API server.
class LocalDevAuthService implements AuthService {
  final SecureTokenStore _store = SecureTokenStore();

  @override
  Future<UserAccount?> get currentUser async {
    final token = await _store.readToken();
    if (token == null || token.isEmpty) return null;
    final decoded = utf8.decode(base64.decode(token));
    return UserAccount(username: decoded);
  }

  @override
  Future<UserAccount> login(String username, String password) async {
    if (!ApiConfig.hasDemoAccount) {
      throw const AppException(AppErrorKind.backendNotConfigured);
    }
    if (username.trim() != ApiConfig.demoUser || password != ApiConfig.demoPass) {
      throw const AppException(AppErrorKind.authInvalid);
    }
    final token = base64.encode(utf8.encode(username.trim()));
    await _store.saveToken(token);
    return UserAccount(username: username.trim());
  }

  @override
  Future<void> logout() => _store.clear();
}