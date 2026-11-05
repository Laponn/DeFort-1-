import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../../../main.dart';
import '../../../core/localization.dart';
import '../../../core/native_channel.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _storageGranted = false;
  bool _notificationGranted = false;
  bool _batteryOptimizationIgnored = false;
  bool _accessibilityGranted = false;
  bool _downloadWatcherActive = false;
  bool _isTestingPhishing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    setState(() => _isLoading = true);
    final status = await KasperskyChannel.getDevicePermissionsStatus();
    if (!mounted) return;
    setState(() {
      _storageGranted = status['storage'] ?? false;
      _notificationGranted = status['notification'] ?? false;
      _batteryOptimizationIgnored = status['batteryOptimization'] ?? false;
      _accessibilityGranted = status['accessibility'] ?? false;
      _downloadWatcherActive = status['downloadWatcher'] ?? false;
      _isLoading = false;
    });
  }

  bool get _isAllGranted =>
      _storageGranted &&
      _notificationGranted &&
      _batteryOptimizationIgnored &&
      _accessibilityGranted;

  Future<void> _testPhishingInterception() async {
    setState(() => _isTestingPhishing = true);
    
    final result = await KasperskyChannel.testPhishingDetection(
      url: 'https://secure-login-account-update.xyz/phishing',
      reason: 'Phishing / Fake Banking Portal',
    );

    if (!mounted) return;
    setState(() => _isTestingPhishing = false);

    showDialog(
      context: context,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : Colors.black87;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(LucideIcons.shieldAlert, color: Colors.redAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLoc.tr(context, 'Tautan Phishing Berhasil Dicegah!'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: textColor),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLoc.tr(context, 'DeFort berhasil memblokir akses ke situs berbahaya dan menyelamatkan kredensial Anda.'),
                style: TextStyle(color: textColor.withOpacity(0.85), height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target URL:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.6))),
                    const SizedBox(height: 2),
                    Text(result['url'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Analisis Kaspersky:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor.withOpacity(0.6))),
                    const SizedBox(height: 2),
                    Text(result['reason'] ?? '', style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Notifikasi darurat peringatan juga telah dikirimkan ke bar notifikasi sistem Android Anda.',
                style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.6), fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLoc.tr(context, 'Mengerti')),
            ),
          ],
        );
      },
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
        title: Text(
          AppLoc.tr(context, 'Izin & Perlindungan Latar Belakang'),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: _refreshPermissions,
            tooltip: 'Segarkan Status',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, child: _buildBlob(const Color(0xFF38BDF8), 240)),
          Positioned(bottom: 0, right: 0, child: _buildBlob(const Color(0xFF6366F1), 260)),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header Status Card
                      _buildHeaderStatusCard(context, textColor, isDark),
                      const SizedBox(height: 20),

                      // Section Title: Perizinan
                      Text(
                        AppLoc.tr(context, 'Perizinan Perangkat'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLoc.tr(context, 'Kelola izin agar perlindungan 24/7 tetap aktif'),
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                      const SizedBox(height: 14),

                      // Item 1: Akses Semua Berkas
                      _buildPermissionTile(
                        context: context,
                        isDark: isDark,
                        icon: LucideIcons.folderLock,
                        iconColor: const Color(0xFF38BDF8),
                        title: AppLoc.tr(context, 'Akses Semua File & Folder'),
                        description: AppLoc.tr(
                          context,
                          'Diperlukan untuk memindai berkas terunduh, arsip, dan ransomware di penyimpanan internal.',
                        ),
                        isGranted: _storageGranted,
                        onAction: () async {
                          await KasperskyChannel.requestStoragePermission();
                          await Future.delayed(const Duration(milliseconds: 500));
                          _refreshPermissions();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Item 2: Izin Notifikasi Sistem
                      _buildPermissionTile(
                        context: context,
                        isDark: isDark,
                        icon: LucideIcons.bellRing,
                        iconColor: const Color(0xFFEAB308),
                        title: AppLoc.tr(context, 'Izin Notifikasi Sistem'),
                        description: AppLoc.tr(
                          context,
                          'Wajib agar DeFort dapat memperingatkan Anda saat ada bahaya di latar belakang.',
                        ),
                        isGranted: _notificationGranted,
                        onAction: () async {
                          await KasperskyChannel.requestNotificationPermission();
                          await Future.delayed(const Duration(milliseconds: 500));
                          _refreshPermissions();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Item 3: Abaikan Optimasi Baterai
                      _buildPermissionTile(
                        context: context,
                        isDark: isDark,
                        icon: LucideIcons.batteryCharging,
                        iconColor: const Color(0xFF10B981),
                        title: AppLoc.tr(context, 'Abaikan Optimasi Baterai'),
                        description: AppLoc.tr(
                          context,
                          'Mencegah sistem Android mematikan perlindungan DeFort saat aplikasi ditutup.',
                        ),
                        isGranted: _batteryOptimizationIgnored,
                        onAction: () async {
                          await KasperskyChannel.requestBatteryOptimization();
                          await Future.delayed(const Duration(milliseconds: 500));
                          _refreshPermissions();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Item 4: Layanan Aksesibilitas (Anti-Phishing Otomatis)
                      _buildPermissionTile(
                        context: context,
                        isDark: isDark,
                        icon: LucideIcons.globeLock,
                        iconColor: const Color(0xFF6366F1),
                        title: AppLoc.tr(context, 'Layanan Aksesibilitas Anti-Phishing'),
                        description: AppLoc.tr(
                          context,
                          'Wajib aktif agar DeFort dapat membaca URL di browser secara real-time dan otomatis menutup situs phishing.',
                        ),
                        isGranted: _accessibilityGranted,
                        onAction: () async {
                          await KasperskyChannel.openAccessibilitySettings();
                          await Future.delayed(const Duration(milliseconds: 500));
                          _refreshPermissions();
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section Title: Modul Perlindungan Latar Belakang 24/7
                      Text(
                        AppLoc.tr(context, 'Modul Perlindungan Latar Belakang 24/7'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLoc.tr(
                          context,
                          'Mesin Kaspersky tetap aktif mengawasi perangkat saat aplikasi DeFort ditutup.',
                        ),
                        style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
                      ),
                      const SizedBox(height: 14),

                      // Card 1: Auto-Scan Aplikasi Baru Saat Diinstal
                      _buildAutoScanCard(context, textColor, isDark),
                      const SizedBox(height: 12),

                      // Card 2: Pemantau Folder Unduhan Otomatis
                      _buildDownloadWatcherCard(context, textColor, isDark),
                      const SizedBox(height: 24),

                      // Section Title: Anti-Phishing Real-Time
                      Text(
                        AppLoc.tr(context, 'Perlindungan Anti-Phishing Real-time'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLoc.tr(
                          context,
                          'Mencegah dan menyelamatkan Anda saat tidak sengaja membuka situs/link phishing dari browser atau pesan.',
                        ),
                        style: TextStyle(fontSize: 12, color: subTextColor, height: 1.4),
                      ),
                      const SizedBox(height: 14),

                      // Anti-Phishing Card
                      _buildPhishingProtectionCard(context, textColor, isDark),
                      const SizedBox(height: 40),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusCard(BuildContext context, Color textColor, bool isDark) {
    final statusColor = _isAllGranted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusTitle = _isAllGranted
        ? AppLoc.tr(context, 'Semua Izin Lengkap & Aktif')
        : AppLoc.tr(context, 'Perlindungan Belum Maksimal');
    final statusSubtitle = _isAllGranted
        ? 'Perangkat Anda terlindungi 24/7 di latar belakang oleh mesin Kaspersky.'
        : 'Berikan izin di bawah ini agar pemantauan file dan tautan phishing berjalan penuh saat aplikasi ditutup.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.8) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAllGranted ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 6),
                Text(
                  statusSubtitle,
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onAction,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isGranted ? AppLoc.tr(context, 'Diizinkan') : AppLoc.tr(context, 'Belum Aktif'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGranted ? Colors.greenAccent[700] ?? Colors.green : Colors.orangeAccent[700] ?? Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isGranted)
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(AppLoc.tr(context, 'Berikan Izin'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.65), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoScanCard(BuildContext context, Color textColor, bool isDark) {
    final appState = Provider.of<AppState>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.packagePlus, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLoc.tr(context, 'Auto-Scan Aplikasi Baru (Install Guard)'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLoc.tr(
                    context,
                    'Memindai setiap APK atau aplikasi baru secara otomatis saat dipasang oleh sistem.',
                  ),
                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.65), height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: appState.backgroundProtectionEnabled,
            activeColor: Colors.teal,
            onChanged: (val) => appState.setBackgroundProtection(val),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadWatcherCard(BuildContext context, Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.download, color: Colors.cyan, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLoc.tr(context, 'Pemantau Folder Unduhan (Download Shield)'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLoc.tr(
                    context,
                    'Memantau folder Unduhan secara langsung dan mengisolasi berkas berbahaya.',
                  ),
                  style: TextStyle(fontSize: 11, color: textColor.withOpacity(0.65), height: 1.3),
                ),
              ],
            ),
          ),
          Switch(
            value: _downloadWatcherActive,
            activeColor: Colors.cyan,
            onChanged: (val) async {
              if (val) {
                await KasperskyChannel.startDownloadMonitor();
              } else {
                await KasperskyChannel.stopDownloadMonitor();
              }
              _refreshPermissions();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhishingProtectionCard(BuildContext context, Color textColor, bool isDark) {
    final appState = Provider.of<AppState>(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.globeLock, color: Colors.indigoAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WebFilter Phishing Shield',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      Text(
                        appState.realTimePhishingProtection ? 'Kaspersky Engine Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: appState.realTimePhishingProtection ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: appState.realTimePhishingProtection,
                activeColor: Colors.indigo,
                onChanged: (val) => appState.setPhishingProtection(val),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Saat fitur ini aktif, DeFort menganalisis setiap tautan yang dibuka dari aplikasi pesan (WhatsApp, Telegram, SMS) dan browser. Jika Anda tidak sengaja mengklik tautan phishing bank atau pencuri data, sistem langsung memutus akses dan menampilkan peringatan darurat.',
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.7), height: 1.4),
          ),
          if (!_accessibilityGranted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.triangleAlert, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLoc.tr(
                        context,
                        'Layanan Aksesibilitas belum aktif. Aktifkan agar DeFort dapat otomatis membaca dan menutup tautan phishing di browser Anda.',
                      ),
                      style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.w500, height: 1.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await KasperskyChannel.openAccessibilitySettings();
                      await Future.delayed(const Duration(milliseconds: 500));
                      _refreshPermissions();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(AppLoc.tr(context, 'Aktifkan'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTestingPhishing ? null : _testPhishingInterception,
              icon: _isTestingPhishing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.flaskConical, size: 18),
              label: Text(AppLoc.tr(context, 'Uji Deteksi Phishing')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigoAccent,
                side: const BorderSide(color: Colors.indigoAccent),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

