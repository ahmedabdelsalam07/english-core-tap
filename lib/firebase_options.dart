import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the English Core TaP app.
/// Web config is production-ready; native platforms require extra setup
/// (google-services.json / GoogleService-Info.plist) before they can build.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase native setup is not configured yet. '
          'Run `flutterfire configure` to add Android/iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCXNjgt9sKFfINHawhrqDyCEQF3uAGxyLE',
    appId: '1:461612467766:web:3f42dc50303c935d84fa97',
    messagingSenderId: '461612467766',
    projectId: 'english-core-tap',
    authDomain: 'english-core-tap.firebaseapp.com',
    storageBucket: 'english-core-tap.firebasestorage.app',
    measurementId: 'G-P7PB16HPCX',
  );
}