import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  Future<UserCredential?> loginWithGoogle() async {
    try {
      // 1. Start the sign-in flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // 2. Check if user canceled
      if (googleUser == null) {
        log("Google Sign-In canceled by user.");
        return null;
      }

      // 3. Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      log("Google Sign-In failed: $e");
      return null;
    }
  }

  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      exceptionHandler(e.code);
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<User?> loginUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } on FirebaseAuthException catch (e) {
      exceptionHandler(e.code);
    } catch (e) {
      log("Something went wrong");
    }
    return null;
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log("Something went wrong");
    }
  }
}

exceptionHandler(String code) {
  switch (code) {
    case "invalid-credential":
      log("Your login credentials are invalid");
    case "email-already-in-use":
      log("User already exists");
    default:
      log("Something went wrong");
  }
}
