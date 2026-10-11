import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/settings_service.dart';
import '../widgets/app_card.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can log back in anytime to see your trips.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<AuthService>().logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = context.watch<AuthService>().user;
    final settings = context.watch<SettingsService>();
    final trips = context.watch<BookingService>().items;
    final upcoming = trips.where((b) => b.status == BookingStatus.confirmed).length;
    final isGuest = user?.isGuest ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: cs.primary,
                child: Text(user?.initials ?? '?',
                    style: TextStyle(
                        color: cs.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? 'Guest',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  Text(isGuest ? 'Guest account' : (user?.email ?? ''),
                      style: TextStyle(color: cs.onSurface.withOpacity(0.65))),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat(label: 'Total trips', value: '${trips.length}')),
            const SizedBox(width: 12),
            Expanded(child: _Stat(label: 'Upcoming', value: '$upcoming')),
          ]),
          const SectionTitle('Appearance'),
          AppCard(
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode)),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
            ),
          ),
          const SectionTitle('Preferences'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Flight notifications'),
                subtitle: const Text('Gate changes, delays and reminders'),
                value: settings.notifications,
                onChanged: settings.setNotifications,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Help & support'),
                    content: const Text(
                        'Email: support@skybook.example\nPhone: 1800-000-000 (24×7)'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close')),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About SkyBook'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'SkyBook',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2026 SkyBook (demo app)',
                ),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: isGuest ? cs.primary : AppColors.danger,
              ),
              onPressed: () => _logout(context),
              icon: Icon(isGuest ? Icons.login : Icons.logout),
              label: Text(isGuest ? 'Sign in / Sign up' : 'Log out'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.w800, color: cs.primary)),
        Text(label,
            style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.65))),
      ]),
    );
  }
}
