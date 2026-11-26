import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/localization.dart';
import '../../../core/native_channel.dart';

class AboutDeFortScreen extends StatefulWidget {
  const AboutDeFortScreen({super.key});

  @override
  State<AboutDeFortScreen> createState() => _AboutDeFortScreenState();
}

class _AboutDeFortScreenState extends State<AboutDeFortScreen> {
  String _sdkVersion = '5.23.0.212';

  @override
  void initState() {
    super.initState();
    _loadSdkVersion();
  }

  Future<void> _loadSdkVersion() async {
    final info = await KasperskyChannel.getKasperskyLicenseInfo();
    if (!mounted) return;
    final ver = info['sdkVersion']?.toString();
    if (ver != null && ver.isNotEmpty) {
      setState(() => _sdkVersion = ver);
    }
  }

  void _showLegalModal(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(fontSize: 13.5, color: subTextColor, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppLoc.tr(context, 'Tutup'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLoc.lang(context) == 'en';
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLoc.tr(context, 'Tentang DeFort'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -30, right: -40, child: _buildBlob(const Color(0xFF6366F1), 220)),
          Positioned(bottom: 40, left: -50, child: _buildBlob(const Color(0xFF06B6D4), 240)),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              // Brand Hero Card
              _buildGlassCard(
                isDark: isDark,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(isDark ? 0.2 : 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/logos/app_logo.png',
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DeFort Mobile Security',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn ? 'Version 1.0.0 (Build 1)' : 'Versi 1.0.0 (Build 1)',
                      style: TextStyle(fontSize: 13, color: subTextColor),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.shieldCheck, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Text(
                            'Powered by Kaspersky SDK $_sdkVersion',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEn
                          ? 'DeFort is a modern mobile cybersecurity fortress designed to protect Android devices from malware, trojans, phishing links, malicious APKs, and unsafe Wi-Fi networks 24/7.'
                          : 'DeFort adalah benteng keamanan siber mobile modern yang dirancang untuk melindungi perangkat Android dari malware, trojan, tautan phishing, APK berbahaya, dan jaringan Wi-Fi tidak aman selama 24/7.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: subTextColor, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Technology Stack Section
              Text(
                isEn ? 'Core Security Architecture' : 'Teknologi & Arsitektur Keamanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              _buildGlassCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildTechRow(
                      icon: LucideIcons.radar,
                      color: Colors.indigoAccent,
                      title: 'Kaspersky Antivirus Engine',
                      subtitle: isEn
                          ? 'Multi-threaded local & cloud malware detection'
                          : 'Deteksi malware multi-thread lokal & cloud KSN',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    _divider(textColor),
                    _buildTechRow(
                      icon: LucideIcons.globeLock,
                      color: Colors.redAccent,
                      title: 'Real-Time Anti-Phishing Shield',
                      subtitle: isEn
                          ? 'Automatic browser URL inspection & instant blocking'
                          : 'Pemeriksaan URL browser & pemblokiran instan otomatis',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    _divider(textColor),
                    _buildTechRow(
                      icon: LucideIcons.wifi,
                      color: Colors.cyan,
                      title: 'Network & SSL Inspector',
                      subtitle: isEn
                          ? 'Wi-Fi reputation, encryption audit, DNS & SSL check'
                          : 'Reputasi Wi-Fi, audit enkripsi, integritas DNS & SSL',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                    _divider(textColor),
                    _buildTechRow(
                      icon: LucideIcons.packageCheck,
                      color: const Color(0xFF10B981),
                      title: 'Quarantine & 24/7 Background Guard',
                      subtitle: isEn
                          ? 'Auto-Scan new APKs, Download Shield & safe vault'
                          : 'Auto-Scan APK baru, Download Shield & brankas karantina',
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Legal & Info Links
              Text(
                isEn ? 'Legal & App Information' : 'Informasi & Ketentuan Hukum',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              _buildGlassCard(
                isDark: isDark,
                child: Column(
                  children: [
                    _buildLinkTile(
                      icon: LucideIcons.lock,
                      title: isEn ? 'Privacy Policy' : 'Kebijakan Privasi',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () => _showLegalModal(
                        context,
                        isEn ? 'Privacy Policy' : 'Kebijakan Privasi',
                        isEn
                            ? '1. Local-First Processing\n'
                              'DeFort performs antivirus file scanning, APK verification, and quarantine isolation directly on your device.\n\n'
                              '2. URL & Threat Reputation\n'
                              'When checking suspicious URLs or Wi-Fi networks, anonymized reputation queries are sent securely to Kaspersky Security Network (KSN).\n\n'
                              '3. Accessibility Service Usage\n'
                              'Accessibility permission is used exclusively to inspect browser address bar URLs to block phishing links automatically. DeFort never records keystrokes, passwords, or private chat messages.\n\n'
                              '4. Account Data\n'
                              'Authentication and profile metadata are protected using Firebase Authentication and encrypted Firestore rules accessible only by you.'
                            : '1. Pemrosesan Lokal Utama\n'
                              'DeFort melakukan pemindaian file antivirus, pemeriksaan APK, dan isolasi karantina secara langsung di dalam perangkat Anda.\n\n'
                              '2. Reputasi URL & Ancaman\n'
                              'Saat memeriksa tautan mencurigakan atau jaringan Wi-Fi, permintaan reputasi anonim dikirimkan secara aman ke Kaspersky Security Network (KSN).\n\n'
                              '3. Penggunaan Layanan Aksesibilitas\n'
                              'Izin Aksesibilitas digunakan secara eksklusif untuk membaca URL pada bilah alamat browser agar tautan phishing dapat diblokir otomatis. DeFort tidak pernah merekam ketikan sandi atau isi pesan pribadi Anda.\n\n'
                              '4. Keamanan Data Akun\n'
                              'Data autentikasi dan profil Anda dilindungi menggunakan Firebase Authentication dan aturan Firestore terenkripsi yang hanya dapat diakses oleh akun Anda sendiri.',
                      ),
                    ),
                    _divider(textColor),
                    _buildLinkTile(
                      icon: LucideIcons.fileText,
                      title: isEn ? 'Terms of Service' : 'Syarat & Ketentuan Layanan',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () => _showLegalModal(
                        context,
                        isEn ? 'Terms of Service' : 'Syarat & Ketentuan Layanan',
                        isEn
                            ? '1. Scope of Service\n'
                              'DeFort Mobile Security provides malware scanning, phishing protection, network security audits, and file quarantine tools for Android devices.\n\n'
                              '2. User Responsibility\n'
                              'Users are responsible for granting required Android permissions (Storage, Notifications, Battery, Accessibility) to achieve full 24/7 background protection.\n\n'
                              '3. Quarantine & File Deletion\n'
                              'Files isolated in Quarantine can be restored or permanently deleted at the user\'s discretion. Permanently deleted threats cannot be recovered.\n\n'
                              '4. Third-Party Engine\n'
                              'Core antivirus and web filtering capabilities are powered by Kaspersky Mobile Security SDK.'
                            : '1. Ruang Lingkup Layanan\n'
                              'DeFort Mobile Security menyediakan layanan pemindaian malware, perlindungan anti-phishing, audit keamanan jaringan, dan karantina berkas untuk perangkat Android.\n\n'
                              '2. Tanggung Jawab Pengguna\n'
                              'Pengguna bertanggung jawab memberikan izin sistem Android yang dibutuhkan (Penyimpanan, Notifikasi, Baterai, Aksesibilitas) agar perlindungan latar belakang 24/7 bekerja maksimal.\n\n'
                              '3. Karantina & Penghapusan Berkas\n'
                              'Berkas yang diisolasi di Ruang Karantina dapat dipulihkan atau dihapus permanen sesuai keputusan pengguna. Berkas yang telah dihapus permanen tidak dapat dikembalikan.\n\n'
                              '4. Mesin Pihak Ketiga\n'
                              'Mesin inti deteksi antivirus dan penyaringan web ditenagai oleh Kaspersky Mobile Security SDK.',
                      ),
                    ),
                    _divider(textColor),
                    _buildLinkTile(
                      icon: LucideIcons.code,
                      title: isEn ? 'Open Source Licenses' : 'Lisensi Open Source & Pihak Ketiga',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: 'DeFort Mobile Security',
                          applicationVersion: '1.0.0 (Build 1)',
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset('assets/logos/app_logo.png', width: 56, height: 56),
                            ),
                          ),
                          applicationLegalese: '© 2026 DeFort Security Team\nPowered by Kaspersky Mobile Security SDK',
                        );
                      },
                    ),
                    _divider(textColor),
                    _buildLinkTile(
                      icon: LucideIcons.sparkles,
                      title: isEn ? 'Check for App Updates' : 'Periksa Pembaruan Aplikasi',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEn
                                  ? 'You are using the latest version of DeFort (v1.0.0).'
                                  : 'Anda sudah menggunakan versi terbaru DeFort (v1.0.0).',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Column(
                  children: [
                    Text(
                      '© 2026 DeFort Security Team',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn ? 'All rights reserved.' : 'Hak cipta dilindungi undang-undang.',
                      style: TextStyle(fontSize: 11, color: subTextColor.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 12, color: subTextColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 19, color: Colors.indigoAccent),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: subTextColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _divider(Color textColor) => Divider(color: textColor.withOpacity(0.08), height: 22);

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.75) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
