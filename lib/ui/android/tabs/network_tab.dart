import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/permissions.dart';
import '../../../core/scan_history.dart';
import '../../../ui/shared/glass_widgets.dart';

class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  bool _isChecking = false;
  String _currentWifiName = 'Mencari...';
  Timer? _wifiTimer;
  
  String _wifiStatus = 'Belum Diperiksa';
  String _dnsStatus = 'Belum Diperiksa';
  String _urlStatus = 'Belum Diperiksa';
  String _sslStatus = 'Belum Diperiksa';

  @override
  void initState() {
    super.initState();
    _requestLocationAndFetchWifi();
    _wifiTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchWifiName();
    });
  }

  @override
  void dispose() {
    _wifiTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationAndFetchWifi() async {
    // Request location permission for Wi-Fi SSID
    await PermissionService.requestLocationPermission();
    _fetchWifiName();
  }

  Future<void> _fetchWifiName() async {
    final wifiName = await KasperskyChannel.getNetworkName();
    if (mounted) {
      setState(() {
        _currentWifiName = wifiName;
      });
    }
  }

  Future<void> _checkNetworkSecurity() async {
    setState(() {
      _isChecking = true;
      _wifiStatus = 'Memeriksa...';
      _dnsStatus = 'Memeriksa...';
      _urlStatus = 'Memeriksa...';
      _sslStatus = 'Memeriksa...';
    });

    final wifiResult = await KasperskyChannel.checkWifiSecurity('current_bssid');
    final dnsResult = await KasperskyChannel.checkDns('google.com');
    final sslResult = await KasperskyChannel.validateSsl('https://google.com');
    final urlCheck = await KasperskyChannel.checkUrlPhishing('https://current-gateway.local');

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      
      if (wifiResult.containsKey('error')) {
        _wifiStatus = 'Gagal (Error SDK)';
      } else {
        bool isWifiSafe = wifiResult['isSafe'] ?? false;
        _wifiStatus = isWifiSafe ? 'Aman (Enkripsi WPA)' : 'Berisiko / Terbuka';
        ScanHistoryService.addRecord(ScanRecord(
          type: 'wifi',
          timestamp: DateTime.now(),
          filesScanned: 0,
          malwareCount: isWifiSafe ? 0 : 1,
          malwareList: isWifiSafe ? [] : ['Jaringan Terbuka/Berisiko'],
          isRealSdk: wifiResult['isRealSdk'] == true,
          folderPath: _currentWifiName,
        ));
      }
      
      if (dnsResult.containsKey('error')) {
        _dnsStatus = 'Gagal (Error SDK)';
      } else {
        bool isDnsSafe = dnsResult['isSafe'] ?? false;
        _dnsStatus = isDnsSafe ? 'Aman (Tidak ada Spoofing)' : 'DNS Tidak Aman';
        ScanHistoryService.addRecord(ScanRecord(
          type: 'dns',
          timestamp: DateTime.now(),
          filesScanned: 0,
          malwareCount: isDnsSafe ? 0 : 1,
          malwareList: isDnsSafe ? [] : ['Spoofing / DNS Berisiko'],
          isRealSdk: dnsResult['isRealSdk'] == true,
          folderPath: 'Gateway DNS',
        ));
      }
      
      if (urlCheck.containsKey('error')) {
        _urlStatus = 'Gagal (Error SDK)';
      } else {
        bool isUrlSafe = urlCheck['isSafe'] ?? false;
        _urlStatus = isUrlSafe ? 'Aman (Tidak ada Phishing)' : 'Berbahaya';
      }
      
      if (sslResult.containsKey('error')) {
        _sslStatus = 'Gagal (Error SDK)';
      } else {
        bool isSslValid = sslResult['isValid'] ?? false;
        _sslStatus = isSslValid ? 'Sertifikat Valid' : 'Sertifikat Invalid';
        ScanHistoryService.addRecord(ScanRecord(
          type: 'ssl',
          timestamp: DateTime.now(),
          filesScanned: 0,
          malwareCount: isSslValid ? 0 : 1,
          malwareList: isSslValid ? [] : ['Sertifikat Tidak Valid / Intersepsi'],
          isRealSdk: sslResult['isRealSdk'] == true,
          folderPath: 'Koneksi TLS/SSL',
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          Positioned(top: -100, right: -50, child: BackgroundBlob(color: AppColors.blobIndigo, size: 300)),
          Positioned(bottom: -50, left: -50, child: BackgroundBlob(color: AppColors.blobTeal, size: 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppLoc.tr(context, 'Keamanan Jaringan'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Pastikan koneksi Wi-Fi Anda aman dari sadapan.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),

                // Hero Card
                GlassCard(
                  child: Column(
                    children: [
                      Icon(LucideIcons.wifi, size: 48, color: AppColors.primaryAdaptive(isDark)),
                      const SizedBox(height: 16),
                      Text(AppLoc.tr(context, 'Wi-Fi Saat Ini'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      Text(_currentWifiName, style: TextStyle(color: subTextColor)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _checkNetworkSecurity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAdaptive(isDark),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isChecking
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(AppLoc.tr(context, 'Analisis Jaringan')),
                        ),
                      )
                    ],
                  )
                ),
                const SizedBox(height: 24),
                Text(AppLoc.tr(context, 'Hasil Analisis Kaspersky'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),
                
                _buildResultRow(context, LucideIcons.shieldCheck, 'Reputasi Wi-Fi', _wifiStatus, _wifiStatus.startsWith('Aman')),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.server, 'Integritas DNS', _dnsStatus, _dnsStatus.startsWith('Aman')),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.search, 'Pemeriksaan URL', _urlStatus, _urlStatus.startsWith('Aman')),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.lock, 'Validasi Sertifikat SSL', _sslStatus, _sslStatus == 'Sertifikat Valid'),

                const SizedBox(height: 100), // Bottom nav padding
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, IconData icon, String title, String status, bool isSafe) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    
    bool isNotChecked = status == 'Belum Diperiksa' || status == 'Not Checked Yet' || status == 'Memeriksa...' || status == 'Checking...';
    Color statusColor = isNotChecked ? AppColors.textSecondary(isDark) : (isSafe ? AppColors.success : AppColors.error);
    
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: AppColors.primaryAdaptive(isDark)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(AppLoc.tr(context, status), style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (!isNotChecked)
            Icon(isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertCircle, color: statusColor),
        ],
      )
    );
  }
}
