import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

/// Compile-time selection also works in the background messaging isolate.
class FirebaseEnvironment {
  static const isDev = String.fromEnvironment('ENVIRONMENT') == 'dev';
  static FirebaseOptions get currentPlatform {
    if (!isDev) return DefaultFirebaseOptions.currentPlatform;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    if (defaultTargetPlatform == TargetPlatform.iOS) return ios;
    throw UnsupportedError('Dev Firebase supports Android and iOS only.');
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyDNgrMR2_SptxlRq8krypYR4ecpuSt3Px0',
    appId: '1:682545581717:android:6cbeb7377befab9a25159c',
    messagingSenderId: '682545581717',
    projectId: 'building-management-dev-7ce57',
    storageBucket: 'building-management-dev-7ce57.firebasestorage.app',
  );
  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyBVibj9rWxYZlDhBHK-q601JeuurDyde4I',
    appId: '1:682545581717:ios:5dbdd0b7e1fa916e25159c',
    messagingSenderId: '682545581717',
    projectId: 'building-management-dev-7ce57',
    storageBucket: 'building-management-dev-7ce57.firebasestorage.app',
    iosBundleId: 'com.j2partners.buildingManageFront.dev',
  );
}
