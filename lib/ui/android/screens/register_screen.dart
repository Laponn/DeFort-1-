import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import '../android_main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscureText = true;

  void _register() async {
    // Save to provider
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.updateProfile(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User Baru', _emailCtrl.text.isNotEmpty ? _emailCtrl.text : 'user@example.com', '+62 -');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    // Navigate to Home
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AndroidMainScreen()),
        (route) => false,
      );
    }
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLoc.tr(context, 'Buat Akun Baru'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(AppLoc.tr(context, 'Daftar sekarang untuk perlindungan penuh.'), style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 32),
                  
                  _buildGlassCard(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Nama Lengkap'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.user, color: subTextColor),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _emailCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Alamat Email'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.mail, color: subTextColor),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscureText,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: AppLoc.tr(context, 'Kata Sandi'),
                            labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                            prefixIcon: Icon(LucideIcons.lock, color: subTextColor),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureText ? LucideIcons.eyeOff : LucideIcons.eye, color: subTextColor),
                              onPressed: () => setState(() => _obscureText = !_obscureText),
                            ),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLoc.tr(context, 'Daftar'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
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
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container(color: Colors.transparent)),
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
