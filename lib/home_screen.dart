import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';
import 'auth/biometric_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

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

  Future<void> _authenticate() async {
    try {
      bool authenticated = await localAuth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      print("Authenticated: $authenticated");

      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication successful!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication failed!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on PlatformException catch (e) {
      print("Authentication error: $e");
    }
  }

  Future<void> _getAvailableBiometrics() async {
    try {
      List<BiometricType> availableBiometrics = await localAuth
          .getAvailableBiometrics();
      print("Available biometrics: $availableBiometrics");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Biometrics: $availableBiometrics")),
      );
    } catch (e) {
      print("Error getting biometrics: $e");
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
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 150),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 100,
                    height: 42,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: const Color(0xFFFFF290),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _isSigningOut ? null : _handleSignOut,
                      child: _isSigningOut
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFFF290),
                                ),
                              ),
                            )
                          : const Text(
                              "Sign Out",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 150),
            const Text(
              "Welcome User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _supportState
                      ? 'This Device is Supported'
                      : 'This Device is not Supported',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _getAvailableBiometrics,
                  child: const Text('Get Available Biometrics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                ElevatedButton(
                  onPressed: _authenticate,
                  child: const Text('Authenticate'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.black87,
          shape: const CircleBorder(),
          child: const Icon(Icons.map_outlined, color: Colors.white, size: 35),
          onPressed: () {
            // handle map button tap
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        elevation: 5,
        shadowColor: Colors.black87,
        shape: const CircularNotchedRectangle(),
        color: Colors.black87,
        notchMargin: 8.0,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  // handle Explore tap
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.explore_outlined,
                      color: Color(0xFFFFF290),
                      size: 26,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Explore",
                      style: TextStyle(fontSize: 14, color: Color(0xFFFFF290)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () {
                  // handle Favorites tap
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.favorite_border,
                      color: Color(0xFFFFF290),
                      size: 26,
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Favorites",
                      style: TextStyle(fontSize: 14, color: Color(0xFFFFF290)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
