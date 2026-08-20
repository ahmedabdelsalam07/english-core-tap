import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for the English Core TaP app.
/// Web and Android configs are production-ready.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'Firebase iOS setup is not configured yet. '
          'Run `flutterfire configure` to add iOS support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDsIOSnH4OwkffJzR3k2lPSNxwkRWzn6Mw',
    appId: '1:461612467766:android:00c4ae5f9eb84f8284fa97',
    messagingSenderId: '461612467766',
    projectId: 'english-core-tap',
    authDomain: 'english-core-tap.firebaseapp.com',
    storageBucket: 'english-core-tap.firebasestorage.app',
  );

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