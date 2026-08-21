import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import 'reload_support.dart';

/// Result of an update check against GitHub Releases.
class UpdateInfo {
  final String latestTag;
  final String releaseNotes;
  final bool updateAvailable;
  final String? apkUrl;
  final String releaseUrl;

  const UpdateInfo({
    required this.latestTag,
    required this.releaseNotes,
    required this.updateAvailable,
    required this.releaseUrl,
    this.apkUrl,
  });
}

/// Checks GitHub Releases for a newer version and provides the right
/// "update" action per platform:
///  - Android: opens the latest APK download URL.
///  - Web: unregisters the old service worker, clears caches and reloads so
///    the freshly deployed build actually loads (the usual reason "the site
///    did not update").
class UpdateService {
  static const _timeout = Duration(seconds: 12);

  /// Compares 'vX.Y.Z' style tags. Returns true when [remote] is strictly
  /// newer than [current].
  static bool isNewer(String remote, String current) {
    List<int> parse(String v) => v
        .replaceAll(RegExp(r'^[vV]'), '')
        .split('.')
        .map((p) => int.tryParse(p.trim()) ?? 0)
        .toList();
    final a = parse(remote);
    final b = parse(current);
    for (var i = 0; i < 3; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av > bv;
    }
    return false;
  }

  /// Queries the latest GitHub release. Throws on network/HTTP failure.
  Future<UpdateInfo> checkForUpdate() async {
    // Cache-buster: proxies must not serve a cached API response, otherwise
    // the check itself would report a stale version forever.
    final uri = Uri.parse(
      'https://api.github.com/repos/${Constants.githubRepo}/releases/latest'
      '?_=${DateTime.now().millisecondsSinceEpoch}',
    );
    final response = await http
        .get(uri, headers: {'Accept': 'application/vnd.github+json'})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('release lookup failed (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final tag = (data['tag_name'] ?? '').toString();
    var notes = (data['body'] ?? '').toString();
    if (notes.length > 900) notes = '${notes.substring(0, 900)}…';
    String? apkUrl;
    final assets =
        (data['assets'] as List? ?? const []).whereType<Map>().toList();
    for (final asset in assets) {
      if ((asset['name'] ?? '').toString().endsWith('.apk')) {
        apkUrl = (asset['browser_download_url'] ?? '').toString();
        break;
      }
    }
    return UpdateInfo(
      latestTag: tag,
      releaseNotes: notes,
      releaseUrl: (data['html_url'] ?? '').toString(),
      apkUrl: apkUrl,
      updateAvailable: isNewer(tag, Constants.appVersion),
    );
  }

  /// Applies the update for the current platform.
  Future<bool> applyUpdate(UpdateInfo info) async {
    if (kIsWeb) {
      // Old service worker + cached assets are exactly why updates appeared
      // broken: nuke them, then reload from the network.
      await unregisterServiceWorkersAndClearCaches();
      return true;
    }
    if (Platform.isAndroid && info.apkUrl != null) {
      return launchUrl(
        Uri.parse(info.apkUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
    return launchUrl(
      Uri.parse(info.releaseUrl),
      mode: LaunchMode.externalApplication,
    );
  }
}
