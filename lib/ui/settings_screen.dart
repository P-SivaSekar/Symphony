import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/player_service.dart';
import 'global_background.dart';
import 'change_password_screen.dart';
import 'glassmorphic_component.dart';
import 'yt_music_player.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final playerService = Provider.of<PlayerService>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          const GlobalBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                 _buildSectionHeader("Appearance", textColor, primaryColor),
                _buildListTile(
                  icon: Icons.color_lens,
                  title: "Theme",
                  subtitle: _getThemeString(appProvider.themeMode),
                  textColor: textColor,
                  onTap: () => _showThemeSelectionDialog(context, appProvider),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader("Account", textColor, primaryColor),
                _buildListTile(
                  icon: Icons.lock,
                  title: "Change Password",
                  subtitle: "Update your account password",
                  textColor: textColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.logout,
                  title: "Logout",
                  subtitle: "Sign out of your Symphony account",
                  textColor: textColor,
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    appProvider.logout();
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("Notifications", textColor, primaryColor),
                _buildSwitchTile(
                  context: context,
                  icon: Icons.notifications_active,
                  title: "Push Notifications",
                  subtitle: "Enable or disable local notifications",
                  textColor: textColor,
                  value: appProvider.notificationsEnabled,
                  onChanged: (val) {
                    appProvider.toggleNotifications();
                  },
                ),
                const SizedBox(height: 24),
                _buildSectionHeader("Playback", textColor, primaryColor),
                _buildSwitchTile(
                  context: context,
                  icon: Icons.auto_awesome,
                  title: "Autoplay",
                  subtitle: "Play similar songs when queue ends",
                  textColor: textColor,
                  value: playerService.autoplayEnabled,
                  onChanged: (val) {
                    playerService.toggleAutoplay();
                  },
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          title: Text(
            title,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13),
          ),
          trailing: Icon(Icons.chevron_right, color: textColor.withOpacity(0.5)),
          onTap: onTap,
        ),
      ),
    );
  }

  String _getThemeString(ThemeMode mode) {
    if (mode == ThemeMode.light) return "Light";
    if (mode == ThemeMode.dark) return "Dark";
    return "System";
  }

  void _showThemeSelectionDialog(BuildContext context, AppProvider appProvider) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Select Theme",
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeRadio(
                context: context,
                title: "System default",
                value: ThemeMode.system,
                groupValue: appProvider.themeMode,
                onChanged: (val) {
                  appProvider.setTheme(val!);
                  Navigator.pop(context);
                },
              ),
              _buildThemeRadio(
                context: context,
                title: "Light",
                value: ThemeMode.light,
                groupValue: appProvider.themeMode,
                onChanged: (val) {
                  appProvider.setTheme(val!);
                  Navigator.pop(context);
                },
              ),
              _buildThemeRadio(
                context: context,
                title: "Dark",
                value: ThemeMode.dark,
                groupValue: appProvider.themeMode,
                onChanged: (val) {
                  appProvider.setTheme(val!);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildThemeRadio({
    required BuildContext context,
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    final theme = Theme.of(context);
    return RadioListTile<ThemeMode>(
      title: Text(
        title,
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SwitchListTile(
          activeColor: Theme.of(context).colorScheme.primary,
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 24),
          ),
          title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
