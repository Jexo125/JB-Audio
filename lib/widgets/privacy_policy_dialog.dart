import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dialog disabled: always returns false so it never shows on launch
class PrivacyPolicyDialog extends StatefulWidget {
  const PrivacyPolicyDialog({super.key});

  static const String _prefsKey = 'privacy_policy_accepted';
  static const String _firstLaunchKey = 'first_app_launch';

  /// Force auto-accept and return false so the dialog is never displayed
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
    await prefs.setBool(_firstLaunchKey, false);
    return false;
  }

  /// Mark privacy policy as accepted
  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<PrivacyPolicyDialog> createState() => _PrivacyPolicyDialogState();
}

class _PrivacyPolicyDialogState extends State<PrivacyPolicyDialog> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}