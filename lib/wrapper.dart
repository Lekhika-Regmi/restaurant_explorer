import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurant_explorer_nepal/auth/auth_screen.dart';
import 'package:restaurant_explorer_nepal/home_screen.dart';
import 'package:restaurant_explorer_nepal/widgets/my_loader.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MyLoader();
          } else if (snapshot.hasError) {
            return const Center(child: Text("Error"));
          } else {
            if (snapshot.data == null) {
              return AuthScreen(isLogin: true);
            } else {
              return HomeScreen();
            }
          }
        },
      ),
    );
  }
}
