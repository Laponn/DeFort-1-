import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/database_helper.dart';
import '../../../core/scan_history_item.dart';
import '../screens/history_screen.dart';

class _ScanLogEntry {
  final String message;
  final bool isThreat;
  const _ScanLogEntry(this.message, {this.isThreat = false});
}

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  bool _isScanning = false;
  String _scanningLabel = '';
  int _scanPercent = 0;
  int _scannedFilesCount = 0;
  int _scannedObjectsCount = 0;
  int _totalFilesCount = 0;
  int _threatsFoundCount = 0;
  String _etaText = 'Menghitung estimasi...';
  int _elapsedSeconds = 0;
  String _currentFile = '';
  final List<_ScanLogEntry> _processLogs = [];
  final ScrollController _logScrollController = ScrollController();

  StreamSubscription<Map<String, dynamic>>? _eventSub;

  @override
  void initState() {
    super.initState();
    _syncActiveScan();
    _eventSub = KasperskyChannel.events.listen((event) {
      if (!mounted) return;
      final type = event['event'] as String?;
      final source = event['source'] as String?;
      if (type == 'onScanProgress' && source == 'ScanTab') {
        final String? logLine = event['logEntry'] as String?;
        final bool isThreat = (event['isThreatLog'] as bool?) ?? false;
        setState(() {
          _isScanning = (event['percent'] as int? ?? _scanPercent) < 100;
          if (event['percent'] != null) {
            _scanPercent = (event['percent'] as num).toInt().clamp(0, 100);
          }
          if (event['filesScanned'] != null) {
            _scannedFilesCount = (event['filesScanned'] as num).toInt();
          }
          if (event['objectsScanned'] != null) {
            _scannedObjectsCount = (event['objectsScanned'] as num).toInt();
          }
          if (event['totalFiles'] != null) {
            _totalFilesCount = (event['totalFiles'] as num).toInt();
          }
          if (event['threatsFound'] != null) {
            _threatsFoundCount = (event['threatsFound'] as num).toInt();
          }
          if (event['etaText'] != null) {
            _etaText = event['etaText'].toString();
          }
          if (event['elapsedSeconds'] != null) {
            _elapsedSeconds = (event['elapsedSeconds'] as num).toInt();
          }
          if (event['currentFile'] != null) {
            _currentFile = event['currentFile'].toString();
          }
          if (logLine != null && logLine.isNotEmpty) {
            _processLogs.add(_ScanLogEntry(logLine, isThreat: isThreat));
            if (_processLogs.length > 250) {
              _processLogs.removeAt(0);
            }
          }
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
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

  Future<void> _syncActiveScan() async {
    final active = await KasperskyChannel.getActiveScanState();
    if (!mounted) return;
    if (active['isScanning'] == true && active['source'] == 'ScanTab') {
      setState(() {
        _isScanning = true;
        _scanningLabel = (active['label'] as String?) ?? 'Memindai...';
        _scanPercent = (active['percent'] as num?)?.toInt() ?? 0;
        _scannedFilesCount = (active['filesScanned'] as num?)?.toInt() ?? 0;
        _scannedObjectsCount = (active['objectsScanned'] as num?)?.toInt() ?? 0;
        _totalFilesCount = (active['totalFiles'] as num?)?.toInt() ?? 0;
        _etaText = (active['etaText'] as String?) ?? 'Menghitung estimasi...';
        _currentFile = (active['currentFile'] as String?) ?? '';
      });
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  Future<bool> _ensureStoragePermissionForFolderOrFullScan() async {
    final hasPerm = await KasperskyChannel.checkStoragePermission();
    if (hasPerm) return true;
    if (!mounted) return false;

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.folderLock, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Izin Akses Penyimpanan',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Agar Kaspersky SDK dapat membaca dan memindai seluruh file di dalam folder memori internal (termasuk file dokumen/uji virus), berikan izin "Akses Semua File" untuk DeFort.',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Lewati', style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Beri Izin'),
          ),
        ],
      ),
    );

    if (shouldOpen == true) {
      await KasperskyChannel.requestStoragePermission();
    }
    return true;
  }

  void _runScan(String type) async {
    if (type == 'Folder' || type == 'Full') {
      await _ensureStoragePermissionForFolderOrFullScan();
    }

    String? folderPath;

    if (type == 'Folder') {
      if (!mounted) return;
      // Buka file picker biar user pilih folder sendiri
      String? selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: AppLoc.tr(context, 'Pilih folder yang ingin dipindai'),
      );

      if (selectedDir == null) return; // User cancel
      folderPath = selectedDir;
    }

    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _scanPercent = 0;
      _scannedFilesCount = 0;
      _scannedObjectsCount = 0;
      _totalFilesCount = 0;
      _threatsFoundCount = 0;
      _etaText = 'Menghitung estimasi waktu...';
      _elapsedSeconds = 0;
      _currentFile = 'Menyiapkan pemindaian...';
      _processLogs.clear();
      _scanningLabel = type == 'Folder'
          ? '${AppLoc.tr(context, 'Memindai')} $folderPath'
          : type == 'Quick'
              ? AppLoc.tr(context, 'Pindai Cepat')
              : AppLoc.tr(context, 'Pindai Menyeluruh');
    });

    // Panggil SDK sesuai tipe scan (berjalan di Foreground Service)
    Map<String, dynamic> result;
    if (type == 'Folder' && folderPath != null) {
      result = await KasperskyChannel.scanFolder(folderPath);
    } else {
      result = await KasperskyChannel.scanMalware(mode: type, source: 'ScanTab');
    }

    // Ambil data real dari SDK dan simpan ke database terlebih dahulu
    if (!result.containsKey('error')) {
      final int malwareCount = result['malwareCount'] ?? 0;
      final int filesScanned = result['filesScanned'] ?? 0;
      final bool isRooted = result['isDeviceRooted'] ?? false;
      final List<dynamic> malwareList = result['malwareList'] ?? [];
      final String? scannedFolder = result['folderPath'];
      final bool hasThreat = malwareCount > 0 || isRooted;

      try {
        final detailsJson = jsonEncode({
          'folder': scannedFolder ?? 'Seluruh Perangkat',
          'files_scanned': filesScanned,
          'malware_count': malwareCount,
          'is_rooted': isRooted,
          'reasons': malwareList.isNotEmpty ? malwareList.map((e) => e.toString()).toList() : [],
        });

        await DatabaseHelper.instance.insertScan(ScanHistoryItem(
          scanType: 'MALWARE',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          statusLevel: hasThreat ? 'DANGER' : 'SAFE',
          summary: hasThreat ? 'Ditemukan $malwareCount ancaman' : 'Aman',
          details: detailsJson,
        ));
      } catch (e) {
        debugPrint('Gagal simpan riwayat: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isScanning = false;
      if (!result.containsKey('error')) {
        _scanPercent = 100;
        _etaText = 'Selesai (0 detik)';
      }
    });

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    // Cek apakah SDK mengembalikan error
    if (result.containsKey('error')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(child: Text(AppLoc.tr(context, 'Pemindaian Gagal'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
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

    final int malwareCount = result['malwareCount'] ?? 0;
    final int filesScanned = result['filesScanned'] ?? 0;
    final int objectsScanned = result['objectsScanned'] ?? filesScanned;
    final int elapsedSec = result['elapsedSeconds'] ?? _elapsedSeconds;
    final bool isRooted = result['isDeviceRooted'] ?? false;
    final List<dynamic> malwareList = result['malwareList'] ?? [];
    final String? scannedFolder = result['folderPath'];

    final bool hasThreat = malwareCount > 0 || isRooted;
    final IconData resultIcon = hasThreat ? LucideIcons.alertTriangle : LucideIcons.checkCircle;
    final Color resultColor = hasThreat ? Colors.red : Colors.green;

    String titleText = hasThreat
        ? AppLoc.tr(context, 'Ancaman Ditemukan!')
        : AppLoc.tr(context, 'Pindai Selesai');

    // Bangun detail hasil scan
    StringBuffer details = StringBuffer();
    if (scannedFolder != null) {
      details.writeln('📁 $scannedFolder');
      details.writeln('');
    }
    details.writeln('📄 $filesScanned ${AppLoc.tr(context, 'file diperiksa')} ($objectsScanned objek)');
    details.writeln('⏱️ Durasi pemindaian: $elapsedSec detik (100%)');
    details.writeln('🛡️ $malwareCount ${AppLoc.tr(context, 'ancaman terdeteksi')}');
    if (isRooted) {
      details.writeln('⚠️ ${AppLoc.tr(context, 'Perangkat terdeteksi ROOT')}');
    }
    if (malwareList.isNotEmpty) {
      details.writeln('');
      details.writeln(AppLoc.tr(context, 'Daftar ancaman:'));
      for (var threat in malwareList) {
        details.writeln('• $threat');
      }
    }
    if (!hasThreat) {
      details.writeln('');
      details.writeln('✅ ${AppLoc.tr(context, 'Perangkat Anda bersih!')}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(resultIcon, color: resultColor),
            const SizedBox(width: 8),
            Expanded(child: Text(titleText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          details.toString().trim(),
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
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildBlob(const Color(0xFFFCA5A5), 300)),
          Positioned(bottom: 50, left: -100, child: _buildBlob(const Color(0xFF93C5FD), 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLoc.tr(context, 'Pindai Perangkat'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
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
                Text(AppLoc.tr(context, 'Pilih metode pemindaian untuk menemukan ancaman.'), style: TextStyle(color: subTextColor)),

                if (_isScanning || _processLogs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildProgressAndLogCard(context, isDark, textColor, subTextColor),
                ],

                const SizedBox(height: 28),
                
                _buildScanOption(
                  context: context,
                  icon: LucideIcons.zap,
                  title: 'Pindai Cepat',
                  subtitle: 'Memeriksa aplikasi sistem utama (1-2 Menit)',
                  color: Colors.blue,
                  onTap: () => _runScan('Quick'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _buildScanOption(
                  context: context,
                  icon: LucideIcons.search,
                  title: 'Pindai Menyeluruh',
                  subtitle: 'Memeriksa seluruh memori internal perangkat (> 5 Menit)',
                  color: Colors.indigo,
                  onTap: () => _runScan('Full'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 16),
                _buildScanOption(
                  context: context,
                  icon: LucideIcons.folderSearch,
                  title: 'Pindai Folder',
                  subtitle: 'Pilih folder dari perangkat Anda untuk dipindai',
                  color: Colors.purple,
                  onTap: () => _runScan('Folder'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 90),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProgressAndLogCard(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final accentColor = _threatsFoundCount > 0
        ? Colors.redAccent
        : (_scanPercent >= 100 ? Colors.green : Colors.indigoAccent);

    return _buildGlassCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Judul Scan + Persentase Besar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (_isScanning)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accentColor,
                          value: _scanPercent > 0 ? (_scanPercent / 100.0) : null,
                        ),
                      )
                    else
                      Icon(
                        _threatsFoundCount > 0 ? LucideIcons.alertTriangle : LucideIcons.checkCircle2,
                        color: accentColor,
                        size: 22,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _scanningLabel,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$_scanPercent%',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar Visual
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _scanPercent > 0 ? (_scanPercent / 100.0).clamp(0.0, 1.0) : null,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 14),

          // Info Bar: Jumlah File Dipindai & Estimasi Waktu Selesai (ETA)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.fileCheck, size: 15, color: subTextColor),
                        const SizedBox(width: 6),
                        Text(
                          'File Dipindai:',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      _totalFilesCount > 0
                          ? '$_scannedFilesCount / $_totalFilesCount file ($_scannedObjectsCount objek)'
                          : '$_scannedFilesCount file ($_scannedObjectsCount objek)',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 15, color: subTextColor),
                        const SizedBox(width: 6),
                        Text(
                          'Estimasi Selesai:',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      _etaText,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.shieldAlert, size: 15, color: subTextColor),
                        const SizedBox(width: 6),
                        Text(
                          'Ancaman Ditemukan:',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                    Text(
                      '$_threatsFoundCount ancaman • $_elapsedSeconds dtk berjalan',
                      style: TextStyle(
                        color: _threatsFoundCount > 0 ? Colors.redAccent : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Header Log Proses
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.terminal, size: 15, color: subTextColor),
                  const SizedBox(width: 6),
                  Text(
                    'Log Proses Pemindaian (${_processLogs.length} baris)',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (!_isScanning && _processLogs.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _processLogs.clear()),
                  child: Text(
                    'Bersihkan Log',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Terminal Log Box
          Container(
            height: 165,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isScanning && _currentFile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '▶ Sedang memeriksa: $_currentFile',
                      style: const TextStyle(
                        color: Color(0xFF58A6FF),
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: _processLogs.length,
                    itemBuilder: (context, index) {
                      final item = _processLogs[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          item.message,
                          style: TextStyle(
                            color: item.isThreat
                                ? const Color(0xFFFF7B72)
                                : const Color(0xFF8B949E),
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: item.isThreat ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLoc.tr(context, 'Pemindaian tetap berjalan di latar belakang meski Anda keluar dari aplikasi.'),
            style: TextStyle(color: subTextColor, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required BuildContext context,
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required Color color, 
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: InkWell(
          onTap: _isScanning ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white24 : Colors.white.withOpacity(0.8)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLoc.tr(context, title), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 4),
                      Text(AppLoc.tr(context, subtitle), style: TextStyle(fontSize: 13, color: subTextColor)),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, color: subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        shape: BoxShape.circle,
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
