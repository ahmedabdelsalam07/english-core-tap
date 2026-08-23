import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_user_store.dart';

/// Outcome of trying to register this device as the single active session.
enum SessionLoginStatus {
  /// This device is now the active one.
  activated,

  /// The account is currently open on another device.
  takenByOther,

  /// Cloud session storage is unavailable (offline or Firestore not enabled
  /// yet) — the login proceeds without device exclusivity.
  unavailable,
}

/// Enforces one active device per account.
///
/// On every sign-in the device registers a fresh session id in the user's
/// cloud document. If another device already holds the session, the caller
/// can ask the student to confirm taking over; the previous device then
/// detects the change on its next heartbeat and signs out automatically.
///
/// Everything fails open: when the cloud is unreachable nobody is ever
/// signed out and logins keep working.
class SessionGuard {
  SessionGuard({
    CloudUserStore? store,
    Future<String?> Function(String uid, String field)? readField,
    Future<bool> Function(String uid, String field, String value)? writeField,
  })  : _store = store,
        _readField = readField,
        _writeField = writeField;

  static const String _sessionField = 'session';
  static const String _localKey = 'active_session_id';
  static const String _prefsUidKey = 'active_session_uid';

  final CloudUserStore? _store;
  final Future<String?> Function(String uid, String field)? _readField;
  final Future<bool> Function(String uid, String field, String value)?
      _writeField;

  CloudUserStore get _cloud => _store ?? CloudUserStore();

  String newSessionId() {
    final rnd = Random.secure();
    final values = List<int>.generate(9, (_) => rnd.nextInt(256));
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
        '${values.map((b) => b.toRadixString(36).padLeft(2, '0')).join()}';
  }

  /// Registers this device as the active session for [uid].
  ///
  /// When [takeOver] is false and another device holds the session, returns
  /// [SessionLoginStatus.takenByOther] without changing anything so the UI
  /// can ask for confirmation first. With [takeOver] true the session is
  /// claimed unconditionally and the other device gets kicked.
  Future<SessionLoginStatus> claimOnLogin(
    String uid, {
    bool takeOver = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remote = await _read(uid);
      final mine = prefs.getString(_localKey);

      if (!takeOver &&
          remote != null &&
          remote.isNotEmpty &&
          remote != mine) {
        return SessionLoginStatus.takenByOther;
      }

      final id = newSessionId();
      final ok = await _write(uid, id);
      if (!ok) {
        // Keep the local marker anyway so a later successful write still
        // lines up with what this device considers its own session.
        await prefs.setString(_localKey, id);
        await prefs.setString(_prefsUidKey, uid);
        return SessionLoginStatus.unavailable;
      }
      await prefs.setString(_localKey, id);
      await prefs.setString(_prefsUidKey, uid);
      return SessionLoginStatus.activated;
    } catch (_) {
      return SessionLoginStatus.unavailable;
    }
  }

  /// Heartbeat check for an already signed-in account.
  ///
  /// Returns true when this device should stay signed in. First launch
  /// after an update adopts whatever session the cloud holds (or registers
  /// a new one) instead of kicking the student.
  Future<bool> isActiveHere(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_prefsUidKey) != uid) {
        // Different account than the one that last claimed here: adopt or
        // register rather than kick.
        final remote = await _read(uid);
        final id = (remote == null || remote.isEmpty)
            ? null
            : remote; // adopt existing
        if (id == null) {
          final fresh = newSessionId();
          await _write(uid, fresh);
          await prefs.setString(_localKey, fresh);
        } else {
          await prefs.setString(_localKey, id);
        }
        await prefs.setString(_prefsUidKey, uid);
        return true;
      }

      final mine = prefs.getString(_localKey);
      if (mine == null || mine.isEmpty) return true; // fail open

      final remote = await _read(uid);
      if (remote == null || remote.isEmpty) return true; // offline / disabled
      return remote == mine;
    } catch (_) {
      return true; // fail open on any error
    }
  }

  /// Clears the local session markers (called on logout).
  Future<void> release() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
      await prefs.remove(_prefsUidKey);
    } catch (_) {}
  }

  Future<String?> _read(String uid) async {
    if (_readField != null) return _readField(uid, _sessionField);
    return _cloud.readField(uid, _sessionField);
  }

  Future<bool> _write(String uid, String value) async {
    if (_writeField != null) return _writeField(uid, _sessionField, value);
    return _cloud.saveField(uid, field: _sessionField, jsonValue: value);
  }
}
