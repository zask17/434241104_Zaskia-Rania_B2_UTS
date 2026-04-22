import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../data/session.dart';
import '../data/theme_settings.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: Column(
        children: [
          const SizedBox(height: 32),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(user?.name ?? 'Guest', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(user?.email ?? '-', style: const TextStyle(color: Colors.grey)),
          Text(
            'Role: ${user?.role.name.toUpperCase()}',
            style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Pengaturan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Pusat Bantuan'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Ganti Tema'),
            subtitle: Text('Mode saat ini: ${ThemeSettings.themeMode.value.name.toUpperCase()}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pilih Tema'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_auto),
                        title: const Text('Sistem'),
                        onTap: () {
                          ThemeSettings.toggleTheme(ThemeMode.system);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_low),
                        title: const Text('Terang (Light)'),
                        onTap: () {
                          ThemeSettings.toggleTheme(ThemeMode.light);
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.brightness_2),
                        title: const Text('Gelap (Dark)'),
                        onTap: () {
                          ThemeSettings.toggleTheme(ThemeMode.dark);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Session.currentUser = null;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
