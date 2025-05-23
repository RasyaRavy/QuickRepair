import 'package:flutter/material.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePopup extends StatelessWidget {
  final String username;
  final VoidCallback onClose;

  const WelcomePopup({
    super.key,
    required this.username,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                size: 48.0,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24.0),
            Text(
              '${AppStrings.welcome}, $username!',
              style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Thank you for logging in to QuickRepair. We\'re here to help you report and track facility issues quickly and efficiently.',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to manage welcome popup state
class WelcomePopupManager {
  static const String _welcomePopupShown = 'welcomePopupShown';
  
  // Show welcome popup if not shown before
  static Future<bool> shouldShowWelcomePopup() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_welcomePopupShown) ?? false);
  }
  
  // Mark welcome popup as shown
  static Future<void> markWelcomePopupAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomePopupShown, true);
  }
  
  // Reset welcome popup state (for testing)
  static Future<void> resetWelcomePopupState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomePopupShown, false);
  }
} 