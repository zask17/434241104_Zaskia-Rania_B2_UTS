import 'package:flutter/material.dart';
import 'login_screen.dart';

// ---- Design tokens (shared "look" for this app) --------------------------
// Deep navy chassis + electric cyan (diagnostic scan) + amber (power LED).
class AppColors {
  static const bgDeep = Color(0xFF0B1220);
  static const bgElevated = Color(0xFF141B2D);
  static const surface = Color(0xFF1B2438);
  static const border = Color(0xFF2A3550);
  static const cyan = Color(0xFF22D3EE);
  static const amber = Color(0xFFF2A93B);
  static const textPrimary = Color(0xFFEAF0F7);
  static const textMuted = Color(0xFF8592A8);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDeep, AppColors.bgElevated],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device chip with animated diagnostic scanline
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                            color: AppColors.border.withOpacity(0.9), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.18),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.laptop_mac_rounded,
                      size: 64,
                      color: AppColors.cyan,
                    ),
                    // Scanline
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
                                    AppColors.cyan.withOpacity(0),
                                    AppColors.cyan.withOpacity(0.9),
                                    AppColors.cyan.withOpacity(0),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Power LED
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.amber.withOpacity(0.8),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Ticketing Service',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: AppColors.textPrimary,
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
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}