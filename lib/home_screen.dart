import 'package:flutter/material.dart';

import 'auth/auth_screen.dart';
import 'auth/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final auth = AuthService();
  bool _isSigningOut = false;

  void _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await auth.signout();
      if (mounted) {
        goToLogin(context);
      }
    } catch (e) {
      // Show error message if sign out fails
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome User",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 20),

            // Sign Out Button with loading state
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          backgroundColor: Colors.black87,
          shape: CircleBorder(),
          child: Icon(Icons.map_outlined, color: Colors.white, size: 35),
          onPressed: () {
            // handle tap
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
              // Home
              GestureDetector(
                onTap: () {
                  // handle Home tap
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
              const SizedBox(width: 40), // space for FAB
              // More
              GestureDetector(
                onTap: () {
                  // handle More tap
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

  goToLogin(BuildContext context) => Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: true)),
  );
}
