import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB' '_QK4QU8Dh0G4EMYy606S3_-ES9COT7qY',
    appId:
        '1:726897308141:web:1234567890abcdef', // You can update this later if you add web
    messagingSenderId: '726897308141',
    projectId: 'symphony-music-app-6eddc',
    authDomain: 'symphony-music-app-6eddc.firebaseapp.com',
    storageBucket: 'symphony-music-app-6eddc.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB' '_QK4QU8Dh0G4EMYy606S3_-ES9COT7qY',
    appId: '1:726897308141:android:368c1f5a578ce5b42fb7e4',
    messagingSenderId: '726897308141',
    projectId: 'symphony-music-app-6eddc',
    storageBucket: 'symphony-music-app-6eddc.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB' '_QK4QU8Dh0G4EMYy606S3_-ES9COT7qY',
    appId:
        '1:726897308141:ios:1234567890abcdef', // You can update this later if you add iOS
    messagingSenderId: '726897308141',
    projectId: 'symphony-music-app-6eddc',
    storageBucket: 'symphony-music-app-6eddc.firebasestorage.app',
    iosBundleId: 'com.example.symphony.symphony',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB' '_QK4QU8Dh0G4EMYy606S3_-ES9COT7qY',
    appId:
        '1:726897308141:ios:1234567890abcdef', // You can update this later if you add macOS
    messagingSenderId: '726897308141',
    projectId: 'symphony-music-app-6eddc',
    storageBucket: 'symphony-music-app-6eddc.firebasestorage.app',
    iosBundleId: 'com.example.symphony.symphony',
  );
}
