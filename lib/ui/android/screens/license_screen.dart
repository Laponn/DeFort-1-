import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/localization.dart';
import '../../../core/native_channel.dart';

class KasperskyLicenseScreen extends StatefulWidget {
  const KasperskyLicenseScreen({super.key});

  @override
  State<KasperskyLicenseScreen> createState() => _KasperskyLicenseScreenState();
}

class _KasperskyLicenseScreenState extends State<KasperskyLicenseScreen> {
  bool _isLoading = true;
  bool _isVerifying = false;
  Map<String, dynamic> _info = {};

  @override
  void initState() {
    super.initState();
    _loadLicenseInfo();
  }

  Future<void> _loadLicenseInfo() async {
    setState(() => _isLoading = true);
    final info = await KasperskyChannel.getKasperskyLicenseInfo();
    if (!mounted) return;
    setState(() {
      _info = info;
      _isLoading = false;
    });
  }

  Future<void> _verifyLicense() async {
    setState(() => _isVerifying = true);
    final res = await KasperskyChannel.verifyKasperskyLicense();
    await _loadLicenseInfo();
    if (!mounted) return;
    setState(() => _isVerifying = false);

    final isEn = AppLoc.lang(context) == 'en';
    final valid = res['isLicenseValid'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          valid
              ? (isEn
                  ? 'Kaspersky SDK license verified and active!'
                  : 'Lisensi Kaspersky SDK berhasil diverifikasi dan aktif!')
              : (isEn
                  ? 'License verification failed. Check your internet connection.'
                  : 'Verifikasi lisensi gagal. Pastikan perangkat terhubung ke internet.'),
        ),
        backgroundColor: valid ? const Color(0xFF10B981) : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatDate(int ms, bool isEn) {
    if (ms <= 0) return isEn ? 'Active (SDK Managed)' : 'Aktif (Dikelola SDK)';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final monthsId = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = isEn ? monthsEn[dt.month - 1] : monthsId[dt.month - 1];
    return '${dt.day.toString().padLeft(2, '0')} $m ${dt.year}';
  }

  String _formatNumber(dynamic n) {
    final val = (n is int) ? n : int.tryParse(n?.toString() ?? '0') ?? 0;
    if (val <= 0) return '-';
    final s = val.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  String _formatBytes(dynamic b) {
    final bytes = (b is int) ? b : int.tryParse(b?.toString() ?? '0') ?? 0;
    if (bytes <= 0) return '-';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(1)} KB';
  }

  void _copyText(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    final isEn = AppLoc.lang(context) == 'en';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEn ? '$label copied to clipboard' : '$label disalin ke papan klip'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLoc.lang(context) == 'en';
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final isValid = _info['isLicenseValid'] == true;
    final isSdkInit = _info['isSdkInitialized'] == true;
    final cloudOk = _info['cloudCheckAvailable'] == true;
    final dbOk = _info['virusDbAvailable'] == true;
    final expireMs = (_info['expireDateMs'] is int) ? _info['expireDateMs'] as int : 0;
    final sdkVersion = (_info['sdkVersion'] ?? '5.23.0.212').toString();
    final maskedKey = (_info['maskedKey'] ?? 'ZCY92-*****-*****-6TAMN').toString();
    final installId = (_info['installationId'] ?? '-').toString();
    final dbDate = (_info['virusDbDate'] ?? '-').toString();
    final knownThreats = _info['knownThreatsCount'] ?? 0;
    final dbRecords = _info['virusDbRecords'] ?? 0;
    final dbSize = _info['virusDbSizeBytes'] ?? 0;

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
          AppLoc.tr(context, 'Lisensi Kaspersky'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 19),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: textColor, size: 20),
            onPressed: _isLoading ? null : _loadLicenseInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(top: -40, right: -40, child: _buildBlob(const Color(0xFF10B981), 220)),
          Positioned(bottom: 60, left: -60, child: _buildBlob(const Color(0xFF6366F1), 240)),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadLicenseInfo,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
                    children: [
                      // Hero License Status Card
                      _buildHeroCard(
                        isDark: isDark,
                        isEn: isEn,
                        isValid: isValid,
                        expireMs: expireMs,
                        maskedKey: maskedKey,
                        sdkVersion: sdkVersion,
                      ),
                      const SizedBox(height: 20),

                      // Engine & Virus Database Details
                      Text(
                        isEn ? 'Engine & Virus Database' : 'Detail Mesin & Basis Data Virus',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _buildDetailRow(
                              icon: LucideIcons.cpu,
                              iconColor: Colors.indigoAccent,
                              label: isEn ? 'SDK Engine Status' : 'Status Engine SDK',
                              value: isSdkInit
                                  ? (isEn ? 'Active & Ready' : 'Aktif & Siap')
                                  : (isEn ? 'Initializing' : 'Inisialisasi'),
                              valueColor: isSdkInit ? const Color(0xFF10B981) : Colors.amber,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.layers,
                              iconColor: Colors.blueAccent,
                              label: isEn ? 'Kaspersky SDK Version' : 'Versi Kaspersky SDK',
                              value: sdkVersion,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.cloud,
                              iconColor: Colors.cyan,
                              label: 'Kaspersky Security Network',
                              value: cloudOk
                                  ? (isEn ? 'Connected (Cloud KSN)' : 'Terhubung (Cloud KSN)')
                                  : (isEn ? 'Local Mode' : 'Mode Lokal'),
                              valueColor: cloudOk ? const Color(0xFF10B981) : Colors.orangeAccent,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.database,
                              iconColor: Colors.teal,
                              label: isEn ? 'Virus DB Status' : 'Status Basis Data Virus',
                              value: dbOk
                                  ? (isEn ? 'Available' : 'Tersedia')
                                  : (isEn ? 'Checking...' : 'Memeriksa...'),
                              valueColor: dbOk ? const Color(0xFF10B981) : Colors.amber,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.calendarClock,
                              iconColor: Colors.purpleAccent,
                              label: isEn ? 'Database Release Date' : 'Tanggal Basis Data',
                              value: dbDate,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.bugOff,
                              iconColor: Colors.redAccent,
                              label: isEn ? 'Known Threat Signatures' : 'Jumlah Signature Ancaman',
                              value: _formatNumber(knownThreats > 0 ? knownThreats : dbRecords),
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildDetailRow(
                              icon: LucideIcons.hardDrive,
                              iconColor: Colors.amber,
                              label: isEn ? 'Database Size' : 'Ukuran Basis Data',
                              value: _formatBytes(dbSize),
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            Row(
                              children: [
                                Icon(LucideIcons.fingerprint, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isEn ? 'Installation ID' : 'ID Instalasi Perangkat',
                                        style: TextStyle(fontSize: 12, color: subTextColor),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        installId,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (installId != '-')
                                  IconButton(
                                    icon: Icon(LucideIcons.copy, size: 16, color: subTextColor),
                                    onPressed: () => _copyText(
                                      isEn ? 'Installation ID' : 'ID Instalasi',
                                      installId,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Licensed Protection Modules
                      Text(
                        isEn ? 'Licensed Protection Modules' : 'Modul Perlindungan Berlisensi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      const SizedBox(height: 12),
                      _buildGlassCard(
                        isDark: isDark,
                        child: Column(
                          children: [
                            _buildModuleRow(
                              title: isEn ? 'Antivirus & EasyScanner Engine' : 'Mesin Antivirus & EasyScanner',
                              subtitle: isEn ? 'Quick, Full & Custom Folder scanning' : 'Pemindaian Cepat, Menyeluruh & Folder',
                              active: isValid || isSdkInit,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildModuleRow(
                              title: 'WebFilter & Anti-Phishing Shield',
                              subtitle: isEn ? 'Real-time malicious URL interception' : 'Pemblokiran tautan phishing secara real-time',
                              active: isValid || isSdkInit,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildModuleRow(
                              title: isEn ? 'Wi-Fi Reputation & DNS Inspector' : 'Reputasi Wi-Fi & Pemeriksa DNS',
                              subtitle: isEn ? 'Network safety, encryption & SSL checks' : 'Audit keamanan Wi-Fi, enkripsi & sertifikat SSL',
                              active: isValid || isSdkInit,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                            _divider(textColor),
                            _buildModuleRow(
                              title: isEn ? 'Quarantine & Background Guards' : 'Karantina & Penjaga Latar Belakang',
                              subtitle: isEn ? 'Auto-Scan APK & Download Folder Monitor' : 'Auto-Scan APK Baru & Pemantau Folder Unduhan',
                              active: isValid || isSdkInit,
                              textColor: textColor,
                              subTextColor: subTextColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Re-Verify License Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isVerifying ? null : _verifyLicense,
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(LucideIcons.shieldCheck, size: 20),
                          label: Text(
                            _isVerifying
                                ? (isEn ? 'Verifying License...' : 'Memverifikasi Lisensi...')
                                : (isEn ? 'Re-Verify License Now' : 'Verifikasi Ulang Lisensi'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
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

  Widget _buildHeroCard({
    required bool isDark,
    required bool isEn,
    required bool isValid,
    required int expireMs,
    required String maskedKey,
    required String sdkVersion,
  }) {
    final gradientColors = isValid
        ? [const Color(0xFF065F46), const Color(0xFF047857), const Color(0xFF10B981)]
        : [const Color(0xFF92400E), const Color(0xFFB45309), const Color(0xFFD97706)];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isValid ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isValid
                            ? (isEn ? 'LICENSE ACTIVE' : 'LISENSI AKTIF')
                            : (isEn ? 'VERIFICATION NEEDED' : 'PERLU VERIFIKASI'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kaspersky Mobile SDK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEn ? 'Activation Key' : 'Kode Aktivasi',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      maskedKey,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.copy, color: Colors.white, size: 18),
                  onPressed: () => _copyText(isEn ? 'License key' : 'Kode lisensi', maskedKey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${isEn ? 'Valid Until' : 'Berlaku Hingga'}: ${_formatDate(expireMs, isEn)}',
                style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'v$sdkVersion',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: subTextColor)),
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

  Widget _buildModuleRow({
    required String title,
    required String subtitle,
    required bool active,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      children: [
        Icon(
          active ? LucideIcons.checkCircle2 : LucideIcons.clock,
          color: active ? const Color(0xFF10B981) : Colors.amber,
          size: 20,
        ),
        const SizedBox(width: 12),
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

  Widget _divider(Color textColor) => Divider(color: textColor.withOpacity(0.08), height: 22);

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.72) : Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(20),
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
      decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
