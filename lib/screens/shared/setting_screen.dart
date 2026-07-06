import 'package:flutter/material.dart';
import '../../data/theme_settings.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _isNotificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Preferensi Servis', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Notifikasi Status Laptop'),
            subtitle: const Text('Dapatkan notifikasi pemberitahuan status tiket'),
            value: _isNotificationEnabled,
            activeColor: Colors.orange,
            onChanged: (bool value) {
              setState(() {
                _isNotificationEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Tampilan & Tema', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Mode Tema'),
            subtitle: Text('Mode saat ini: ${ThemeSettings.themeMode.value.name.toUpperCase()}'), // Integrasi state dark/light mode
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showThemeDialog(context);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Tentang Aplikasi', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versi Aplikasi'),
            trailing: Text('v1.0.2 Servis-Tech', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('Ikuti Sistem Device'),
              onTap: () {
                ThemeSettings.toggleTheme(ThemeMode.system); //[cite: 18]
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Mode Terang (Light)'),
              onTap: () {
                ThemeSettings.toggleTheme(ThemeMode.light); //[cite: 18]
                Navigator.pop(context);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Mode Gelap (Dark)'),
              onTap: () {
                ThemeSettings.toggleTheme(ThemeMode.dark); //[cite: 18]
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}