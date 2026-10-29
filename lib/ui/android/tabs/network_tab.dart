import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'dart:convert';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/net_check.dart';
import '../../../core/database_helper.dart';
import '../../../core/scan_history_item.dart';
import '../screens/history_screen.dart';

class NetworkTab extends StatefulWidget {
  const NetworkTab({super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> with WidgetsBindingObserver {
  bool _isChecking = false;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _eventSub;
  
  // WiFi Info (real data dari device)
  String _wifiSsid = '...';
  String _wifiBssid = '';
  int _signalLevel = 0;
  int _linkSpeed = 0;
  int _frequency = 0;
  String _connectionType = '...';
  bool _isWifiConnected = false;

  bool _ssidAvailable = false;
  String _ssidReason = '';

  // Security check results
  NetCheck _wifiStatus = NetCheck.idle;
  NetCheck _dnsStatus = NetCheck.idle;
  NetCheck _urlStatus = NetCheck.idle;
  NetCheck _sslStatus = NetCheck.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWifiInfo();
    // Auto-refresh WiFi info setiap 10 detik
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadWifiInfo());

    _eventSub = KasperskyChannel.events.listen((event) {
      if (!mounted) return;
      if (event['event'] == 'onNetworkScanStep') {
        final step = event['step'] as String?;
        final data = event['data'] as Map?;
        if (step != null && data != null) {
          final check = NetCheck.fromMap(data);
          setState(() {
            switch (step) {
              case 'wifi':
                _wifiStatus = check;
                break;
              case 'dns':
                _dnsStatus = check;
                break;
              case 'url':
                _urlStatus = check;
                break;
              case 'ssl':
                _sslStatus = check;
                break;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadWifiInfo();
    }
  }

  Future<void> _loadWifiInfo() async {
    final info = await KasperskyChannel.getWifiInfo();
    if (!mounted) return;
    setState(() {
      _isWifiConnected = info['isConnected'] ?? false;
      _wifiSsid = info['ssid'] ?? 'Tidak Diketahui';
      _ssidAvailable = info['ssidAvailable'] ?? true;
      _ssidReason = info['ssidReason'] ?? '';
      _wifiBssid = info['bssid'] ?? '00:00:00:00:00:00';
      _signalLevel = info['signalLevel'] ?? 0;
      _linkSpeed = info['linkSpeed'] ?? -1;
      _frequency = info['frequency'] ?? -1;
      _connectionType = info['connectionType'] ?? 'Tidak Diketahui';
    });
  }

  Future<void> _checkNetworkSecurity() async {
    setState(() {
      _isChecking = true;
      _wifiStatus = NetCheck.checking;
      _dnsStatus = NetCheck.checking;
      _urlStatus = NetCheck.checking;
      _sslStatus = NetCheck.checking;
    });

    // Ambil info WiFi terbaru dulu
    await _loadWifiInfo();

    // Jalankan semua pemeriksaan jaringan (Wi-Fi, DNS, URL, SSL) di dalam Foreground Service
    // sehingga tetap berjalan hingga selesai meskipun aplikasi diminimalkan/ditutup.
    final results = await KasperskyChannel.runFullNetworkScan();
    final wifiRes = results['wifi'] ?? NetCheck.idle;
    final dnsRes = results['dns'] ?? NetCheck.idle;
    final urlRes = results['url'] ?? NetCheck.idle;
    final sslRes = results['ssl'] ?? NetCheck.idle;

    // Simpan ke riwayat/database
    try {
      final allLevels = [wifiRes.level, dnsRes.level, sslRes.level, urlRes.level];
      String overallStatus = 'SAFE';
      if (allLevels.contains('DANGER')) {
        overallStatus = 'DANGER';
      } else if (allLevels.contains('WARNING') || allLevels.contains('ERROR') || allLevels.contains('UNKNOWN')) {
        overallStatus = 'WARNING';
      }

      final detailsJson = jsonEncode({
        'wifi': wifiRes.summary,
        'dns': dnsRes.summary,
        'ssl': sslRes.summary,
        'url': urlRes.summary,
        'reasons': [
          ...wifiRes.reasons,
          ...dnsRes.reasons,
          ...sslRes.reasons,
          ...urlRes.reasons,
        ]
      });

      await DatabaseHelper.instance.insertScan(ScanHistoryItem(
        scanType: 'NETWORK',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        statusLevel: overallStatus,
        summary: overallStatus == 'SAFE' ? 'Aman' : 'Terdapat Isu Keamanan',
        details: detailsJson,
      ));
    } catch (e) {
      debugPrint('Gagal menyimpan riwayat: $e');
    }

    if (!mounted) return;
    setState(() {
      _isChecking = false;
      _wifiStatus = wifiRes;
      _dnsStatus = dnsRes;
      _urlStatus = urlRes;
      _sslStatus = sslRes;
    });
  }

  String _getSignalText() {
    if (!_isWifiConnected) return 'Tidak Terhubung';
    switch (_signalLevel) {
      case 4: return 'Sangat Kuat';
      case 3: return 'Kuat';
      case 2: return 'Sedang';
      case 1: return 'Lemah';
      default: return 'Sangat Lemah';
    }
  }

  String _getFrequencyBand() {
    if (_frequency <= 0) return '-';
    return _frequency > 4900 ? '5 GHz' : '2.4 GHz';
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLoc.tr(context, 'Keamanan Jaringan'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(
                      icon: const Icon(LucideIcons.history),
                      color: textColor,
                      tooltip: 'Riwayat Pemindaian',
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                      },
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Pastikan koneksi Wi-Fi Anda aman dari sadapan.'), style: TextStyle(color: subTextColor)),
                
                // Location Permission Banner (jika SSID tidak tersedia karena masalah izin/lokasi mati)
                if (_isWifiConnected && !_ssidAvailable) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLoc.tr(context, 'Nama Jaringan Tidak Diketahui'),
                                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _ssidReason,
                                style: TextStyle(color: subTextColor, fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      await KasperskyChannel.requestLocationPermission();
                                      _loadWifiInfo();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(AppLoc.tr(context, 'Beri Izin'), style: const TextStyle(color: Colors.orange)),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () async {
                                      await KasperskyChannel.openLocationSettings();
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(AppLoc.tr(context, 'Buka GPS'), style: const TextStyle(color: Colors.orange)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
                const SizedBox(height: 32),

                // Hero Card — WiFi Info Real
                _buildGlassCard(
                  context,
                  child: Column(
                    children: [
                      Icon(
                        _isWifiConnected ? LucideIcons.wifi : LucideIcons.wifiOff,
                        size: 48, 
                        color: _isWifiConnected 
                          ? (isDark ? Colors.indigoAccent : Colors.indigo)
                          : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isWifiConnected ? _wifiSsid : AppLoc.tr(context, 'Tidak Terhubung ke WiFi'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_connectionType • ${_getSignalText()}',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                      if (_isWifiConnected) ...[
                        const SizedBox(height: 16),
                        // Detail WiFi
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('BSSID', _wifiBssid, textColor, subTextColor),
                              const Divider(height: 16),
                              _buildInfoRow(AppLoc.tr(context, 'Kecepatan'), '$_linkSpeed Mbps', textColor, subTextColor),
                              const Divider(height: 16),
                              _buildInfoRow(AppLoc.tr(context, 'Frekuensi'), '${_getFrequencyBand()} ($_frequency MHz)', textColor, subTextColor),
                              const Divider(height: 16),
                              _buildInfoRow(AppLoc.tr(context, 'Kekuatan Sinyal'), '${_getSignalText()} ($_signalLevel/4)', textColor, subTextColor),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
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
                
                _buildResultRow(context, LucideIcons.shieldCheck, 'Reputasi Wi-Fi', _wifiStatus),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.server, 'Integritas DNS', _dnsStatus),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.search, 'Pemeriksaan URL', _urlStatus),
                const SizedBox(height: 12),
                _buildResultRow(context, LucideIcons.lock, 'Validasi Sertifikat SSL', _sslStatus),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor, Color subTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 12)),
        Flexible(child: Text(value, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
      ],
    );
  }

  Widget _buildResultRow(BuildContext context, IconData icon, String title, NetCheck status) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    bool isNotChecked = status.isPending;
    bool isSafe = status.isSafe;
    
    Color statusColor = isNotChecked ? (isDark ? Colors.white54 : Colors.black54) : (isSafe ? Colors.green : Colors.red);
    
    return GestureDetector(
      onTap: status.reasons.isNotEmpty ? () => _showReasonsDialog(context, title, status) : null,
      child: _buildGlassCard(
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
                  Text(AppLoc.tr(context, status.summary), style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (!isNotChecked)
              Icon(isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertCircle, color: statusColor),
            if (status.reasons.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: statusColor.withOpacity(0.5)),
            ]
          ],
        )
      ),
    );
  }

  void _showReasonsDialog(BuildContext context, String title, NetCheck status) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Row(
          children: [
            Icon(status.isSafe ? LucideIcons.checkCircle2 : LucideIcons.alertTriangle, 
                 color: status.isSafe ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(AppLoc.tr(context, title), style: const TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status.summary, style: TextStyle(fontWeight: FontWeight.bold, color: status.isSafe ? Colors.green : Colors.red)),
            const SizedBox(height: 16),
            const Text('Alasan:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...status.reasons.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(r)),
                ],
              ),
            )).toList(),
            if (status.extra.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Info Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...status.extra.entries
                  .where((e) => e.key != 'reasons' && e.key != 'level' && e.key != 'summary')
                  .map((e) => Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12, color: Colors.grey)))
                  .toList(),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLoc.tr(context, 'Tutup')),
          ),
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
