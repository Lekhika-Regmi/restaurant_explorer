import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/auth_screen.dart';
import '../../auth/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  static const id = "account_screen";

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final auth = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isSigningOut = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        // Here you would typically upload to Firebase Storage
        _showSnackBar("Profile picture updated!", Colors.green);
      }
    } catch (e) {
      _showSnackBar("Failed to pick image", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
    }
  }

  String _getInitials() {
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser!.displayName!.substring(0, 1).toUpperCase();
    } else if (currentUser?.email != null && currentUser!.email!.isNotEmpty) {
      return currentUser!.email!.substring(0, 1).toUpperCase();
    }
    return 'U';
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
      _showSnackBar("Sign out failed. Please try again.", Colors.red);
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

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Confirm New Password",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
            onPressed: () {
              if (newPasswordController.text ==
                  confirmPasswordController.text) {
                // Handle password change logic here
                Navigator.pop(context);
                _showSnackBar("Password changed successfully!", Colors.green);
              } else {
                _showSnackBar("Passwords don't match!", Colors.red);
              }
            },
            child: const Text("Change Password"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action cannot be undone. All your data will be permanently deleted. Are you sure you want to delete your account?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation() {
    final TextEditingController confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Final Confirmation",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Type 'DELETE' to confirm account deletion:"),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(
                hintText: "Type DELETE here",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (confirmController.text == "DELETE") {
                Navigator.pop(context);
                // Handle account deletion logic here
                _showSnackBar("Account deletion initiated...", Colors.red);
              } else {
                _showSnackBar("Please type 'DELETE' to confirm", Colors.orange);
              }
            },
            child: const Text(
              "Permanently Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportProblemDialog() {
    final TextEditingController problemController = TextEditingController();
    String selectedCategory = "Bug Report";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Report a Problem"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Problem Category",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: "Bug Report",
                    child: Text("Bug Report"),
                  ),
                  DropdownMenuItem(
                    value: "Feature Request",
                    child: Text("Feature Request"),
                  ),
                  DropdownMenuItem(
                    value: "Account Issue",
                    child: Text("Account Issue"),
                  ),
                  DropdownMenuItem(
                    value: "App Crash",
                    child: Text("App Crash"),
                  ),
                  DropdownMenuItem(value: "Other", child: Text("Other")),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: problemController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Describe the problem",
                  border: OutlineInputBorder(),
                  hintText:
                      "Please provide detailed information about the issue...",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
              onPressed: () {
                if (problemController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _showSnackBar(
                    "Problem report submitted. Thank you!",
                    Colors.green,
                  );
                } else {
                  _showSnackBar("Please describe the problem", Colors.orange);
                }
              },
              child: const Text("Submit Report"),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SecurityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Account",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFFCE6),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFFFF290),
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (currentUser?.photoURL != null
                                  ? NetworkImage(currentUser!.photoURL!)
                                        as ImageProvider
                                  : null),
                        child:
                            _profileImage == null &&
                                currentUser?.photoURL == null
                            ? Text(
                                _getInitials(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: _pickImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.displayName ?? "User Name",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentUser?.email ?? "user@example.com",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Account Settings Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.security,
                    title: "Security",
                    subtitle: "Manage your account security",
                    onTap: _navigateToSecurity,
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.lock,
                    title: "Change Password",
                    subtitle: "Update your password",
                    onTap: _showChangePasswordDialog,
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.report_problem,
                    title: "Report a Problem",
                    subtitle: "Let us know about any issues",
                    onTap: _showReportProblemDialog,
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    subtitle: "Get help and support",
                    onTap: () => _showSnackBar(
                      "Help & Support coming soon!",
                      Colors.blue,
                    ),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip,
                    title: "Privacy Policy",
                    subtitle: "Review our privacy policy",
                    onTap: () => _showSnackBar(
                      "Privacy Policy coming soon!",
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger Zone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _showDeleteAccountDialog,
                      child: const Text(
                        "Permanently Delete Account",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This action cannot be undone. All your data will be permanently deleted.",
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF290).withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }
}

// Security Screen
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security"),
        backgroundColor: const Color(0xFFFFF290),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint, color: Colors.green),
                    title: const Text("Biometric Authentication"),
                    subtitle: const Text("Use fingerprint or face recognition"),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Handle biometric toggle
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.phone_android,
                      color: Colors.blue,
                    ),
                    title: const Text("Two-Factor Authentication"),
                    subtitle: const Text("Add an extra layer of security"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Handle 2FA setup
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.orange),
                    title: const Text("Login History"),
                    subtitle: const Text("View recent login activity"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show login history
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
