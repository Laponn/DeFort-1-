import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../ui/shared/glass_widgets.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _showEditProfileSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: appState.userName);
    final emailCtrl = TextEditingController(text: appState.userEmail);
    final phoneCtrl = TextEditingController(text: appState.userPhone);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;
        final textColor = AppColors.textPrimary(isDark);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Text(AppLoc.tr(context, 'Edit Profil'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: nameCtrl,
                    style: TextStyle(color: textColor),
                    validator: Validators.name,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Nama Lengkap'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailCtrl,
                    style: TextStyle(color: textColor),
                    validator: Validators.email,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Alamat Email'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    style: TextStyle(color: textColor),
                    validator: Validators.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Nomor Telepon'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          appState.updateProfile(nameCtrl.text, emailCtrl.text, phoneCtrl.text);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLoc.tr(context, 'Profil Berhasil Diperbarui!')),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAdaptive(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLoc.tr(context, 'Simpan Perubahan')),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final oldPassCtrl = TextEditingController();
        final newPassCtrl = TextEditingController();
        final confirmPassCtrl = TextEditingController();

        bool isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;
        final textColor = AppColors.textPrimary(isDark);

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Text(AppLoc.tr(context, 'Ubah Kata Sandi'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    validator: (val) => Validators.required(val, 'Kata Sandi Saat Ini'),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Kata Sandi Saat Ini'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    validator: Validators.passwordStrong,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Kata Sandi Baru'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    style: TextStyle(color: textColor),
                    validator: (val) => Validators.confirmPassword(val, newPassCtrl.text),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: InputDecoration(
                      labelText: AppLoc.tr(context, 'Konfirmasi Kata Sandi Baru'),
                      labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(AppLoc.tr(context, 'Kata sandi berhasil diperbarui!')),
                            backgroundColor: AppColors.success,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAdaptive(isDark),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppLoc.tr(context, 'Simpan Kata Sandi')),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  void _show2FASheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;
            final textColor = AppColors.textPrimary(isDark);
            final subTextColor = AppColors.textSecondary(isDark);

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: sheetBgColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  Text(AppLoc.tr(context, 'Autentikasi Dua Faktor (2FA)'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(AppLoc.tr(context, 'Amankan akun Anda dengan mewajibkan verifikasi tambahan saat masuk dari perangkat baru.'), style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primaryAdaptive(isDark).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(LucideIcons.smartphone, color: AppColors.primaryAdaptive(isDark)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLoc.tr(context, 'Gunakan Aplikasi Authenticator'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            Text('Google Authenticator, Authy, dll.', style: TextStyle(fontSize: 13, color: subTextColor)),
                          ],
                        ),
                      ),
                      Switch(
                        value: appState.is2FAEnabled,
                        activeColor: AppColors.primaryAdaptive(isDark),
                        onChanged: (val) {
                          appState.toggle2FA();
                          setSheetState(() {});
                          if (val) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(AppLoc.tr(context, '2FA berhasil diaktifkan!')),
                              backgroundColor: AppColors.success,
                            ));
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.bg(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: textColor),
            title: Text(AppLoc.tr(context, 'Akun Saya'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ),
          body: Stack(
            children: [
              Positioned(top: -50, left: -50, child: BackgroundBlob(color: AppColors.blobBlue, size: 250)),
              Positioned(bottom: 100, right: -50, child: BackgroundBlob(color: AppColors.blobRed, size: 300)),
              
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                                child: Text(appState.userName.isNotEmpty ? appState.userName.substring(0, 2).toUpperCase() : 'US', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryAdaptive(isDark))),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.primaryAdaptive(isDark), shape: BoxShape.circle),
                                child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(appState.userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Text(appState.userEmail, style: TextStyle(color: subTextColor)),
                          const SizedBox(height: 8),
                          StatusBadge(text: AppLoc.tr(context, 'Terverifikasi'), color: AppColors.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(AppLoc.tr(context, 'Data Pribadi'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildInfoRow(context, LucideIcons.user, 'Nama Lengkap', appState.userName, onTap: () => _showEditProfileSheet(context)),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildInfoRow(context, LucideIcons.mail, 'Alamat Email', appState.userEmail, onTap: () => _showEditProfileSheet(context)),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildInfoRow(context, LucideIcons.phone, 'Nomor Telepon', appState.userPhone, onTap: () => _showEditProfileSheet(context)),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Text(AppLoc.tr(context, 'Keamanan Akun'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildActionRow(context, LucideIcons.lock, 'Ubah Kata Sandi', onTap: () => _showChangePasswordSheet(context)),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildActionRow(
                            context, 
                            LucideIcons.shieldCheck, 
                            'Autentikasi Dua Faktor (2FA)', 
                            onTap: () => _show2FASheet(context, appState),
                            trailingText: appState.is2FAEnabled ? 'Aktif' : 'Nonaktif',
                            trailingColor: appState.is2FAEnabled ? AppColors.success : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);

                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(AppLoc.tr(context, 'Keluar'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {required VoidCallback onTap}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAdaptive(isDark), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLoc.tr(context, label), style: TextStyle(color: subTextColor, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
              ],
            ),
          ),
          Icon(LucideIcons.edit2, color: subTextColor, size: 16),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, IconData icon, String label, {required VoidCallback onTap, String? trailingText, Color? trailingColor}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryAdaptive(isDark), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(AppLoc.tr(context, label), style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15)),
          ),
          if (trailingText != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(AppLoc.tr(context, trailingText), style: TextStyle(color: trailingColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          Icon(LucideIcons.chevronRight, color: textColor.withOpacity(0.5)),
        ],
      ),
    );
  }
}
