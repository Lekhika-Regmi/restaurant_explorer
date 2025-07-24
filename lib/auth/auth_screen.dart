import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';

import '../home_screen.dart';
import '../widgets/my_loader.dart';
import '../widgets/textfield.dart';
import '../widgets/wave_clipper.dart';
import 'auth_service.dart';
import 'biometric_helper.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, required this.isLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  // Loading states
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_email.text.isEmpty || _password.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (!widget.isLogin && _name.text.isEmpty) {
      _showSnackBar("Please enter your name");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isLogin) {
        final user = await _auth.loginUserWithEmailAndPassword(
          _email.text,
          _password.text,
        );
        if (user != null) {
          log("User Logged In");
          await _askBiometricSetup();
          _goToHome();
        } else {
          _showSnackBar("Login failed. Please check your credentials.");
        }
      } else {
        final user = await _auth.createUserWithEmailAndPassword(
          _email.text,
          _password.text,
        );
        if (user != null) {
          log("User Created Successfully");
          _goToHome();
        } else {
          _showSnackBar("Signup failed. Please try again.");
        }
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final userCredential = await AuthService().loginWithGoogle();
      if (userCredential != null) {
        log("Welcome ${userCredential.user?.displayName}");
        _goToHome();
      } else {
        _showSnackBar("Google Sign-In was cancelled");
      }
    } catch (e) {
      _showSnackBar("Google Sign-In failed. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  void _goToHome() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );

  void _switchAuthMode() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => AuthScreen(isLogin: !widget.isLogin)),
  );

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isLogin = widget.isLogin;

    return Scaffold(
      backgroundColor: Colors.yellow[100],
      body: Stack(
        children: [
          ClipPath(
            clipper: BottomWaveClipper(),
            child: Container(
              height: height * 0.4,
              width: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/images/food_icon.png', height: 150),
                  const SizedBox(height: 10),
                  Text(
                    "Welcome to Dishcovery!",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w200,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(height: isLogin ? 80 : 95),
                Text(
                  isLogin ? "Login" : "Sign-Up",
                  style: GoogleFonts.petitFormalScript(
                    fontSize: 50,
                    fontWeight: FontWeight.w200,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 50),
                if (!isLogin) ...[
                  CustomTextField(
                    hint: "Enter Name",
                    label: "Name",
                    controller: _name,
                  ),
                  const SizedBox(height: 20),
                ],
                CustomTextField(
                  hint: "Enter Email",
                  label: "Email",
                  controller: _email,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  hint: "Enter Password",
                  label: "Password",
                  isPassword: true,
                  controller: _password,
                ),
                const SizedBox(height: 30),

                // Login/Signup Button with loading state
                SizedBox(
                  width: 180,
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
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
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
                        : Text(
                            isLogin ? "Login" : "Signup",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                if (isLogin) ...[
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loginWithBiometrics,
                    child: const Text("Login with Biometrics"),
                  ),
                ],

                const SizedBox(height: 10),

                if (isLogin)
                  // Google Sign-In Button with loading state
                  SizedBox(
                    height: 42,
                    child: TextButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.black54,
                                ),
                              ),
                            )
                          : SvgPicture.asset(
                              'assets/images/google_icon.svg',
                              height: 20,
                            ),
                      label: Text(
                        _isGoogleLoading
                            ? "Signing in..."
                            : "Sign in with Google",
                        style: const TextStyle(color: Colors.black54),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                          side: const BorderSide(color: Colors.white70),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                    ),
                    InkWell(
                      onTap: (_isLoading || _isGoogleLoading)
                          ? null
                          : _switchAuthMode,
                      child: Text(
                        "Switch",
                        style: TextStyle(
                          color: (_isLoading || _isGoogleLoading)
                              ? Colors.grey
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),

          // Full screen loading overlay (optional - for critical operations)
          if (_isLoading &&
              false) // Set to true if you want full screen loading
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: MyLoader()),
            ),
        ],
      ),
    );
  }

  Future<void> _askBiometricSetup() async {
    final shouldSetup = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Enable Biometric Login?"),
        content: const Text(
          "Would you like to use biometrics for quick login next time?",
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

    if (shouldSetup == true) {
      await BiometricHelper.setBiometricPreference(true);
    }
  }

  Future<void> _loginWithBiometrics() async {
    final enabled = await BiometricHelper.getBiometricPreference();
    if (!enabled) {
      _showSnackBar("Biometric login not enabled.");
      return;
    }

    final localAuth = LocalAuthentication();
    final canCheck = await localAuth.canCheckBiometrics;

    if (!canCheck) {
      _showSnackBar("Biometric not available.");
      return;
    }

    final didAuthenticate = await localAuth.authenticate(
      localizedReason: "Login with biometrics",
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (didAuthenticate) {
      _goToHome(); // Navigate without password
    } else {
      _showSnackBar("Authentication failed.");
    }
  }
}
