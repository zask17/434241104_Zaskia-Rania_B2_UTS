import 'package:flutter/material.dart';
import '../../theme/app_theme.dart' show AppColors;
import '../../data/theme_settings.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    // Gunakan ValueListenableBuilder agar kolom input langsung merespons saat tombol ganti tema diklik
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeSettings.themeMode,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark ||
            (currentMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

        // Skema token warna reaktif khusus untuk komponen input teks
        final dynamicSurface = isDark ? AppColors.surface : Colors.white;
        final dynamicBorder = isDark ? AppColors.border : const Color(0xFFCBD5E1);
        final dynamicTextPrimary = isDark ? AppColors.textPrimary : const Color(0xFF0F172A);
        final dynamicTextMuted = isDark ? AppColors.textMuted : const Color(0xFF64748B);

        OutlineInputBorder buildBorder(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

        return TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: dynamicTextPrimary),
          cursorColor: AppColors.amber,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: dynamicTextMuted),
            filled: true,
            fillColor: dynamicSurface,
            prefixIcon: Icon(prefixIcon, color: dynamicTextMuted, size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            border: buildBorder(dynamicBorder, 1),
            enabledBorder: buildBorder(dynamicBorder, 1),
            focusedBorder: buildBorder(AppColors.amber, 1.6),
            errorBorder: buildBorder(const Color(0xFFE0555C), 1.2),
            focusedErrorBorder: buildBorder(const Color(0xFFE0555C), 1.6),
          ),
        );
      },
    );
  }
}

class CustomPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CustomPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          disabledBackgroundColor: AppColors.amber.withOpacity(0.5),
          foregroundColor: const Color(0xFF121824), // Teks tombol tetap gelap kontras di atas kuning amber
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF121824),
          ),
        )
            : Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
        ),
      ),
    );
  }
}