import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurant_explorer_nepal/deep_link_listener.dart';
import 'package:restaurant_explorer_nepal/screens/explore/explore_screen.dart';
import 'package:restaurant_explorer_nepal/screens/restaurant_detail_screen.dart';
import 'package:restaurant_explorer_nepal/wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/list': (context) => const ExploreScreen(),
        '/details': (context) =>
            const RestaurantDetailScreen(restaurantId: 'undefined'),
      },
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
      home: DeepLinkListener(child: Wrapper()),
      // Remove all routes - we'll handle navigation through bottom nav
    );
  }
}
