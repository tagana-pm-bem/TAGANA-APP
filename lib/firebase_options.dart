import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web not configured');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Platform not configured');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxbvmkNW-1oxLMDyUaoSQDetfL4dl94mc',
    appId: '1:697063451310:android:62a425f6df2fb590ef5b3f',
    messagingSenderId: '697063451310',
    projectId: 'tagana-app-7ea2e',
    storageBucket: 'tagana-app-7ea2e.firebasestorage.app',
  );
}
