import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'theme/app_theme.dart';
// import 'data/theme_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Laptop Repair Helpdesk',
      debugShowCheckedModeBanner: false,
      // Mengaitkan tema baru yang bernuansa servis komputer
      theme: LaptopServiceTheme.lightTheme,
      darkTheme: LaptopServiceTheme.darkTheme,
      themeMode: ThemeMode.system, // Menyesuaikan preferensi OS device
      home: const SplashScreen(),
    );
  }
}