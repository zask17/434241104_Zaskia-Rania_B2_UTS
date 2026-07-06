import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _navigateToLogin();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background otomatis menyesuaikan dengan skema warna sistem/pilihan user
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: theme.dividerColor.withOpacity(0.2),
                          width: 1.4
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.laptop_mac_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  // Scanline Animasi
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: AnimatedBuilder(
                      animation: _scanController,
                      builder: (context, child) {
                        return Align(
                          alignment: Alignment(0, -1 + 2 * _scanController.value),
                          child: Container(
                            height: 3,
                            width: 140,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0),
                                  theme.colorScheme.primary.withOpacity(0.8),
                                  theme.colorScheme.primary.withOpacity(0),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Ticketing Service',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87 ?? Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'DIAGNOSTICS  •  REPAIRS  •  CARE',
              style: TextStyle(
                fontSize: 11.5,
                fontFamily: 'monospace',
                letterSpacing: 2.2,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}