import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../../main.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/scan_history.dart';
import '../../../ui/shared/glass_widgets.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isScanning = false;
  
  String _statusMessage = 'Perangkat Aman';
  String _statusSubMessage = 'Sistem berjalan dengan sangat baik.';
  Color _statusColor = Colors.blue;
  
  List<ScanRecord> _scanHistory = [];
  
  // Device Report data
  String _networkName = 'Memeriksa...';
  bool _isLicenseValid = false;
  String _licenseExpiry = '-';
  int _totalScans = 0;
  int _totalThreats = 0;
  int _totalFilesScanned = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadScanHistory(),
      _loadDeviceReport(),
    ]);
  }

  Future<void> _loadScanHistory() async {
    final history = await ScanHistoryService.getHistory();
    if (mounted) {
      setState(() {
        _scanHistory = history;
        _totalScans = history.length;
        _totalThreats = history.fold(0, (sum, r) => sum + r.malwareCount);
        _totalFilesScanned = history.fold(0, (sum, r) => sum + r.filesScanned);
      });
    }
  }

  Future<void> _loadDeviceReport() async {
    // Network
    final netName = await KasperskyChannel.getNetworkName();
    
    // License
    Map<String, dynamic> licenseInfo = {};
    try {
      licenseInfo = await KasperskyChannel.getLicenseInfo();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _networkName = netName;
        _isLicenseValid = licenseInfo['isValid'] == true;
        _licenseExpiry = licenseInfo['expirationDate']?.toString() ?? '-';
      });
    }
  }

  Future<void> _runQuickScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Memindai...';
      _statusSubMessage = 'Harap tunggu, SDK sedang bekerja.';
    });

    final result = await KasperskyChannel.scanMalware();
    
    if (!mounted) return;
    
    setState(() {
      _isScanning = false;
      if (result.containsKey('error')) {
         _statusMessage = 'Pemindaian Gagal';
         _statusSubMessage = result['error'].toString();
         _statusColor = AppColors.error;
      } else {
         int malwareCount = result['malwareCount'] ?? 0;
         int scanned = result['filesScanned'] ?? 0;
         List<String> malwareList = List<String>.from(result['malwareList'] ?? []);

         // Save to history
         ScanHistoryService.addRecord(ScanRecord(
           type: 'quick',
           timestamp: DateTime.now(),
           filesScanned: scanned,
           malwareCount: malwareCount,
           malwareList: malwareCount == 0 ? [] : malwareList,
           isRealSdk: result['isRealSdk'] == true,
         ));
         _loadScanHistory();

         if (malwareCount > 0) {
            _statusMessage = 'Ancaman Ditemukan!';
            _statusSubMessage = '$malwareCount malware dari $scanned file.';
            _statusColor = AppColors.error;
         } else {
            _statusMessage = '100% Aman';
            _statusSubMessage = '$scanned file bersih dari ancaman.';
            _statusColor = AppColors.info;
         }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          Positioned(top: -50, left: -100, child: BackgroundBlob(color: AppColors.blobBlue, size: 250)),
          Positioned(top: 150, right: -80, child: BackgroundBlob(color: AppColors.blobPurple, size: 300)),
          Positioned(bottom: 0, left: 20, child: BackgroundBlob(color: AppColors.blobGreen, size: 200)),
          
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, textColor, isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primaryAdaptive(isDark),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      children: [
                        _buildMainShield(textColor, isDark),
                        const SizedBox(height: 32),
                        _buildQuickStats(textColor, isDark),
                        const SizedBox(height: 28),
                        _buildDeviceReport(textColor, isDark),
                        const SizedBox(height: 28),
                        _buildScanHistoryLog(textColor, isDark),
                        const SizedBox(height: 100), // Bottom nav padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================
  // DEVICE REPORT SECTION
  // ====================================
  Widget _buildDeviceReport(Color textColor, bool isDark) {
    final appState = Provider.of<AppState>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.clipboard, color: AppColors.primaryAdaptive(isDark), size: 20),
            const SizedBox(width: 8),
            Text('Laporan Perangkat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Stats Row
        Row(
          children: [
            Expanded(child: _buildMiniStat(LucideIcons.scan, '$_totalScans', 'Total Scan', AppColors.scanColor, isDark, textColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat(LucideIcons.fileCheck, '$_totalFilesScanned', 'File Diperiksa', AppColors.info, isDark, textColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStat(LucideIcons.bug, '$_totalThreats', 'Ancaman', _totalThreats > 0 ? AppColors.error : AppColors.success, isDark, textColor)),
          ],
        ),
        const SizedBox(height: 16),

        // Detail Cards
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildReportRow(
                icon: LucideIcons.shieldCheck,
                label: 'Kaspersky SDK',
                value: _isLicenseValid ? 'Aktif & Terverifikasi' : 'Tidak Aktif',
                valueColor: _isLicenseValid ? AppColors.success : AppColors.error,
                textColor: textColor,
                isDark: isDark,
              ),
              Divider(color: textColor.withOpacity(0.08), height: 20),
              _buildReportRow(
                icon: LucideIcons.calendar,
                label: 'Lisensi Berakhir',
                value: _licenseExpiry,
                valueColor: textColor.withOpacity(0.8),
                textColor: textColor,
                isDark: isDark,
              ),
              Divider(color: textColor.withOpacity(0.08), height: 20),
              _buildReportRow(
                icon: LucideIcons.wifi,
                label: 'Jaringan',
                value: _networkName,
                valueColor: textColor.withOpacity(0.8),
                textColor: textColor,
                isDark: isDark,
              ),
              Divider(color: textColor.withOpacity(0.08), height: 20),
              _buildReportRow(
                icon: LucideIcons.bug,
                label: 'Anti-Malware',
                value: appState.realTimeProtection ? 'Real-Time Aktif' : 'Nonaktif',
                valueColor: appState.realTimeProtection ? AppColors.success : AppColors.warning,
                textColor: textColor,
                isDark: isDark,
              ),
              Divider(color: textColor.withOpacity(0.08), height: 20),
              _buildReportRow(
                icon: LucideIcons.globe,
                label: 'Anti-Phishing',
                value: appState.isAntiPhishingActive ? 'Aktif' : 'Nonaktif',
                valueColor: appState.isAntiPhishingActive ? AppColors.success : AppColors.warning,
                textColor: textColor,
                isDark: isDark,
              ),
              Divider(color: textColor.withOpacity(0.08), height: 20),
              _buildReportRow(
                icon: LucideIcons.clock,
                label: 'Scan Terakhir',
                value: _scanHistory.isNotEmpty ? _formatTimeAgo(_scanHistory.first.timestamp) : 'Belum pernah',
                valueColor: textColor.withOpacity(0.8),
                textColor: textColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label, Color color, bool isDark, Color textColor) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6), fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildReportRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAdaptive(isDark), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor, fontSize: 13),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ====================================
  // SCAN HISTORY LOG SECTION
  // ====================================
  Widget _buildScanHistoryLog(Color textColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(LucideIcons.history, color: AppColors.primaryAdaptive(isDark), size: 20),
                const SizedBox(width: 8),
                Text('Riwayat Pemindaian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            if (_scanHistory.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showClearHistoryDialog(isDark, textColor),
                icon: Icon(LucideIcons.trash2, size: 14, color: textColor.withOpacity(0.5)),
                label: Text('Hapus', style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_scanHistory.isEmpty)
          GlassCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(LucideIcons.searchX, size: 40, color: textColor.withOpacity(0.25)),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat pemindaian',
                    style: TextStyle(color: textColor.withOpacity(0.5), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tekan "Pindai Sekarang" untuk memulai.',
                    style: TextStyle(color: textColor.withOpacity(0.35), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(
            _scanHistory.length > 10 ? 10 : _scanHistory.length,
            (i) => _buildHistoryItem(_scanHistory[i], textColor, isDark, i),
          ),

        if (_scanHistory.length > 10) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => _showAllHistorySheet(isDark, textColor),
              child: Text(
                'Lihat ${_scanHistory.length - 10} lainnya →',
                style: TextStyle(color: AppColors.primaryAdaptive(isDark), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHistoryItem(ScanRecord scan, Color textColor, bool isDark, int index) {
    final bool hasThreat = scan.malwareCount > 0;
    final Color statusColor = hasThreat ? AppColors.error : AppColors.success;
    final IconData statusIcon = hasThreat ? LucideIcons.shieldAlert : LucideIcons.shieldCheck;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showScanDetailSheet(scan, isDark, textColor),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          scan.typeDisplay,
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                        ),
                        if (scan.isRealSdk) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAdaptive(isDark).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('SDK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryAdaptive(isDark))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      scan.isFileScan 
                        ? '${scan.filesScanned} file • ${_formatDateTime(scan.timestamp)}'
                        : _formatDateTime(scan.timestamp),
                      style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 11),
                    ),
                    if (scan.target.isNotEmpty)
                      Text(
                        scan.target.length > 35 ? '...${scan.target.substring(scan.target.length - 35)}' : scan.target,
                        style: TextStyle(color: textColor.withOpacity(0.35), fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Result
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasThreat ? '${scan.malwareCount} ancaman' : 'Aman ✓',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(scan.timestamp),
                    style: TextStyle(color: textColor.withOpacity(0.35), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================
  // DETAIL SHEET (Tap on history item)
  // ====================================
  void _showScanDetailSheet(ScanRecord scan, bool isDark, Color textColor) {
    final statusColor = scan.isSafe ? AppColors.success : AppColors.error;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                scan.isSafe ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                size: 40,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              scan.isSafe ? 'Tidak Ada Ancaman' : '${scan.malwareCount} Ancaman Ditemukan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            Text(
              '${scan.typeDisplay} • ${_formatDateTime(scan.timestamp)}',
              style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13),
            ),
            const SizedBox(height: 24),
            
            // Detail rows
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Tipe Scan', scan.typeDisplay, textColor),
                  Divider(color: textColor.withOpacity(0.08), height: 16),
                  _buildDetailRow('Waktu', _formatDateTime(scan.timestamp), textColor),
                  Divider(color: textColor.withOpacity(0.08), height: 16),
                  
                  if (scan.isFileScan) ...[
                    _buildDetailRow('File Diperiksa', '${scan.filesScanned} file', textColor),
                    Divider(color: textColor.withOpacity(0.08), height: 16),
                  ],
                  
                  _buildDetailRow(scan.isSafe ? 'Status' : 'Ancaman', scan.isSafe ? 'Aman' : '${scan.malwareCount}', textColor, valueColor: scan.isSafe ? AppColors.success : AppColors.error),
                  
                  if (scan.target.isNotEmpty) ...[
                    Divider(color: textColor.withOpacity(0.08), height: 16),
                    _buildDetailRow(scan.isFileScan ? 'Folder' : 'Target', scan.target, textColor),
                  ],
                  Divider(color: textColor.withOpacity(0.08), height: 16),
                  _buildDetailRow('Mesin', scan.isRealSdk ? 'Kaspersky SDK' : 'Simulasi', textColor),
                ],
              ),
            ),
            
            // Malware list if any
            if (scan.malwareList.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Ancaman Terdeteksi:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 14)),
              ),
              const SizedBox(height: 8),
              ...scan.malwareList.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m, style: TextStyle(color: textColor, fontSize: 13))),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor ?? textColor, fontSize: 13),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ====================================
  // SHOW ALL HISTORY SHEET
  // ====================================
  void _showAllHistorySheet(bool isDark, Color textColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SheetHandle(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(LucideIcons.history, color: AppColors.primaryAdaptive(isDark)),
                const SizedBox(width: 8),
                Text('Semua Riwayat Pemindaian', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
              ],
            ),
            Text('${_scanHistory.length} pemindaian tercatat', style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _scanHistory.length,
                itemBuilder: (context, i) => _buildHistoryItem(_scanHistory[i], textColor, isDark, i),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================================
  // CLEAR HISTORY DIALOG
  // ====================================
  void _showClearHistoryDialog(bool isDark, Color textColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Riwayat?', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: Text('Semua riwayat pemindaian akan dihapus secara permanen.', style: TextStyle(color: textColor.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: textColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ScanHistoryService.clearHistory();
              _loadScanHistory();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  // ====================================
  // HELPERS
  // ====================================
  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m';
  }

  // ====================================
  // EXISTING WIDGETS (Header, Shield, Stats)
  // ====================================
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
                      border: Border.all(
                        color: (isDark ? Colors.indigoAccent : Colors.white).withOpacity(1 - _pulseController.value),
                        width: 2,
                      ),
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
                      color: AppColors.glass(isDark),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder(isDark), width: 1.5),
                    ),
                    child: Center(
                      child: Icon(
                        _isScanning ? LucideIcons.loader : LucideIcons.check, 
                        size: 40, 
                        color: _statusColor,
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
          icon: _isScanning
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(LucideIcons.zap, size: 18),
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
            _buildStatCard(LucideIcons.bug, 'Anti-Malware', 'Aktif', isDark ? Colors.indigoAccent : Colors.indigo, 'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).', textColor, isDark),
            _buildStatCard(LucideIcons.globe, 'Safe Browsing', 'Aktif', isDark ? Colors.lightBlue : Colors.blue, 'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.', textColor, isDark),
            _buildStatCard(LucideIcons.alertTriangle, 'Izin Aplikasi', 'Aman', Colors.orange, 'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.', textColor, isDark),
            _buildStatCard(LucideIcons.wifi, 'Koneksi', 'Aman', Colors.teal, 'Terhubung ke jaringan terenkripsi yang aman (WPA3).', textColor, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String title, String subtitle, Color color, String details, Color textColor, bool isDark) {
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
                    const SheetHandle(),
                    Icon(icon, size: 48, color: color),
                    const SizedBox(height: 16),
                    Text(AppLoc.tr(context, title), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 8),
                    Text(AppLoc.tr(context, details), textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 15)),
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
              color: AppColors.glass(isDark),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.glassBorder(isDark)),
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
                Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                const SizedBox(height: 4),
                Text(AppLoc.tr(context, subtitle), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
