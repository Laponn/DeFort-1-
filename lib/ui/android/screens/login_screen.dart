import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../ui/shared/glass_widgets.dart';
import '../android_main.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _loginError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    // Clear previous error
    setState(() => _loginError = null);
    
    // Validate form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay for realistic UX
    await Future.delayed(const Duration(milliseconds: 800));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AndroidMainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: BackgroundBlob(color: AppColors.blobIndigo, size: 300)),
          Positioned(bottom: -50, left: -50, child: BackgroundBlob(color: AppColors.blobTeal, size: 250)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLoc.tr(context, 'Selamat Datang Kembali'),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLoc.tr(context, 'Masuk untuk mengelola keamanan perangkat Anda.'),
                      style: TextStyle(color: subTextColor),
                    ),
                    const SizedBox(height: 40),
                    
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: textColor),
                            validator: Validators.email,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: AppLoc.tr(context, 'Alamat Email'),
                              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                              prefixIcon: Icon(LucideIcons.mail, color: subTextColor),
                              filled: false,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                              errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                              focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscureText,
                            style: TextStyle(color: textColor),
                            validator: Validators.password,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: AppLoc.tr(context, 'Kata Sandi'),
                              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                              prefixIcon: Icon(LucideIcons.lock, color: subTextColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? LucideIcons.eyeOff : LucideIcons.eye, color: subTextColor),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                              filled: false,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                              errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                              focusedErrorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                              },
                              child: Text(
                                AppLoc.tr(context, 'Lupa Kata Sandi?'),
                                style: TextStyle(color: AppColors.primaryAdaptive(isDark), fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Login error message
                    if (_loginError != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_loginError!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryAdaptive(isDark),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor: AppColors.primaryAdaptive(isDark).withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                AppLoc.tr(context, 'Masuk'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLoc.tr(context, 'Belum punya akun? '), style: TextStyle(color: subTextColor)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: Text(
                            AppLoc.tr(context, 'Daftar Sekarang'),
                            style: TextStyle(color: AppColors.primaryAdaptive(isDark), fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
