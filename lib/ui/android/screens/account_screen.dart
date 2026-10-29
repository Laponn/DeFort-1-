import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import 'login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _showEditProfileSheet(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
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
        final textColor = isDark ? Colors.white : Colors.black87;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(AppLoc.tr(context, 'Edit Profil'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: AppLoc.tr(context, 'Nama Lengkap'),
                    labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: AppLoc.tr(context, 'Alamat Email'),
                    labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneCtrl,
                  style: TextStyle(color: textColor),
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
                      appState.updateProfile(nameCtrl.text, emailCtrl.text, phoneCtrl.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLoc.tr(context, 'Profil Berhasil Diperbarui!'))));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
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
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: sheetBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Text(AppLoc.tr(context, 'Ubah Kata Sandi'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 24),
                
                TextField(
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: AppLoc.tr(context, 'Kata Sandi Saat Ini'),
                    labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: AppLoc.tr(context, 'Kata Sandi Baru'),
                    labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withOpacity(0.3))),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  style: TextStyle(color: textColor),
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
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLoc.tr(context, 'Kata sandi berhasil diperbarui!'))));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
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
            final textColor = isDark ? Colors.white : Colors.black87;
            final subTextColor = isDark ? Colors.white70 : Colors.black54;

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
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  Text(AppLoc.tr(context, 'Autentikasi Dua Faktor (2FA)'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text(AppLoc.tr(context, 'Amankan akun Anda dengan mewajibkan verifikasi tambahan saat masuk dari perangkat baru.'), style: TextStyle(color: subTextColor)),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(LucideIcons.smartphone, color: Colors.indigo),
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
                        activeColor: Colors.indigo,
                        onChanged: (val) {
                          appState.toggle2FA();
                          setSheetState(() {});
                          if (val) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLoc.tr(context, '2FA berhasil diaktifkan!'))));
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
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

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
              Positioned(top: -50, left: -50, child: _buildBlob(const Color(0xFF93C5FD), 250)),
              Positioned(bottom: 100, right: -50, child: _buildBlob(const Color(0xFFFCA5A5), 300)),
              
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
                                child: Text(
                                  appState.userName.isNotEmpty 
                                    ? (appState.userName.length >= 2 ? appState.userName.substring(0, 2) : appState.userName).toUpperCase() 
                                    : 'US', 
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo)
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                                child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(appState.userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Text(appState.userEmail, style: TextStyle(color: subTextColor)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(AppLoc.tr(context, 'Terverifikasi'), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text(AppLoc.tr(context, 'Data Pribadi'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 16),
                    _buildGlassCard(
                      context,
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
                    _buildGlassCard(
                      context,
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
                            trailingColor: appState.is2FAEnabled ? Colors.green : Colors.grey,
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
                          backgroundColor: Colors.red,
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
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.indigoAccent : Colors.indigo, size: 20),
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
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.indigoAccent : Colors.indigo, size: 20),
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
          padding: const EdgeInsets.all(20),
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
