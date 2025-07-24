import 'package:shared_preferences/shared_preferences.dart';

class BiometricHelper {
  static const String _key = 'useBiometrics';
  static const String _promptedKey = 'biometricPrompted';

  static Future<void> setBiometricPreference(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
    await prefs.setBool(_promptedKey, true); // track prompt
  }

  static Future<bool> getBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<bool> wasPromptedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptedKey) ?? false;
  }
}
