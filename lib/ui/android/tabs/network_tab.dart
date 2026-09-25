import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';

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
    _fetchWifiName();
    _wifiTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchWifiName();
    });
  }

  @override
  void dispose() {
    _wifiTimer?.cancel();
    super.dispose();
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

    setState(() {
      _isChecking = false;
      
      if (wifiResult.containsKey('error')) {
        _wifiStatus = 'Gagal (Error SDK)';
      } else {
        bool isWifiSafe = wifiResult['isSafe'] ?? false;
        _wifiStatus = isWifiSafe ? 'Aman (Enkripsi WPA)' : 'Berisiko / Terbuka';
      }
      
      if (dnsResult.containsKey('error')) {
        _dnsStatus = 'Gagal (Error SDK)';
      } else {
        bool isDnsSafe = dnsResult['isSafe'] ?? false;
        _dnsStatus = isDnsSafe ? 'Aman (Tidak ada Spoofing)' : 'DNS Tidak Aman';
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background blobs
          Positioned(top: -100, right: -50, child: _buildBlob(const Color(0xFF818CF8), 300)),
          Positioned(bottom: -50, left: -50, child: _buildBlob(const Color(0xFF34D399), 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppLoc.tr(context, 'Keamanan Jaringan'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Pastikan koneksi Wi-Fi Anda aman dari sadapan.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),

                // Hero Card
                _buildGlassCard(
                  context,
                  child: Column(
                    children: [
                      Icon(LucideIcons.wifi, size: 48, color: isDark ? Colors.indigoAccent : Colors.indigo),
                      const SizedBox(height: 16),
                      Text(AppLoc.tr(context, 'Wi-Fi Saat Ini'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      Text(_currentWifiName, style: TextStyle(color: subTextColor)),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isChecking ? null : _checkNetworkSecurity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.indigoAccent : Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(AppLoc.tr(context, _isChecking ? 'Menganalisis...' : 'Analisis Jaringan')),
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
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultRow(BuildContext context, IconData icon, String title, String status, bool isSafe) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    bool isNotChecked = status == 'Belum Diperiksa' || status == 'Not Checked Yet' || status == 'Memeriksa...' || status == 'Checking...';
    Color statusColor = isNotChecked ? (isDark ? Colors.white54 : Colors.black54) : (isSafe ? Colors.green : Colors.red);
    
    return _buildGlassCard(
      context,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: isDark ? Colors.indigoAccent : Colors.indigo),
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
