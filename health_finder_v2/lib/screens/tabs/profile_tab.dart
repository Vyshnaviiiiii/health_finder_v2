import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../location_settings_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    (user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? 'User',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '',
                    style: const TextStyle(color: AppTheme.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Settings tiles
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Settings',
                  subtitle: 'Change city or search radius',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LocationSettingsScreen()),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage your notifications',
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Notifications'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NotificationTile(
                            title: 'Nearby blood requests',
                            subtitle: 'Get notified when blood is needed nearby',
                          ),
                          _NotificationTile(
                            title: 'New services added',
                            subtitle: 'When new clinics are added near you',
                          ),
                          _NotificationTile(
                            title: 'App updates',
                            subtitle: 'Important app announcements',
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and info',
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Health Finder',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                        'Helping Indians find health services nearby.\nData powered by Firebase.',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              await auth.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false);
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(
              color: AppTheme.textMuted, fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: onTap,
    );
  }
}

class _NotificationTile extends StatefulWidget {
  final String title;
  final String subtitle;

  const _NotificationTile(
      {required this.title, required this.subtitle});

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(widget.subtitle,
          style:
              const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      value: _enabled,
      activeColor: AppTheme.primary,
      onChanged: (val) => setState(() => _enabled = val),
    );
  }
}
