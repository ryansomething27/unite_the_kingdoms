import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for all supported platforms.
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBD1xESsKaUSMc-zQkG55sdsh6sYxQpGgU',
    appId: '1:977831010431:web:abcdef123456789',
    messagingSenderId: '977831010431',
    projectId: 'unite-the-kingdoms',
    authDomain: 'unite-the-kingdoms.firebaseapp.com',
    storageBucket: 'unite-the-kingdoms.appspot.com',
    measurementId: 'G-XXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz123456789',
    appId: '1:977831010431:android:abcdef123456789',
    messagingSenderId: '977831010431',
    projectId: 'unite-the-kingdoms',
    storageBucket: 'unite-the-kingdoms.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBD1xESsKaUSMc-zQkG55sdsh6sYxQpGgU',
    appId: '1:977831010431:ios:55f3e9c442f9ee55c49f4a',
    messagingSenderId: '977831010431',
    projectId: 'unite-the-kingdoms',
    storageBucket: 'unite-the-kingdoms.firebasestorage.app',
    iosBundleId: 'com.example.unite_kingdoms',
    iosClientId: '977831010431-4d0da1topmi5c1dlkuo05qeisdc8si76.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBD1xESsKaUSMc-zQkG55sdsh6sYxQpGgU',
    appId: '1:977831010431:ios:55f3e9c442f9ee55c49f4a',
    messagingSenderId: '977831010431',
    projectId: 'unite-the-kingdoms',
    storageBucket: 'unite-the-kingdoms.firebasestorage.app',
    iosBundleId: 'com.example.unite_kingdoms',
    iosClientId: '977831010431-4d0da1topmi5c1dlkuo05qeisdc8si76.apps.googleusercontent.com',
  );
}