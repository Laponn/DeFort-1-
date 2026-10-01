import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../ui/shared/glass_widgets.dart';
import '../android_main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate registration delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Save to provider
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateProfile(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      '+62 -',
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AndroidMainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          Positioned(top: 50, right: -50, child: BackgroundBlob(color: AppColors.blobTeal, size: 300)),
          Positioned(bottom: 50, left: -50, child: BackgroundBlob(color: AppColors.blobIndigo, size: 250)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLoc.tr(context, 'Buat Akun Baru'),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLoc.tr(context, 'Daftar sekarang untuk perlindungan penuh.'),
                      style: TextStyle(color: subTextColor),
                    ),
                    const SizedBox(height: 32),
                    
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameCtrl,
                            style: TextStyle(color: textColor),
                            validator: Validators.name,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: AppLoc.tr(context, 'Nama Lengkap'),
                              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                              prefixIcon: Icon(LucideIcons.user, color: subTextColor),
                              filled: false,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                              errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: TextStyle(color: textColor),
                            validator: Validators.passwordStrong,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: AppLoc.tr(context, 'Kata Sandi'),
                              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                              prefixIcon: Icon(LucideIcons.lock, color: subTextColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePass ? LucideIcons.eyeOff : LucideIcons.eye, color: subTextColor),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                              helperText: 'Minimal 8 karakter, huruf besar, dan angka',
                              helperStyle: TextStyle(color: subTextColor.withOpacity(0.7), fontSize: 11),
                              filled: false,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                              errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            obscureText: _obscureConfirm,
                            style: TextStyle(color: textColor),
                            validator: (val) => Validators.confirmPassword(val, _passCtrl.text),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: AppLoc.tr(context, 'Konfirmasi Kata Sandi Baru'),
                              labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                              prefixIcon: Icon(LucideIcons.lock, color: subTextColor),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye, color: subTextColor),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              filled: false,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                              errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                AppLoc.tr(context, 'Daftar'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
