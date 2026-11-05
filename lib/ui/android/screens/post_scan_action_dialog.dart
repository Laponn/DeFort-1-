import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import 'quarantine_screen.dart';

class PostScanActionDialog extends StatefulWidget {
  final Map<String, dynamic> scanResult;
  final VoidCallback? onNavigateToNetwork;
  final VoidCallback? onNavigateToIdentity;

  const PostScanActionDialog({
    super.key,
    required this.scanResult,
    this.onNavigateToNetwork,
    this.onNavigateToIdentity,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> scanResult,
    VoidCallback? onNavigateToNetwork,
    VoidCallback? onNavigateToIdentity,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PostScanActionDialog(
        scanResult: scanResult,
        onNavigateToNetwork: onNavigateToNetwork,
        onNavigateToIdentity: onNavigateToIdentity,
      ),
    );
  }

  @override
  State<PostScanActionDialog> createState() => _PostScanActionDialogState();
}

class _PostScanActionDialogState extends State<PostScanActionDialog> {
  final Map<String, String> _processedThreats =
      {}; // threatId -> 'quarantined' | 'deleted' | 'error'
  bool _isBulkProcessing = false;
  late List<Map<String, dynamic>> _threats;
  late bool _hasThreat;
  late int _malwareCount;
  late int _filesScanned;
  late int _objectsScanned;
  late int _elapsedSec;
  late bool _isRooted;
  late String? _scannedFolder;

  @override
  void initState() {
    super.initState();
    _parseResult();
  }

  void _parseResult() {
    final res = widget.scanResult;
    _malwareCount = (res['malwareCount'] as num?)?.toInt() ?? 0;
    _filesScanned = (res['filesScanned'] as num?)?.toInt() ?? 0;
    _objectsScanned = (res['objectsScanned'] as num?)?.toInt() ?? _filesScanned;
    _elapsedSec = (res['elapsedSeconds'] as num?)?.toInt() ?? 0;
    _isRooted = res['isDeviceRooted'] == true;
    _scannedFolder = res['folderPath'] as String?;

    final rawThreats = res['threats'] as List?;
    if (rawThreats != null && rawThreats.isNotEmpty) {
      _threats = rawThreats
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      final names = res['malwareList'] as List? ?? [];
      _threats = names.map((name) {
        final id = 'fallback_${name.hashCode}';
        return {
          'id': id,
          'virusName': name.toString(),
          'filePath': _scannedFolder ?? '',
          'objectName': name.toString(),
          'packageName': '',
          'isApplication': false,
          'severity': 'High',
        };
      }).toList();
    }

    _hasThreat = _malwareCount > 0 || _isRooted || _threats.isNotEmpty;
  }

  Future<void> _quarantineThreat(Map<String, dynamic> threat) async {
    final id = threat['id']?.toString() ?? '';
    final name = threat['virusName']?.toString() ?? 'Berkas';

    final result = await KasperskyChannel.quarantineThreat(
      id,
      filePath: threat['filePath']?.toString(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _processedThreats[id] = 'quarantined';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: Text('📦 "$name" berhasil diisolasi ke Ruang Karantina.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text(
            result['message']?.toString() ?? 'Gagal mengkarantina berkas.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteThreat(Map<String, dynamic> threat) async {
    final id = threat['id']?.toString() ?? '';
    final name = threat['virusName']?.toString() ?? 'Berkas';
    final isApp = threat['isApplication'] == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isApp ? 'Copot Pemasangan Aplikasi?' : 'Hapus Berkas Permanen?',
        ),
        content: Text(
          isApp
              ? 'Aplikasi "$name" terdeteksi berbahaya. Sistem akan membuka permintaan pencopotan aplikasi.'
              : 'Berkas ancaman "$name" akan dihapus secara permanen dari penyimpanan perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApp ? 'Copot' : 'Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await KasperskyChannel.deleteThreat(
      id,
      filePath: threat['filePath']?.toString(),
      packageName: threat['packageName']?.toString(),
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _processedThreats[id] = 'deleted';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('🗑️ "$name": ${result['message']}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text(
            result['message']?.toString() ?? 'Gagal menghapus berkas.',
          ),
        ),
      );
    }
  }

  Future<void> _quarantineAll() async {
    setState(() => _isBulkProcessing = true);
    int successCount = 0;

    for (final threat in _threats) {
      final id = threat['id']?.toString() ?? '';
      if (_processedThreats.containsKey(id)) continue;

      final res = await KasperskyChannel.quarantineThreat(
        id,
        filePath: threat['filePath']?.toString(),
      );
      if (res['success'] == true) {
        _processedThreats[id] = 'quarantined';
        successCount++;
      }
    }

    if (!mounted) return;
    setState(() => _isBulkProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange.shade800,
        content: Text(
          '📦 $successCount berkas berhasil diisolasi ke Ruang Karantina.',
        ),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Ancaman?'),
        content: const Text(
          'Seluruh berkas berbahaya yang terdeteksi akan dihapus secara permanen atau dicopot pemasangannya dari perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isBulkProcessing = true);
    int successCount = 0;

    for (final threat in _threats) {
      final id = threat['id']?.toString() ?? '';
      if (_processedThreats.containsKey(id)) continue;

      final res = await KasperskyChannel.deleteThreat(
        id,
        filePath: threat['filePath']?.toString(),
        packageName: threat['packageName']?.toString(),
      );
      if (res['success'] == true) {
        _processedThreats[id] = 'deleted';
        successCount++;
      }
    }

    if (!mounted) return;
    setState(() => _isBulkProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade800,
        content: Text(
          '🗑️ Tindakan selesai untuk $successCount berkas/aplikasi berbahaya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBgColor = isDark ? const Color(0xFF161B22) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _hasThreat
                        ? Colors.red.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _hasThreat
                        ? LucideIcons.alertTriangle
                        : LucideIcons.shieldCheck,
                    color: _hasThreat ? Colors.red : Colors.green,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasThreat
                            ? 'Ditemukan $_malwareCount Ancaman!'
                            : 'Perangkat Aman & Bersih',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _hasThreat ? Colors.redAccent : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hasThreat
                            ? 'Segera ambil tindakan isolasi atau hapus berkas'
                            : '$_filesScanned file berhasil dipindai • 0 Ancaman',
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: textColor.withOpacity(0.6),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_hasThreat) ...[
                  _buildThreatResolutionSection(
                    context,
                    isDark,
                    textColor,
                    subTextColor,
                  ),
                ] else ...[
                  _buildCleanPreventionSection(
                    context,
                    isDark,
                    textColor,
                    subTextColor,
                  ),
                ],
              ],
            ),
          ),

          // Bottom Action Bar
          _buildBottomBar(context, isDark, textColor),
        ],
      ),
    );
  }

  // ==========================================
  // KONDISI 1: DITEMUKAN ANCAMAN (THREATS FOUND)
  // ==========================================
  Widget _buildThreatResolutionSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isRooted) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.shieldAlert, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Perangkat Anda memiliki akses ROOT. Hak akses root memudahkan malware memodifikasi sistem.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Bulk Actions Bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tindakan Lanjutan Massal:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBulkProcessing ? null : _quarantineAll,
                      icon: const Icon(LucideIcons.packageCheck, size: 16),
                      label: const Text(
                        'Karantina Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isBulkProcessing ? null : _deleteAll,
                      icon: const Icon(LucideIcons.trash2, size: 16),
                      label: const Text(
                        'Hapus Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Daftar Berkas Terdeteksi (${_threats.length}):',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),

        ..._threats.map(
          (threat) =>
              _buildThreatItemCard(threat, isDark, textColor, subTextColor),
        ),
      ],
    );
  }

  Widget _buildThreatItemCard(
    Map<String, dynamic> threat,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final id = threat['id']?.toString() ?? '';
    final virusName = threat['virusName']?.toString() ?? 'Malware';
    final filePath = threat['filePath']?.toString() ?? '';
    final isApp = threat['isApplication'] == true;
    final severity = threat['severity']?.toString() ?? 'High';
    final status = _processedThreats[id];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status == 'quarantined'
              ? Colors.orange.withOpacity(0.6)
              : status == 'deleted'
              ? Colors.grey.withOpacity(0.4)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isApp
                      ? Colors.purple.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApp ? LucideIcons.smartphone : LucideIcons.fileWarning,
                  color: isApp ? Colors.purpleAccent : Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      virusName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: status != null ? Colors.grey : textColor,
                        decoration: status == 'deleted'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    if (filePath.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        filePath,
                        style: TextStyle(color: subTextColor, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  severity == 'High' ? 'Tinggi' : 'Sedang',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Status or Buttons
          if (status == 'quarantined') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.packageCheck,
                    size: 14,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Telah Dikarantina (Aman & Terisolasi)',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'deleted') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.trash2, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Telah Dihapus / Diproses',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _quarantineThreat(threat),
                  icon: const Icon(LucideIcons.packageCheck, size: 14),
                  label: const Text(
                    'Karantina',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _deleteThreat(threat),
                  icon: const Icon(LucideIcons.trash2, size: 14),
                  label: Text(
                    isApp ? 'Copot App' : 'Hapus File',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // KONDISI 2: TIDAK ADA ANCAMAN (BERSIH & AMAN)
  // Menampilkan Result Total File yang Berhasil Dipindai
  // ==========================================
  Widget _buildCleanPreventionSection(
    BuildContext context,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        // Kartu Utama Total File yang Berhasil Dipindai
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.green,
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$_filesScanned File',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Colors.green,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Berkas Berhasil Dipindai',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Seluruh berkas telah diperiksa dan dinyatakan 100% bersih tanpa ancaman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: subTextColor),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Rincian Hasil Pemindaian
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              _buildMetricRow(
                icon: LucideIcons.files,
                label: 'Total File Dipindai',
                value: '$_filesScanned file',
                valueColor: Colors.green,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 22,
              ),
              _buildMetricRow(
                icon: LucideIcons.layers,
                label: 'Total Objek Internal',
                value: '$_objectsScanned objek',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 22,
              ),
              _buildMetricRow(
                icon: LucideIcons.clock,
                label: 'Durasi Pemindaian',
                value: '$_elapsedSec detik',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 22,
              ),
              _buildMetricRow(
                icon: LucideIcons.folderCheck,
                label: 'Target Pemindaian',
                value: _scannedFolder ?? 'Seluruh Perangkat',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.black12,
                height: 22,
              ),
              _buildMetricRow(
                icon: LucideIcons.shieldCheck,
                label: 'Status Keamanan',
                value: 'Aman (0 Ancaman)',
                valueColor: Colors.green,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: subTextColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: subTextColor),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          if (_hasThreat) ...[
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const QuarantineScreen()),
                );
              },
              icon: const Icon(LucideIcons.packageCheck, size: 16),
              label: const Text(
                'Buka Karantina',
                style: TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasThreat
                    ? Colors.grey.shade800
                    : Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _hasThreat ? 'Tutup Hasil' : 'Selesai',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
