import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/scan_history.dart';
import '../../../core/permissions.dart';
import '../../../ui/shared/glass_widgets.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  bool _isScanning = false;
  String _currentScanType = '';
  List<ScanRecord> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final history = await ScanHistoryService.getHistory();
    if (mounted) {
      setState(() => _recentScans = history.take(5).toList());
    }
  }

  void _runScan(String type) async {
    // Request storage permission first
    final hasPermission = await PermissionService.requestStoragePermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin penyimpanan diperlukan untuk memindai perangkat'),
          backgroundColor: AppColors.warning,
        ),
      );
    }

    String? selectedFolder;
    if (type == 'Folder') {
      selectedFolder = await FilePicker.getDirectoryPath(
        dialogTitle: AppLoc.tr(context, 'Pilih direktori spesifik untuk diperiksa'),
      );
      if (selectedFolder == null) return;
    }

    setState(() {
      _isScanning = true;
      _currentScanType = type;
    });
    
    // Call the actual native Kaspersky SDK
    final result = type == 'Folder' 
        ? await KasperskyChannel.scanFolder(selectedFolder!)
        : await KasperskyChannel.scanMalware();
    
    if (!mounted) return;
    setState(() => _isScanning = false);

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    
    if (result.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.error),
              const SizedBox(width: 8),
              Text(AppLoc.tr(context, 'Pemindaian Gagal'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            result['error'].toString(),
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text(AppLoc.tr(context, 'Tutup'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))
            )
          ],
        )
      );
      return;
    }
    
    int filesScanned = result['filesScanned'] ?? 0;
    int malwareCount = result['malwareCount'] ?? 0;
    List<String> malwareList = List<String>.from(result['malwareList'] ?? []);

    // Save to scan history
    final record = ScanRecord(
      type: type.toLowerCase(),
      timestamp: DateTime.now(),
      filesScanned: filesScanned,
      malwareCount: malwareCount,
      malwareList: malwareCount == 0 ? [] : malwareList,
      isRealSdk: result['isRealSdk'] == true,
      folderPath: selectedFolder,
    );
    await ScanHistoryService.addRecord(record);
    _loadRecentScans();
    
    bool hasThreats = malwareCount > 0;
    String contentText = hasThreats
      ? '${AppLoc.tr(context, 'Ancaman Ditemukan!')} $malwareCount malware.'
      : '$filesScanned ${AppLoc.tr(context, 'file diperiksa. Tidak ada ancaman.')}';
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(hasThreats ? LucideIcons.shieldAlert : LucideIcons.checkCircle, color: hasThreats ? AppColors.error : AppColors.success),
            const SizedBox(width: 8),
            Text(AppLoc.tr(context, 'Pindai Selesai'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          contentText,
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text(AppLoc.tr(context, 'Tutup'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))
          )
        ],
      )
    );
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
          Positioned(top: -50, right: -50, child: BackgroundBlob(color: AppColors.blobRed, size: 300)),
          Positioned(bottom: 50, left: -100, child: BackgroundBlob(color: AppColors.blobBlue, size: 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppLoc.tr(context, 'Pindai Perangkat'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Pilih metode pemindaian untuk menemukan ancaman.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),
                
                _buildScanOption(
                  icon: LucideIcons.zap,
                  title: 'Pindai Cepat',
                  subtitle: 'Memeriksa aplikasi sistem utama (1-2 Menit)',
                  color: AppColors.info,
                  onTap: () => _runScan('Quick'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _buildScanOption(
                  icon: LucideIcons.search,
                  title: 'Pindai Menyeluruh',
                  subtitle: 'Memeriksa seluruh memori internal perangkat (> 5 Menit)',
                  color: AppColors.scanColor,
                  onTap: () => _runScan('Full'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _buildScanOption(
                  icon: LucideIcons.folderSearch,
                  title: 'Pindai Folder',
                  subtitle: 'Pilih direktori spesifik untuk diperiksa',
                  color: Colors.purple,
                  onTap: () => _runScan('Folder'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                // Scan History Section
                if (_recentScans.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Pemindaian',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ScanHistoryService.clearHistory();
                          _loadRecentScans();
                        },
                        child: Text('Hapus', style: TextStyle(color: subTextColor, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_recentScans.length, (i) {
                    final scan = _recentScans[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (scan.isSafe ? AppColors.success : AppColors.error).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                scan.isSafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle,
                                color: scan.isSafe ? AppColors.success : AppColors.error,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(scan.typeDisplay, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                                  Text(
                                    '${scan.filesScanned} file • ${_formatDate(scan.timestamp)}',
                                    style: TextStyle(color: subTextColor, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              scan.isSafe ? 'Aman' : '${scan.malwareCount} ancaman',
                              style: TextStyle(
                                color: scan.isSafe ? AppColors.success : AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],

                // Bottom padding for nav bar
                const SizedBox(height: 100),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildScanOption({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color, 
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    bool isThisScanning = _isScanning && _currentScanType == title;

    return GlassCard(
      child: InkWell(
        onTap: _isScanning ? null : onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: isThisScanning
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: color))
                  : Icon(icon, color: isDark ? color.withOpacity(0.8) : color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                  const SizedBox(height: 4),
                  Text(AppLoc.tr(context, subtitle), style: TextStyle(color: subTextColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: subTextColor.withOpacity(0.5))
          ],
        ),
      ),
    );
  }
}
