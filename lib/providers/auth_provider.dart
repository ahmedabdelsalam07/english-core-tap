import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/backend_client.dart';
import 'services_provider.dart';

class AuthController extends AsyncNotifier<UserAccount?> {
  late final AuthService _auth;

  @override
  Future<UserAccount?> build() async {
    _auth = ref.read(authServiceProvider);
    return _auth.currentUser;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _auth.login(username, password));
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncData(null);
  }

  /// Firebase Auth is always available in production builds.
  bool get isConfigured => true;
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserAccount?>(AuthController.new);