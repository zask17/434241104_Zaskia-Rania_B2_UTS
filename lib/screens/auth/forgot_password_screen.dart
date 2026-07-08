import 'package:flutter/material.dart';
import 'dart:math';
import '../widget/custom_widget.dart';
import '../../theme/app_theme.dart' show AppColors;
import '../../data/theme_settings.dart';
import '../../services/api_service.dart';
import '../../services/email_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();

      // 1. Cek apakah email terdaftar
      final exists = await _apiService.checkEmailExists(email);

      if (!exists) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email tidak terdaftar!'), backgroundColor: Colors.red),
        );
        return;
      }

      // 2. Buat token reset (6 digit angka)
      final randomToken = (Random().nextInt(899999) + 100000).toString();

      // 3. Simpan token ke database Supabase
      final tokenSaved = await _apiService.saveResetToken(email, randomToken);

      if (!tokenSaved) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuat permintaan reset password.'), backgroundColor: Colors.red),
        );
        return;
      }

      // 4. Kirim email via Mailtrap
      final resetLink = "https://ticketing-app.example/reset?email=$email&token=$randomToken";
      print('Attempting to send email to $email with link: $resetLink');
      final success = await EmailService.sendResetPasswordEmail(email, resetLink);

      setState(() => _isLoading = false);

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token reset password telah dikirim ke email Anda!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Pindah ke halaman input password baru
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim email. Silakan coba lagi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: dynamicTextPrimary),
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
                            width: 84, height: 84,
                            decoration: BoxDecoration(
                              color: dynamicSurface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: dynamicBorder, width: 1.2),
                              boxShadow: [BoxShadow(color: AppColors.amber.withOpacity(0.15), blurRadius: 24, spreadRadius: 1)],
                            ),
                            child: const Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.amber),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text('Reset Password', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dynamicTextPrimary)),
                        const SizedBox(height: 8),
                        Text(
                          'Masukkan email servis terdaftar Anda. Kami akan mengirimkan tautan pemulihan sandi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: dynamicTextMuted, fontSize: 13.5),
                        ),
                        const SizedBox(height: 32),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Registered Email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty) ? 'Harap masukkan email' : null,
                        ),
                        const SizedBox(height: 24),
                        CustomPrimaryButton(text: 'Send Reset Link', isLoading: _isLoading, onPressed: _handleResetPassword),
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