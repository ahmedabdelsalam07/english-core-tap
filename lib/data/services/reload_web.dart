// Web-only: removes any previously registered service worker and clears the
// Cache Storage entries, then reloads so the newest deployment is fetched.
//
// This is the fix for "the web app never updates": Flutter's release builds
// register an offline-first service worker; without clearing it users stay
// on a stale build even after a redeploy.
// This file is web-only by design (conditional export) — dart:html is the
// simplest API here.
// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> unregisterServiceWorkersAndClearCaches() async {
  try {
    final sw = html.window.navigator.serviceWorker;
    if (sw != null) {
      final registrations = await sw.getRegistrations();
      for (final reg in registrations) {
        await reg.unregister();
      }
    }
  } catch (_) {}
  try {
    if (html.window.caches != null) {
      final keys = await html.window.caches!.keys();
      for (final key in keys) {
        await html.window.caches!.delete(key);
      }
    }
  } catch (_) {}
  html.window.location.reload();
}
