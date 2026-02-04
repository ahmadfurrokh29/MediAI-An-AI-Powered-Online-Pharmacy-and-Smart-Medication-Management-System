import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:med/data/repositories/authentication/authentication_repository.dart';
import 'package:med/firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  // Widget Bindings
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  // todo: Init Local Storage
  await GetStorage.init();
  // Await Native Splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((FirebaseApp value) => Get.put(AuthenticationRepository()));
  // Ensure Firebase Auth uses a concrete locale to avoid repeated
  // "Ignoring header X-Firebase-Locale because its value was null" logs.
  try {
    FirebaseAuth.instance.setLanguageCode('en');
  } catch (_) {
    // ignore: avoid_print
    print('[main] Could not set FirebaseAuth language code');
  }
  // todo: Initialize Authentication
  runApp(const App());
}
