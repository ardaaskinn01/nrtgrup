// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase yapılandırma seçenekleri.
/// FlutterFire CLI (`flutterfire configure`) çalıştırıldığında bu dosya otomatik güncellenebilir.
/// iOS ve Android tarafında `GoogleService-Info.plist` veya `google-services.json`
/// eklendiğinde Firebase.initializeApp() doğrudan bu dosyaları okuyabilir.
class DefaultFirebaseOptions {
  static bool get areOptionsConfigured => _isConfigured;
  static const bool _isConfigured = true;

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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCHKl_bH4ao97h35BJnzTHdUVAbxIQSlik',
    appId: '1:1014560919657:web:25f2a57561acd6833e92f8',
    messagingSenderId: '1014560919657',
    projectId: 'nrtgrup-bca9d',
    authDomain: 'nrtgrup-bca9d.firebaseapp.com',
    storageBucket: 'nrtgrup-bca9d.firebasestorage.app',
    measurementId: 'G-16F9KF7Z9C',
  );

  // Placeholder değerler (FlutterFire CLI veya Firebase Konsolu ile güncellenir)

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDfEtAD4k-PJdng3Zdhqvu02N2RRVZVwUs',
    appId: '1:1014560919657:android:0869c59b7710d6733e92f8',
    messagingSenderId: '1014560919657',
    projectId: 'nrtgrup-bca9d',
    storageBucket: 'nrtgrup-bca9d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxNtVbaBN3Wy3shoo8cLDeFdFRG8xZa7U',
    appId: '1:1014560919657:ios:d5a069fc607a1aec3e92f8',
    messagingSenderId: '1014560919657',
    projectId: 'nrtgrup-bca9d',
    storageBucket: 'nrtgrup-bca9d.firebasestorage.app',
    iosBundleId: 'com.aasoft.nrt',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxNtVbaBN3Wy3shoo8cLDeFdFRG8xZa7U',
    appId: '1:1014560919657:ios:d5a069fc607a1aec3e92f8',
    messagingSenderId: '1014560919657',
    projectId: 'nrtgrup-bca9d',
    storageBucket: 'nrtgrup-bca9d.firebasestorage.app',
    iosBundleId: 'com.aasoft.nrt',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCHKl_bH4ao97h35BJnzTHdUVAbxIQSlik',
    appId: '1:1014560919657:web:55575e7677a6cf523e92f8',
    messagingSenderId: '1014560919657',
    projectId: 'nrtgrup-bca9d',
    authDomain: 'nrtgrup-bca9d.firebaseapp.com',
    storageBucket: 'nrtgrup-bca9d.firebasestorage.app',
    measurementId: 'G-NN84JJYFXY',
  );

}