// Updated home_screen.dart
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:restaurant_explorer_nepal/widgets/bottom_navbar.dart';

import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'auth/biometric_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const id = "home_screen";

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LocalAuthentication localAuth;
  bool _supportState = false;
  final auth = AuthService();
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    localAuth = LocalAuthentication();
    localAuth.isDeviceSupported().then((bool isSupported) {
      setState(() {
        _supportState = isSupported;
      });
    });
    _askBiometricSetupIfFirstTime();
  }

  Future<void> _askBiometricSetupIfFirstTime() async {
    final alreadyPrompted = await BiometricHelper.wasPromptedBefore();
    if (alreadyPrompted) return;

    final enable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enable Biometric Login?"),
        content: const Text(
          "Would you like to enable biometrics for quicker future logins?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No", style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (enable != null) {
      await BiometricHelper.setBiometricPreference(enable);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await auth.signout();
      if (mounted) {
        goToLogin(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sign out failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  void goToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Instead of returning a Scaffold with bottomNavigationBar,
    // return the CustomBottomNavBar directly
    return const CustomBottomNavBar();
  }
}
