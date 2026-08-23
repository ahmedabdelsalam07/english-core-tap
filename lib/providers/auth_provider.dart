import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/api_config.dart';
import '../data/services/backend_client.dart';
import '../data/services/session_guard.dart';
import 'services_provider.dart';

final sessionGuardProvider = Provider<SessionGuard>((ref) {
  return SessionGuard();
});

/// Set when this device was signed out because the account opened elsewhere.
final kickedFromOtherDeviceProvider = StateProvider<bool>((ref) => false);

class AuthController extends AsyncNotifier<UserAccount?> {
  late final AuthService _auth;

  @override
  Future<UserAccount?> build() async {
    _auth = ref.read(authServiceProvider);
    return _auth.currentUser;
  }

  /// Signs in and claims the single active device slot for this account.
  ///
  /// When another device already holds the session and [takeOverOtherDevice]
  /// is false, throws [AppException] with [AppErrorKind.sessionTaken] so the
  /// UI can ask for confirmation; retrying with the flag set takes over and
  /// the previous device is signed out automatically on its next heartbeat.
  Future<void> login(
    String username,
    String password, {
    bool takeOverOtherDevice = false,
  }) async {
    state = const AsyncLoading();
    try {
      final account = await _auth.login(username, password);
      if (account.uid.isNotEmpty) {
        final status = await ref
            .read(sessionGuardProvider)
            .claimOnLogin(account.uid, takeOver: takeOverOtherDevice);
        if (status == SessionLoginStatus.takenByOther) {
          // Roll back the fresh sign-in on this device; the other device
          // keeps the account until the student decides otherwise.
          await _auth.logout();
          const failure = AppException(AppErrorKind.sessionTaken);
          state = AsyncError(failure, StackTrace.current);
          throw failure;
        }
      }
      state = AsyncData(account);
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    } catch (error) {
      final mapped = AppException(mapHttpError(error));
      state = AsyncError(mapped, StackTrace.current);
      throw mapped;
    }
  }

  Future<void> logout() async {
    await ref.read(sessionGuardProvider).release();
    await _auth.logout();
    state = const AsyncData(null);
  }

  /// Signs this device out because the same account was opened elsewhere.
  Future<void> signOutByOtherDevice() async {
    await ref.read(sessionGuardProvider).release();
    try {
      await _auth.logout();
    } catch (_) {}
    ref.read(kickedFromOtherDeviceProvider.notifier).state = true;
    state = const AsyncData(null);
  }

  /// Firebase Auth is always available in production builds.
  bool get isConfigured => true;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserAccount?>(AuthController.new);

/// Periodic single-device heartbeat. Fails open: whenever the cloud session
/// store is unreachable (offline, or Firestore not enabled yet) nobody ever
/// gets signed out.
final sessionKickCheckerProvider = Provider<void>((ref) {
  Timer.periodic(const Duration(seconds: 45), (_) => _verifySession(ref));
});

Future<void> _verifySession(Ref ref) async {
  try {
    final account = ref.read(authControllerProvider).valueOrNull;
    if (account == null || account.uid.isEmpty) return;
    final guard = ref.read(sessionGuardProvider);
    if (!await guard.isActiveHere(account.uid)) {
      await ref.read(authControllerProvider.notifier).signOutByOtherDevice();
    }
  } catch (_) {}
}
