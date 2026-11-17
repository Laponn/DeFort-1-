import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import '../../../core/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final confirmPassword = _confirmPassCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar("Nama, email, dan kata sandi wajib diisi!", isError: true);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showSnackBar("Masukkan format alamat email yang valid!", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Kata sandi minimal harus 6 karakter!", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Konfirmasi kata sandi tidak cocok!", isError: true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    String? result = await AuthService().registerUser(
      email: email,
      password: password,
      nama: name,
      phone: phone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result == "Sukses") {
      context.read<AppState>().reloadFromPrefs();
      _showSnackBar("Registrasi berhasil! Silakan masuk dengan akun Anda.", isError: false);
      Navigator.pop(context, email);
    } else {
      _showSnackBar(result ?? "Terjadi kesalahan saat mendaftar.", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          Positioned(top: 50, right: -50, child: _buildBlob(const Color(0xFF34D399), 300)),
          Positioned(bottom: 50, left: -50, child: _buildBlob(const Color(0xFF818CF8), 250)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/logos/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLoc.tr(context, 'Buat Akun Baru'),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLoc.tr(context, 'Daftar sekarang untuk perlindungan penuh.'),
                    style: TextStyle(color: subTextColor),
                  ),
                  const SizedBox(height: 28),

                  _buildGlassCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Nama Lengkap'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.user, color: subTextColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Alamat Email'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.mail, color: subTextColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Nomor Telepon (Opsional)'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.phone, color: subTextColor),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Kata Sandi'),
                            helperText: AppLoc.tr(context, 'Minimal 6 karakter'),
                            helperStyle: TextStyle(color: subTextColor, fontSize: 11),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.lock, color: subTextColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass ? LucideIcons.eyeOff : LucideIcons.eye,
                                color: subTextColor,
                              ),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPassCtrl,
                          obscureText: _obscureConfirmPass,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _isLoading ? null : _register(),
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Konfirmasi Kata Sandi'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.shieldCheck, color: subTextColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPass ? LucideIcons.eyeOff : LucideIcons.eye,
                                color: subTextColor,
                              ),
                              onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: textColor.withOpacity(0.3)),
                            ),
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
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.indigo.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppLoc.tr(context, 'Daftar'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppLoc.tr(context, 'Sudah punya akun? '), style: TextStyle(color: subTextColor)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          AppLoc.tr(context, 'Masuk Sekarang'),
                          style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required Widget child}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.8)),
          ),
          child: child,
        ),
      ),
    );
  }
}
