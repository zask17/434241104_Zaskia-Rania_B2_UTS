import 'package:flutter/material.dart';
import '../widget/custom_widget.dart';
import '../../theme/app_theme.dart' show AppColors;
import '../../data/theme_settings.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: Color(0xFFE0555C)),
        );
        return;
      }

      setState(() => _isLoading = true);

      final String uniqueUserId = await _apiService.generateUserId();

      final Map<String, dynamic> userPayload = {
        'id': uniqueUserId, // Hasil format urutan baru (Contoh: USR-00000004)
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text.trim(),
        'role_id': 3,
      };

      final result = await _apiService.registerUser(userPayload);
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] as String? ?? 'Pendaftaran gagal'), backgroundColor: const Color(0xFFE0555C)),
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

        // Skema token warna dinamis
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
                            child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppColors.amber),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: dynamicTextPrimary)),
                        const SizedBox(height: 6),
                        Text('Join us to manage diagnostics updates', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: dynamicTextMuted)),
                        const SizedBox(height: 32),
                        CustomTextField(controller: _nameController, label: 'Full Name', prefixIcon: Icons.person_outline_rounded),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.isEmpty || !v.contains('@')) ? 'Format email tidak valid' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: dynamicTextMuted),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? 'Password minimal 6 karakter' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          prefixIcon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: dynamicTextMuted),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                        ),
                        const SizedBox(height: 28),
                        CustomPrimaryButton(text: 'Register', isLoading: _isLoading, onPressed: _handleRegister),
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