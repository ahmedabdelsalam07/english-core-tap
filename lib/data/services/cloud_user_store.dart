import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Reads and writes the signed-in student's data snapshot from Cloud
/// Firestore over its REST API, so history and favorites follow the account
/// across devices, reinstalls and app updates.
///
/// Every call degrades silently to "unavailable" when Firestore is not
/// enabled yet or the device is offline — local storage always stays the
/// source of truth shown in the UI. Once Firestore is enabled in the Firebase
/// console this service starts working with no code changes.
class CloudUserStore {
  CloudUserStore({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    Future<String?> Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _timeout = timeout,
        _tokenProvider = tokenProvider ?? _firebaseIdToken;

  static const String _projectId = 'english-core-tap';

  final http.Client _client;
  final Duration _timeout;
  final Future<String?> Function() _tokenProvider;

  static Future<String?> _firebaseIdToken() async {
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Uri _docUri(String uid) => Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId'
        '/databases/(default)/documents/users/$uid',
      );

  Future<String?> _idToken() => _tokenProvider();

  /// Returns the stored [CloudSnapshot] for [uid], or null when unavailable.
  Future<CloudSnapshot?> fetch(String uid) async {
    final token = await _idToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _client
          .get(_docUri(uid), headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>? ?? const {};
      String? value(String key) =>
          (fields[key] as Map<String, dynamic>?)?['stringValue'] as String?;
      return CloudSnapshot(
        historyJson: value('history'),
        favoritesJson: value('favorites'),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reads a single string field of the user document; null on any failure.
  Future<String?> readField(String uid, String field) async {
    final token = await _idToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _client
          .get(_docUri(uid), headers: {'Authorization': 'Bearer $token'})
          .timeout(_timeout);
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>? ?? const {};
      return (fields[field] as Map<String, dynamic>?)?['stringValue']
          as String?;
    } catch (_) {
      return null;
    }
  }

  /// Persists one field of the user document. Returns true on success.
  Future<bool> saveField(
    String uid, {
    required String field,
    required String jsonValue,
  }) async {
    final token = await _idToken();
    if (token == null || token.isEmpty) return false;
    try {
      final uri = _docUri(uid).replace(queryParameters: <String, String>{
        'updateMask.fieldPaths': field,
      });
      final response = await _client
          .patch(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'fields': <String, dynamic>{
                field: <String, String>{'stringValue': jsonValue},
              },
            }),
          )
          .timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Wraps a list of JSON lines into the single string stored in Firestore.
  static String encodeList(List<String> lines) => jsonEncode(lines);

  /// Unwraps a stored string back into JSON lines; null when malformed.
  static List<String>? decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return null;
  }
}

/// A user's cloud snapshot; each field is a JSON-encoded list of entry lines.
class CloudSnapshot {
  final String? historyJson;
  final String? favoritesJson;

  const CloudSnapshot({this.historyJson, this.favoritesJson});
}
