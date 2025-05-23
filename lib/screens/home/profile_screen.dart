import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickrepair/constants/routes.dart';
import 'package:quickrepair/constants/strings.dart';
import 'package:quickrepair/services/supabase_service.dart';
import 'package:quickrepair/services/theme_provider.dart'; // Import ThemeProvider
// import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase.instance is available via SupabaseService

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      // Corrected: Call static signOut method
      await SupabaseService.signOut();
      // Navigate to login screen and remove all previous routes
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access currentUser via SupabaseService
    final user = SupabaseService.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false, // No back button if it's a main tab
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: <Widget>[
          if (user != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                subtitle: Text(user.email ?? 'N/A'),
              ),
            ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: Theme.of(context).iconTheme.color),
                  title: const Text(AppStrings.editProfile),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to Edit Profile Screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.featureComingSoon)),
                    );
                  },
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                ListTile(
                  leading: Icon(Icons.notifications_outlined, color: Theme.of(context).iconTheme.color),
                  title: const Text(AppStrings.notifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to Notifications Settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(AppStrings.featureComingSoon)),
                    );
                  },
                ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                // Settings ListTile - can navigate to a dedicated SettingsScreen later
                ListTile(
                  leading: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color),
                  title: const Text(AppStrings.settings),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Navigate to a dedicated SettingsScreen
                    // For now, can show a dialog or do nothing
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings placeholder - Theme toggle is below.')),
                    );
                  },
                ),
                 const Divider(height: 0, indent: 16, endIndent: 16),
                // Dark Mode Toggle
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeProvider.toggleTheme();
                  },
                  secondary: Icon(
                    themeProvider.themeMode == ThemeMode.dark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                     color: Theme.of(context).iconTheme.color
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: Icon(Icons.help_outline, color: Theme.of(context).iconTheme.color),
              title: const Text(AppStrings.help),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to Help/Support Screen or show a dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.featureComingSoon)),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white), // Ensure icon color contrasts with button
            label: const Text(AppStrings.logout),
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, // Or Theme.of(context).colorScheme.error
              foregroundColor: Colors.white,      // Ensure text color contrasts
              padding: const EdgeInsets.symmetric(vertical: 12),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 