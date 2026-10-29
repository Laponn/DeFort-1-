import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/localization.dart';
import '../screens/account_screen.dart';
import '../screens/login_screen.dart';

class MenuTab extends StatelessWidget {
  const MenuTab({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _buildBlob(const Color(0xFFFDE047), 200)),
          Positioned(bottom: 50, right: -50, child: _buildBlob(const Color(0xFF6EE7B7), 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppLoc.tr(context, 'Pengaturan'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 32),
                
                Consumer<AppState>(
                  builder: (context, appState, _) {
                    return _buildGlassCard(
                      context,
                      child: Column(
                        children: [
                          _buildMenuTile(context, LucideIcons.user, 'Akun Saya', 'Kelola profil & data Anda', isAccount: true),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildMenuTile(context, LucideIcons.crown, 'DeFort Premium', appState.isPremium ? 'Status: Aktif' : 'Tingkatkan untuk perlindungan ekstra', isPremium: true),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildMenuTile(context, LucideIcons.shieldCheck, 'Lisensi Kaspersky', 'Aktif hingga 2027'),
                          Divider(color: textColor.withOpacity(0.1), height: 24),
                          _buildMenuTile(context, LucideIcons.settings, 'Preferensi', 'Bahasa, Tema, Notifikasi', isPreferences: true),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(height: 24),
                _buildGlassCard(
                  context,
                  child: Column(
                    children: [
                      _buildMenuTile(context, LucideIcons.helpCircle, 'Pusat Bantuan', 'FAQ dan dukungan pelanggan'),
                      Divider(color: textColor.withOpacity(0.1), height: 24),
                      _buildMenuTile(context, LucideIcons.info, 'Tentang DeFort', 'Versi 1.0.0 (Powered by Kaspersky)'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildGlassCard(
                  context,
                  child: _buildMenuTile(context, LucideIcons.logOut, 'Keluar dari Akun', 'Akhiri sesi saat ini', isDestructive: true),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showPreferencesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, appState, _) {
            bool isDark = Theme.of(context).brightness == Brightness.dark;
            final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;
            final textColor = isDark ? Colors.white : Colors.black87;

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
                  Text(AppLoc.tr(context, 'Preferensi Aplikasi'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 24),
                  
                  // Dark Mode Toggle
                  Row(
                    children: [
                      Icon(LucideIcons.moon, color: textColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLoc.tr(context, 'Mode Gelap'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            Text(AppLoc.tr(context, 'Tampilan malam hari'), style: TextStyle(color: textColor.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      Switch(
                        value: appState.isDarkMode,
                        activeColor: Colors.indigo,
                        onChanged: (val) => appState.toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Language Toggle
                  Row(
                    children: [
                      Icon(LucideIcons.languages, color: textColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLoc.tr(context, 'Bahasa'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            Text(AppLoc.tr(context, 'Pilih bahasa aplikasi'), style: TextStyle(color: textColor.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      DropdownButton<String>(
                        value: appState.language,
                        dropdownColor: sheetBgColor,
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'id', child: Text('Indonesia')),
                          DropdownMenuItem(value: 'en', child: Text('English')),
                        ],
                        onChanged: (val) {
                          if (val != null) appState.setLanguage(val);
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

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, {bool isDestructive = false, bool isPreferences = false, bool isAccount = false, bool isPremium = false}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () {
        if (isAccount) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
        } else if (isPreferences) {
           _showPreferencesSheet(context);
        } else if (isPremium) {
           _showPremiumSheet(context);
        } else if (isDestructive) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(AppLoc.tr(context, 'Keluar'), style: TextStyle(color: textColor)),
              content: Text(AppLoc.tr(context, 'Apakah Anda yakin ingin keluar dari akun DeFort?'), style: TextStyle(color: textColor)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLoc.tr(context, 'Batal'), style: TextStyle(color: textColor)),
                ),
                ElevatedButton(
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: Text(AppLoc.tr(context, 'Keluar')),
                )
              ],
            )
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: isDark ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Icon(icon, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                ],
              ),
              content: Text(AppLoc.tr(context, 'Anda telah membuka menu ') + AppLoc.tr(context, title) + AppLoc.tr(context, '. Halaman ini masih dalam tahap purwarupa.'), style: TextStyle(color: textColor)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLoc.tr(context, 'Tutup'), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                )
              ],
            )
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: textColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isDestructive ? Colors.red : textColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDestructive ? Colors.red : textColor)),
                  if (subtitle.isNotEmpty) Text(AppLoc.tr(context, subtitle), style: TextStyle(fontSize: 13, color: subTextColor)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: subTextColor.withOpacity(0.3))
          ],
        ),
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

  void _showPremiumSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<AppState>(
          builder: (context, appState, _) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.crown, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Text(AppLoc.tr(context, 'DeFort Premium'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    appState.isPremium 
                      ? AppLoc.tr(context, 'Anda saat ini berlangganan Premium. Semua fitur perlindungan tingkat lanjut telah aktif.')
                      : AppLoc.tr(context, 'Tingkatkan ke Premium untuk membuka semua fitur perlindungan Kaspersky, termasuk VPN tanpa batas dan WebFilter real-time.'),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  if (!appState.isPremium) ...[
                    _buildPremiumFeature(context, 'VPN Cepat Tanpa Batas', isDark),
                    _buildPremiumFeature(context, 'Anti-Phishing Tingkat Lanjut', isDark),
                    _buildPremiumFeature(context, 'Pembaruan Basis Data Prioritas', isDark),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        appState.togglePremium();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(appState.isPremium 
                              ? AppLoc.tr(context, 'Premium berhasil diaktifkan!')
                              : AppLoc.tr(context, 'Langganan Premium dibatalkan.')
                            ),
                            backgroundColor: appState.isPremium ? Colors.green : Colors.red,
                          )
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appState.isPremium ? Colors.red : Colors.amber,
                        foregroundColor: appState.isPremium ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        appState.isPremium 
                          ? AppLoc.tr(context, 'Batalkan Premium')
                          : AppLoc.tr(context, 'Beli Premium - \$9.99/bulan'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildPremiumFeature(BuildContext context, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, color: Colors.green, size: 20),
          const SizedBox(width: 12),
          Text(AppLoc.tr(context, text), style: const TextStyle(fontSize: 15)),
        ],
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
