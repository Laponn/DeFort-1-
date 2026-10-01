import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../ui/shared/glass_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate sending email
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSent = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLoc.tr(context, 'Tautan pemulihan telah dikirim!')),
        backgroundColor: AppColors.success,
      ),
    );

    // Go back after short delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context);
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
          Positioned(top: -50, left: -50, child: BackgroundBlob(color: AppColors.blobRed, size: 300)),
          Positioned(bottom: 100, right: -50, child: BackgroundBlob(color: AppColors.blobOrange, size: 250)),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(LucideIcons.key, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      AppLoc.tr(context, 'Lupa Kata Sandi?'),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLoc.tr(context, 'Masukkan alamat email Anda untuk menerima tautan pemulihan kata sandi.'),
                      style: TextStyle(color: subTextColor),
                    ),
                    const SizedBox(height: 32),
                    
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor),
                        validator: Validators.email,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        enabled: !_isSent,
                        decoration: InputDecoration(
                          labelText: AppLoc.tr(context, 'Alamat Email'),
                          labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                          prefixIcon: Icon(LucideIcons.mail, color: subTextColor),
                          filled: false,
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.warning, width: 2)),
                          errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.error)),
                        ),
                      ),
                    ),

                    if (_isSent) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.checkCircle2, color: AppColors.success),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Email pemulihan telah dikirim ke ${_emailCtrl.text}. Periksa inbox Anda.',
                                style: TextStyle(color: textColor, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isSent) ? null : _sendResetLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor: AppColors.warning.withOpacity(0.5),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                AppLoc.tr(context, _isSent ? 'Terkirim ✓' : 'Kirim Tautan'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
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
