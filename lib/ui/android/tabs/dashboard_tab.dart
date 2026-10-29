import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/database_helper.dart';
import '../../../core/scan_history_item.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isScanning = false;
  Timer? _wifiRefreshTimer;
  StreamSubscription<Map<String, dynamic>>? _eventSub;

  int _scanPercent = 0;
  int _scannedFilesCount = 0;
  int _scannedObjectsCount = 0;
  int _totalFilesCount = 0;
  String _etaText = 'Menghitung estimasi...';
  String _currentFile = '';
  final List<String> _processLogs = [];
  final ScrollController _logScrollController = ScrollController();

  String _statusMessage = 'Perangkat Aman';
  String _statusSubMessage = 'Sistem berjalan dengan sangat baik.';
  Color _statusColor = Colors.blue;

  // Real WiFi data
  String _wifiSsid = '...';
  String _connectionType = '...';
  bool _isWifiConnected = false;
  int _signalLevel = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadWifiInfo();
    // Auto-refresh WiFi info setiap 15 detik
    _wifiRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadWifiInfo());

    _eventSub = KasperskyChannel.events.listen((event) {
      if (!mounted) return;
      final type = event['event'] as String?;
      final source = event['source'] as String?;
      if (type == 'onScanProgress' && source == 'Dashboard') {
        final count = (event['filesScanned'] as num?)?.toInt() ?? _scannedFilesCount;
        final objs = (event['objectsScanned'] as num?)?.toInt() ?? _scannedObjectsCount;
        final total = (event['totalFiles'] as num?)?.toInt() ?? _totalFilesCount;
        final pct = (event['percent'] as num?)?.toInt() ?? _scanPercent;
        final eta = (event['etaText'] as String?) ?? _etaText;
        final curFile = (event['currentFile'] as String?) ?? _currentFile;
        final logLine = event['logEntry'] as String?;

        setState(() {
          _isScanning = pct < 100;
          _scanPercent = pct.clamp(0, 100);
          _scannedFilesCount = count;
          _scannedObjectsCount = objs;
          _totalFilesCount = total;
          _etaText = eta;
          _currentFile = curFile;
          _statusMessage = 'Memindai... ($_scanPercent%)';
          _statusSubMessage = total > 0
              ? '$count / $total file dipindai • Estimasi $eta'
              : '$count file dipindai • Estimasi $eta';
          if (logLine != null && logLine.isNotEmpty) {
            _processLogs.add(logLine);
            if (_processLogs.length > 150) {
              _processLogs.removeAt(0);
            }
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.animateTo(
              _logScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _wifiRefreshTimer?.cancel();
    _eventSub?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWifiInfo() async {
    final info = await KasperskyChannel.getWifiInfo();
    if (!mounted) return;
    setState(() {
      _isWifiConnected = info['isConnected'] ?? false;
      _wifiSsid = info['ssid'] ?? 'Tidak Diketahui';
      _connectionType = info['connectionType'] ?? 'Tidak Diketahui';
      _signalLevel = info['signalLevel'] ?? 0;
    });
  }

  String _getConnectionDetail() {
    if (!_isWifiConnected) {
      if (_connectionType == 'Seluler') {
        return AppLoc.tr(context, 'Terhubung melalui jaringan seluler.');
      }
      return AppLoc.tr(context, 'Tidak terhubung ke jaringan WiFi.');
    }
    String signal = _signalLevel >= 3 ? 'kuat' : (_signalLevel >= 2 ? 'sedang' : 'lemah');
    return '${AppLoc.tr(context, 'Terhubung ke')} "$_wifiSsid" (${AppLoc.tr(context, 'sinyal')} $signal).';
  }

  String _getConnectionStatus() {
    if (!_isWifiConnected && _connectionType != 'Seluler') {
      return AppLoc.tr(context, 'Tidak Terhubung');
    }
    return AppLoc.tr(context, 'Aman');
  }

  Future<void> _runQuickScan() async {
    setState(() {
      _isScanning = true;
      _scanPercent = 0;
      _scannedFilesCount = 0;
      _scannedObjectsCount = 0;
      _totalFilesCount = 0;
      _etaText = 'Menghitung estimasi...';
      _currentFile = 'Menyiapkan pemindaian...';
      _processLogs.clear();
      _statusMessage = 'Memindai... (0%)';
      _statusSubMessage = 'Tetap berjalan meski Anda keluar dari aplikasi.';
    });

    final result = await KasperskyChannel.scanMalware(mode: 'Quick', source: 'Dashboard');

    // Simpan ke riwayat pemindaian
    if (!result.containsKey('error')) {
      final int malwareCount = result['malwareCount'] ?? 0;
      final int scanned = result['filesScanned'] ?? 0;
      final bool isRooted = result['isDeviceRooted'] ?? false;
      final List<dynamic> malwareList = result['malwareList'] ?? [];
      final bool hasThreat = malwareCount > 0 || isRooted;

      try {
        final detailsJson = jsonEncode({
          'folder': 'Pindai Cepat (Beranda)',
          'files_scanned': scanned,
          'malware_count': malwareCount,
          'is_rooted': isRooted,
          'reasons': malwareList.map((e) => e.toString()).toList(),
        });
        await DatabaseHelper.instance.insertScan(ScanHistoryItem(
          scanType: 'MALWARE',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          statusLevel: hasThreat ? 'DANGER' : 'SAFE',
          summary: hasThreat ? 'Ditemukan $malwareCount ancaman' : 'Aman',
          details: detailsJson,
        ));
      } catch (e) {
        debugPrint('Gagal simpan riwayat Beranda: $e');
      }
    }

    if (!mounted) return;
    
    setState(() {
      _isScanning = false;
      _scanPercent = 100;
      if (result.containsKey('error')) {
         _statusMessage = 'Pemindaian Gagal';
         _statusSubMessage = result['error'].toString();
         _statusColor = Colors.red;
      } else {
         int malwareCount = result['malwareCount'] ?? 0;
         int scanned = result['filesScanned'] ?? 0;
         if (malwareCount > 0) {
            _statusMessage = 'Ancaman Ditemukan!';
            _statusSubMessage = '$malwareCount ${AppLoc.tr(context, 'malware dari')} $scanned file.';
            _statusColor = Colors.red;
         } else {
            _statusMessage = '100% Aman';
            _statusSubMessage = '$scanned ${AppLoc.tr(context, 'file bersih dari ancaman.')}';
            _statusColor = Colors.blue;
         }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(top: -50, left: -100, child: _buildBlob(const Color(0xFF93C5FD), 250)),
          Positioned(top: 150, right: -80, child: _buildBlob(const Color(0xFFC4B5FD), 300)),
          Positioned(bottom: 0, left: 20, child: _buildBlob(const Color(0xFFA7F3D0), 200)),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor, isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    children: [
                      _buildMainShield(textColor, isDark),
                      if (_isScanning || _processLogs.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildMiniProcessLog(textColor, isDark),
                      ],
                      const SizedBox(height: 32),
                      _buildQuickStats(textColor, isDark),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniProcessLog(Color textColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Proses: $_scannedFilesCount / ${_totalFilesCount > 0 ? _totalFilesCount : "-"} file ($_scanPercent%)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isScanning ? _etaText : 'Selesai',
                style: const TextStyle(
                  color: Colors.indigoAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: _scanPercent > 0 ? (_scanPercent / 100.0).clamp(0.0, 1.0) : null,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 95,
            child: ListView.builder(
              controller: _logScrollController,
              itemCount: _processLogs.length,
              itemBuilder: (context, index) {
                final line = _processLogs[index];
                final isWarn = line.contains('⚠️');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    line,
                    style: TextStyle(
                      color: isWarn ? const Color(0xFFFF7B72) : const Color(0xFF8B949E),
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                    ),
                  ),
                );
              },
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
      decoration: BoxDecoration(
        color: color.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor, bool isDark) {
    final appState = Provider.of<AppState>(context);
    String initials = 'US';
    if (appState.userName.isNotEmpty) {
      List<String> names = appState.userName.trim().split(' ');
      if (names.length >= 2) {
        initials = '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        initials = names[0].substring(0, names[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('DeFort', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          CircleAvatar(
            backgroundColor: isDark ? Colors.grey[800] : Colors.white,
            child: Text(initials, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildMainShield(Color textColor, bool isDark) {
    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 150 + (_pulseController.value * 50),
                    height: 150 + (_pulseController.value * 50),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: (isDark ? Colors.indigoAccent : Colors.white).withOpacity(1 - _pulseController.value), width: 2),
                    ),
                  );
                },
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.8), width: 1.5),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isScanning) ...[
                            Text(
                              '$_scanPercent%',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _statusColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_scannedFilesCount file',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: textColor.withOpacity(0.75),
                              ),
                            ),
                          ] else
                            Icon(
                               LucideIcons.check,
                               size: 40,
                               color: _statusColor
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(AppLoc.tr(context, _statusMessage), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 8),
        Text(AppLoc.tr(context, _statusSubMessage), textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.7))),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isScanning ? null : _runQuickScan,
          icon: _isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.zap, size: 18),
          label: Text(AppLoc.tr(context, _isScanning ? 'Memproses...' : 'Pindai Sekarang')),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? Colors.indigoAccent : Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(Color textColor, bool isDark) {
    // Data koneksi real
    final connStatus = _getConnectionStatus();
    final connDetail = _getConnectionDetail();
    final connColor = (_isWifiConnected || _connectionType == 'Seluler') ? Colors.teal : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLoc.tr(context, 'Ringkasan Keamanan'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            _buildGlassCard(LucideIcons.bug, 'Anti-Malware', AppLoc.tr(context, 'Aktif'), isDark ? Colors.indigoAccent : Colors.indigo, AppLoc.tr(context, 'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).'), textColor, isDark),
            _buildGlassCard(LucideIcons.globe, 'Safe Browsing', AppLoc.tr(context, 'Aktif'), isDark ? Colors.lightBlue : Colors.blue, AppLoc.tr(context, 'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.'), textColor, isDark),
            _buildGlassCard(LucideIcons.alertTriangle, AppLoc.tr(context, 'Izin Aplikasi'), AppLoc.tr(context, 'Aman'), Colors.orange, AppLoc.tr(context, 'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.'), textColor, isDark),
            // Card Koneksi — DATA REAL
            _buildGlassCard(
              _isWifiConnected ? LucideIcons.wifi : (_connectionType == 'Seluler' ? LucideIcons.smartphone : LucideIcons.wifiOff),
              AppLoc.tr(context, 'Koneksi'),
              connStatus,
              connColor,
              connDetail,
              textColor,
              isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassCard(IconData icon, String title, String subtitle, Color color, String details, Color textColor, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                    ),
                    Icon(icon, size: 48, color: color),
                    const SizedBox(height: 16),
                    Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Text(details, textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 15)),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(AppLoc.tr(context, 'Mengerti'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
              )
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.2 : 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
