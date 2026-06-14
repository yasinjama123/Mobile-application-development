import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform. '
          'Run: flutterfire configure',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy-REPLACE-WITH-YOUR-ANDROID-API-KEY',
    appId: '1:000000000000:android:REPLACE',
    messagingSenderId: '000000000000',
    projectId: 'fairprice-birrwise',
    storageBucket: 'fairprice-birrwise.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy-REPLACE-WITH-YOUR-IOS-API-KEY',
    appId: '1:000000000000:ios:REPLACE',
    messagingSenderId: '000000000000',
    projectId: 'fairprice-birrwise',
    storageBucket: 'fairprice-birrwise.appspot.com',
    iosClientId: 'REPLACE.apps.googleusercontent.com',
    iosBundleId: 'com.group5.fairprice',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy-REPLACE-WITH-YOUR-WEB-API-KEY',
    appId: '1:000000000000:web:REPLACE',
    messagingSenderId: '000000000000',
    projectId: 'fairprice-birrwise',
    storageBucket: 'fairprice-birrwise.appspot.com',
    authDomain: 'fairprice-birrwise.firebaseapp.com',
  );
}
