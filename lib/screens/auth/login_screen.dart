import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../shared/dashboard_screen.dart';
import '../widget/custom_widget.dart';
import '../../theme/app_theme.dart' show AppColors;
import '../../data/theme_settings.dart';
import '../../data/session.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Harap masukkan email';
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _apiService.login(_emailController.text.trim(), _passwordController.text.trim());
      setState(() => _isLoading = false);

      if (result['success'] == true && result['data'] != null) {
        Session.currentUser = User.fromJson(result['data'] as Map<String, dynamic>);
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] as String? ?? 'Login gagal'),
            backgroundColor: const Color(0xFFE0555C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        // Deteksi secara real-time apakah tema saat ini adalah Dark Mode
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        // Skema warna dinamis berdasarkan status tema aktif
        final dynamicBgDeep = isDark ? AppColors.bgDeep : const Color(0xFFF4F6F9);
        final dynamicBgElevated = isDark ? AppColors.bgElevated : const Color(0xFFE2E8F0);
        final dynamicSurface = isDark ? AppColors.surface : Colors.white;
        final dynamicBorder = isDark ? AppColors.border : const Color(0xFFCBD5E1);
        final dynamicTextPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
        final dynamicTextMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: dynamicTextPrimary,
                ),
                onPressed: () => ThemeSettings.toggleTheme(isDark ? ThemeMode.light : ThemeMode.dark),
              ),
            ],
          ),
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 300), // Efek transisi smooth saat ganti tema
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [dynamicBgDeep, dynamicBgElevated],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: dynamicSurface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: dynamicBorder, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                    color: AppColors.amber.withOpacity(0.15),
                                    blurRadius: 24,
                                    spreadRadius: 1
                                )
                              ],
                            ),
                            child: const Icon(Icons.laptop_mac_rounded, size: 40, color: AppColors.amber),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dynamicTextPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to track your repair status',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, color: dynamicTextMuted),
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: dynamicTextMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (value) => (value == null || value.isEmpty) ? 'Harap masukkan password' : null,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.amber),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                            child: const Text('Forgot Password?'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomPrimaryButton(text: 'Login', isLoading: _isLoading, onPressed: _handleLogin),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account?", style: TextStyle(color: dynamicTextMuted)),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.amber),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                              child: const Text('Register'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}