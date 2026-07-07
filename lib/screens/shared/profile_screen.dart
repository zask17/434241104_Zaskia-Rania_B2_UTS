import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import '../shared/setting_screen.dart';
import '../../data/session.dart';
import '../../data/theme_settings.dart';
import '../../theme/app_theme.dart' show AppColors;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.currentUser;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        final dynamicBgDeep = isDark ? AppColors.bgDeep : const Color(0xFFF4F6F9);
        final dynamicBgElevated = isDark ? AppColors.bgElevated : const Color(0xFFE2E8F0);
        final dynamicSurface = isDark ? AppColors.surface : Colors.white;
        final dynamicBorder = isDark ? AppColors.border : const Color(0xFFCBD5E1);
        final dynamicTextPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
        final dynamicTextMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            foregroundColor: dynamicTextPrimary,
            elevation: 0,
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [dynamicBgDeep, dynamicBgElevated],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.amber.withOpacity(0.15),
                    child: const Icon(Icons.person_rounded, size: 46, color: AppColors.amber),
                  ),
                ),
                const SizedBox(height: 14),
                Text(user?.name ?? 'Guest', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dynamicTextPrimary)),
                Text(user?.email ?? '-', style: TextStyle(color: dynamicTextMuted, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('ROLE: ${user?.role.name.toUpperCase()}', style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),

                // MENU OPSI DENGAN STYLE SIBER MODERN
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: dynamicSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dynamicBorder, width: 0.8),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.settings_outlined, color: AppColors.amber),
                          title: Text('Pengaturan Aplikasi', style: TextStyle(color: dynamicTextPrimary, fontWeight: FontWeight.w500)),
                          trailing: Icon(Icons.chevron_right_rounded, color: dynamicTextMuted),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingScreen())),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.help_outline_rounded, color: AppColors.amber),
                          title: Text('Pusat Bantuan', style: TextStyle(color: dynamicTextPrimary, fontWeight: FontWeight.w500)),
                          trailing: Icon(Icons.chevron_right_rounded, color: dynamicTextMuted),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.palette_outlined, color: AppColors.amber),
                          title: Text('Ganti Tema Tampilan', style: TextStyle(color: dynamicTextPrimary, fontWeight: FontWeight.w500)),
                          subtitle: Text('Mode Aktif: ${currentMode.name.toUpperCase()}', style: TextStyle(color: dynamicTextMuted, fontSize: 12)),
                          trailing: Icon(Icons.chevron_right_rounded, color: dynamicTextMuted),
                          onTap: () => _showThemeDialog(context, isDark, dynamicSurface, dynamicTextPrimary),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Session.clear();
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0555C),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeDialog(BuildContext context, bool isDark, Color surface, Color textPrimary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Pilih Tema Aplikasi', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.brightness_auto_rounded, color: AppColors.amber),
              title: Text('Sistem Device', style: TextStyle(color: textPrimary)),
              onTap: () { ThemeSettings.toggleTheme(ThemeMode.system); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.light_mode_rounded, color: AppColors.amber),
              title: Text('Mode Terang', style: TextStyle(color: textPrimary)),
              onTap: () { ThemeSettings.toggleTheme(ThemeMode.light); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: AppColors.amber),
              title: Text('Mode Gelap', style: TextStyle(color: textPrimary)),
              onTap: () { ThemeSettings.toggleTheme(ThemeMode.dark); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}