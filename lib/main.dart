import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

export 'app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    debugPrint('Firebase init error: ${error.message ?? error.code}');
  } on UnsupportedError catch (error) {
    debugPrint('Firebase platform configuration error: $error');
  }
  runApp(const MyApp());
}
