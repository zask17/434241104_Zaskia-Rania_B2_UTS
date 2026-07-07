import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';
import 'theme/app_theme.dart';
import 'data/theme_settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Laptop Repair Helpdesk',
          debugShowCheckedModeBanner: false,
          theme: LaptopServiceTheme.lightTheme,
          darkTheme: LaptopServiceTheme.darkTheme,
          themeMode: currentMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}