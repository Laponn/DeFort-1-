import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
                            _buildMenuTile(context, LucideIcons.shieldCheck, 'Lisensi Kaspersky', 'Aktif hingga 2027', isLicense: true),
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
                        _buildMenuTile(context, LucideIcons.helpCircle, 'Pusat Bantuan', 'FAQ dan dukungan pelanggan', isHelp: true),
                        Divider(color: textColor.withOpacity(0.1), height: 24),
                        _buildMenuTile(context, LucideIcons.info, 'Tentang DeFort', 'Versi 1.0.0 (Powered by Kaspersky)', isAbout: true),
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
                  
                  // Notifications Toggle
                  Row(
                    children: [
                      Icon(LucideIcons.bellRing, color: textColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLoc.tr(context, 'Notifikasi'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                            Text(AppLoc.tr(context, 'Terima peringatan ancaman instan'), style: TextStyle(color: textColor.withOpacity(0.6))),
                          ],
                        ),
                      ),
                      Switch(
                        value: appState.isNotificationEnabled,
                        activeColor: Colors.indigo,
                        onChanged: (val) => appState.toggleNotifications(),
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

  Widget _buildMenuTile(BuildContext context, IconData icon, String title, String subtitle, {bool isDestructive = false, bool isPreferences = false, bool isAccount = false, bool isPremium = false, bool isLicense = false, bool isHelp = false, bool isAbout = false}) {
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
        } else if (isLicense) {
           _showLicenseSheet(context);
        } else if (isHelp) {
           _showHelpSheet(context);
        } else if (isAbout) {
           _showAboutSheet(context);
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

  void _showLicenseSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
              Row(
                children: [
                  Icon(LucideIcons.shieldCheck, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Text(AppLoc.tr(context, 'Lisensi Kaspersky'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLoc.tr(context, 'Status'), style: TextStyle(color: textColor.withOpacity(0.6))),
                    Text(AppLoc.tr(context, 'Aktif Terverifikasi'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 12),
                    Text(AppLoc.tr(context, 'Kode Lisensi'), style: TextStyle(color: textColor.withOpacity(0.6))),
                    Text('ZCY92-*****-*****-6TAMN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'monospace', color: textColor)),
                    const SizedBox(height: 12),
                    Text(AppLoc.tr(context, 'Masa Berlaku'), style: TextStyle(color: textColor.withOpacity(0.6))),
                    Text('1 Januari 2027', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textColor)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLoc.tr(context, 'Lisensi ini mengaktifkan mesin Antivirus, perlindungan Anti-Phishing real-time, dan pemeriksaan keamanan jaringan melalui Kaspersky Security Network (KSN).'),
                style: TextStyle(color: textColor.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }
    );
  }

  void _showHelpSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                children: [
                  Icon(LucideIcons.helpCircle, color: Colors.indigo, size: 28),
                  const SizedBox(width: 12),
                  Text(AppLoc.tr(context, 'Pusat Bantuan (FAQ)'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _buildFaqItem(context, 'Apa itu DeFort Security?', 'DeFort adalah aplikasi keamanan seluler yang didukung oleh Kaspersky SDK untuk melindungi perangkat Anda dari malware, phishing, dan ancaman jaringan.', textColor, isDark),
                    _buildFaqItem(context, 'Bagaimana cara memindai virus?', 'Buka tab "Pindai" di menu bawah, lalu pilih Pindai Cepat, Pindai Penuh, atau Pindai Folder. Pemindaian akan berjalan secara lokal di perangkat Anda.', textColor, isDark),
                    _buildFaqItem(context, 'Apakah data saya aman?', 'Ya, DeFort Security tidak membagikan data pribadi Anda. Pengecekan URL dan jaringan dilakukan secara anonim melalui Kaspersky Security Network (KSN).', textColor, isDark),
                    _buildFaqItem(context, 'Apa keuntungan DeFort Premium?', 'Premium membuka fitur lanjutan seperti VPN tanpa batas, perlindungan anti-phishing real-time, dan prioritas pembaruan database virus.', textColor, isDark),
                    _buildFaqItem(context, 'Bagaimana cara mengubah kata sandi?', 'Buka "Akun Saya" di menu Pengaturan, lalu pilih "Ubah Kata Sandi". Anda juga dapat mengaktifkan Autentikasi 2-Faktor di sana.', textColor, isDark),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer, Color textColor, bool isDark) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(AppLoc.tr(context, question), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        iconColor: Colors.indigo,
        collapsedIconColor: textColor.withOpacity(0.5),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(AppLoc.tr(context, answer), style: TextStyle(color: textColor.withOpacity(0.7), height: 1.5)),
        ],
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetBgColor = isDark ? Colors.grey[900]! : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: sheetBgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.shield, size: 64, color: Colors.indigo),
              ),
              const SizedBox(height: 24),
              Text('DeFort Security', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Text('Versi 1.0.0', style: TextStyle(color: textColor.withOpacity(0.6))),
              const SizedBox(height: 24),
              Text(
                AppLoc.tr(context, 'DeFort Security adalah aplikasi perlindungan perangkat komprehensif yang dirancang untuk memberikan keamanan maksimal terhadap malware, phishing, dan ancaman cyber lainnya.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor.withOpacity(0.8), height: 1.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.shieldCheck, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Powered by Kaspersky SDK', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('© 2026 DeFort Inc. All rights reserved.', style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5))),
              const SizedBox(height: 24),
            ],
          ),
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
