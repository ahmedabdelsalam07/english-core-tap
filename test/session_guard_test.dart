import 'package:english_core_tap/data/services/session_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('claims a free session for this device', () async {
    SharedPreferences.setMockInitialValues({});
    final writes = <String, String>{};
    final guard = SessionGuard(
      readField: (_, __) async => null,
      writeField: (uid, field, value) async {
        writes[value] = field;
        return true;
      },
    );

    final status = await guard.claimOnLogin('u1');
    expect(status, SessionLoginStatus.activated);
    expect(writes.values.single, 'session');
  });

  test('reports taken when another device holds the session', () async {
    SharedPreferences.setMockInitialValues({});
    var wrote = false;
    final guard = SessionGuard(
      readField: (_, __) async => 'device-other',
      writeField: (_, __, ___) async {
        wrote = true;
        return true;
      },
    );

    final status = await guard.claimOnLogin('u1');
    expect(status, SessionLoginStatus.takenByOther);
    expect(wrote, isFalse);
  });

  test('takeover overwrites the session unconditionally', () async {
    SharedPreferences.setMockInitialValues({});
    String? written;
    final guard = SessionGuard(
      readField: (_, __) async => 'device-other',
      writeField: (_, __, value) async {
        written = value;
        return true;
      },
    );

    final status = await guard.claimOnLogin('u1', takeOver: true);
    expect(status, SessionLoginStatus.activated);
    expect(written, isNotNull);
    expect(written != 'device-other', isTrue);
  });

  test('fails open when the cloud is unreachable', () async {
    SharedPreferences.setMockInitialValues({});
    final guard = SessionGuard(
      readField: (_, __) => Future.error(Exception('offline')),
      writeField: (_, __, ___) async => false,
    );

    final status = await guard.claimOnLogin('u1');
    expect(status, SessionLoginStatus.unavailable);
  });

  test('first heartbeat adopts the remote session instead of kicking',
      () async {
    SharedPreferences.setMockInitialValues({});
    final guard = SessionGuard(
      readField: (_, __) async => 'remote-session-id',
      writeField: (_, __, ___) async => true,
    );

    // No local marker yet (e.g. first launch after an update): adopt.
    expect(await guard.isActiveHere('u1'), isTrue);

    // Second check now compares against the adopted marker.
    expect(await guard.isActiveHere('u1'), isTrue);
  });

  test('kicks only when both markers exist and differ', () async {
    SharedPreferences.setMockInitialValues({
      'active_session_uid': 'u1',
      'active_session_id': 'mine',
    });
    var remote = 'mine';
    final guard = SessionGuard(
      readField: (_, __) async => remote,
      writeField: (_, __, ___) async => true,
    );
    expect(await guard.isActiveHere('u1'), isTrue);

    remote = 'theirs'; // another device took over
    expect(await guard.isActiveHere('u1'), isFalse);
  });

  test('heartbeat fails open on errors and empty remote', () async {
    SharedPreferences.setMockInitialValues({
      'active_session_uid': 'u1',
      'active_session_id': 'mine',
    });
    final offline = SessionGuard(
      readField: (_, __) => Future.error(Exception('offline')),
      writeField: (_, __, ___) async => false,
    );
    expect(await offline.isActiveHere('u1'), isTrue);

    final noRemote = SessionGuard(
      readField: (_, __) async => null,
      writeField: (_, __, ___) async => true,
    );
    expect(await noRemote.isActiveHere('u1'), isTrue);
  });
}
