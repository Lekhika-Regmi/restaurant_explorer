import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_explorer_nepal/wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0xFFFFF290), // pastel yellow
        scaffoldBackgroundColor: const Color(
          0xFFFFFCE6,
        ), // slight background contrast
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFF290),
          primary: const Color(0xFFFFF290),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      home: const Wrapper(),
    );
  }
}
