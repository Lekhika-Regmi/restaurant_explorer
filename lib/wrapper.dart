import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_explorer_nepal/auth/auth_screen.dart';
import 'package:restaurant_explorer_nepal/widgets/bottom_navbar.dart';
import 'package:restaurant_explorer_nepal/widgets/my_loader.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: MyLoader());
        } else if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Authentication Error")),
          );
        } else {
          if (snapshot.data == null) {
            return const AuthScreen(isLogin: true);
          } else {
            // User is authenticated, show main app with bottom navigation
            return const CustomBottomNavBar();
          }
        }
      },
    );
  }
}
