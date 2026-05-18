import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDJSYsoxWa0x8MTuPxP8L84InAJWPJFKIM",
      authDomain: "forex-learn-app-9cd4b.firebaseapp.com",
      databaseURL: "https://forex-learn-app-9cd4b-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "forex-learn-app-9cd4b",
      storageBucket: "forex-learn-app-9cd4b.firebasestorage.app",
      messagingSenderId: "817475852364",
      appId: "1:817475852364:web:12a2ff594bb586b3f5fce9"

    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forex Learn',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}