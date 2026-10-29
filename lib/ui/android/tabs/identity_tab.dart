import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import 'dart:convert';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/url_analyzer.dart';
import '../../../core/database_helper.dart';
import '../../../core/scan_history_item.dart';
import '../screens/history_screen.dart';

class IdentityTab extends StatefulWidget {
  const IdentityTab({super.key});

  @override
  State<IdentityTab> createState() => _IdentityTabState();
}

class _IdentityTabState extends State<IdentityTab> {
  final TextEditingController _urlController = TextEditingController();
  bool _isCheckingUrl = false;
  
  bool _isAntiPhishingActive = true;
  bool _isFakeAppMonitorActive = false;

  void _checkUrl() async {
    FocusScope.of(context).unfocus();
    final input = _urlController.text;

    // 1. Rapikan & validasi input sebelum dikirim ke Kaspersky
    final url = UrlAnalyzer.normalize(input);
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLoc.tr(context, 'Format URL tidak valid. Contoh: google.com atau https://example.com')),
      ));
      return;
    }

    setState(() => _isCheckingUrl = true);

    // 2. Kirim ke Kaspersky SDK lewat MethodChannel
    final native = await KasperskyChannel.checkUrlPhishing(url);

    if (!mounted) return; // tab sudah ditutup saat menunggu hasil
    setState(() => _isCheckingUrl = false);

    // 3. Tangani error dengan pesan yang jelas sesuai kodenya
    if (native.containsKey('error')) {
      _showErrorDialog(native['code'] as String?, native['error']?.toString());
      return;
    }

    // 4. Gabungkan verdict Kaspersky + heuristik lokal menjadi daftar alasan
    final result = UrlAnalyzer.analyze(input: input, url: url, native: native);
    
    // 5. Simpan ke riwayat/database
    try {
      final detailsJson = jsonEncode({
        'url': result.url,
        'reasons': result.reasons.map((r) => r.text(AppLoc.lang(context))).toList(),
      });

      await DatabaseHelper.instance.insertScan(ScanHistoryItem(
        scanType: 'URL',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        statusLevel: result.safety == UrlSafety.safe ? 'SAFE' : (result.safety == UrlSafety.dangerous ? 'DANGER' : 'WARNING'),
        summary: result.summary(AppLoc.lang(context)),
        details: detailsJson,
      ));
    } catch (e) {
      debugPrint('Gagal simpan riwayat: $e');
    }

    _showResultDialog(result);
  }

  /// Pesan error yang mudah dipahami berdasarkan kode dari native.
  String _errorMessage(String? code) {
    switch (code) {
      case 'SDK_NOT_READY':
        return 'Kaspersky SDK masih melakukan inisialisasi. Coba lagi dalam beberapa detik.';
      case 'LICENSE_INVALID':
        return 'Lisensi Kaspersky tidak valid atau belum aktif. Pastikan perangkat terhubung ke internet lalu buka ulang aplikasi.';
      case 'NETWORK_ERROR':
        return 'Tidak dapat terhubung ke server Kaspersky. Periksa koneksi internet Anda.';
      case 'TIMEOUT':
        return 'Server Kaspersky tidak merespons. Coba lagi nanti.';
      case 'INVALID_URL':
        return 'Format URL tidak valid. Contoh: google.com atau https://example.com';
      default:
        return 'Terjadi kesalahan saat memeriksa URL.';
    }
  }

  void _showErrorDialog(String? code, String? detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black45;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertCircle, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLoc.tr(context, 'Pemeriksaan Gagal'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLoc.tr(context, _errorMessage(code)), style: TextStyle(color: textColor)),
            const SizedBox(height: 12),
            // Detail teknis, berguna saat debugging
            Text('[$code] ${detail ?? '-'}', style: TextStyle(color: subTextColor, fontSize: 11)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLoc.tr(context, 'Tutup'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(UrlCheckResult result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final lang = AppLoc.lang(context);

    // Warna, ikon, dan judul sesuai status akhir
    final (Color color, IconData icon, String title) = switch (result.safety) {
      UrlSafety.safe => (Colors.green, LucideIcons.checkCircle, 'Tautan Aman'),
      UrlSafety.dangerous => (Colors.red, LucideIcons.alertTriangle, 'Tautan Berbahaya!'),
      UrlSafety.unknown => (Colors.amber.shade700, Icons.help_outline, 'Tidak Dapat Dipastikan'),
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(AppLoc.tr(context, title), style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL yang diperiksa
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(result.url, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                // Kesimpulan
                Text(result.summary(lang), style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Text(AppLoc.tr(context, 'Alasan'), style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                // Daftar alasan
                ...result.reasons.map((r) => _buildReasonRow(r, lang, textColor)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLoc.tr(context, 'Tutup'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonRow(UrlReason reason, String lang, Color textColor) {
    final (IconData icon, Color color) = switch (reason.level) {
      ReasonLevel.ok => (LucideIcons.checkCircle2, Colors.green),
      ReasonLevel.info => (Icons.info_outline, Colors.blueGrey),
      ReasonLevel.warning => (LucideIcons.alertCircle, Colors.orange),
      ReasonLevel.danger => (LucideIcons.alertTriangle, Colors.red),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(reason.text(lang), style: TextStyle(color: textColor, fontSize: 13, height: 1.35))),
        ],
      ),
    );
  }

  void _toggleFakeAppMonitor(bool val) async {
    if (val) {
       bool success = await KasperskyChannel.startFakeAppMonitor();
       setState(() => _isFakeAppMonitorActive = success);
       if (success) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLoc.tr(context, 'Pemantauan Aplikasi Palsu Diaktifkan'))));
       }
    } else {
       setState(() => _isFakeAppMonitorActive = false);
    }
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
          Positioned(top: 50, left: -50, child: _buildBlob(const Color(0xFFFCA5A5), 300)),
          Positioned(bottom: 100, right: -50, child: _buildBlob(const Color(0xFFFDBA74), 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLoc.tr(context, 'Identitas & Privasi'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
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
                Text(AppLoc.tr(context, 'Lindungi diri dari Phishing dan Aplikasi Palsu.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),

                // Manual URL Check
                _buildGlassCard(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.search, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(AppLoc.tr(context, 'Periksa Tautan (Anti-Phishing)'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _urlController,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                hintText: 'https://example.com',
                                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                                filled: true,
                                fillColor: isDark ? Colors.grey[800]!.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: BorderSide(color: subTextColor.withOpacity(0.2), width: 1),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: BorderSide(color: subTextColor.withOpacity(0.2), width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12), 
                                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isCheckingUrl ? null : _checkUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: _isCheckingUrl ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(color:Colors.white, strokeWidth:2)) : Text(AppLoc.tr(context, 'Cek')),
                          )
                        ],
                      )
                    ],
                  )
                ),

                const SizedBox(height: 24),
                Text(AppLoc.tr(context, 'Perlindungan Real-time'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 16),

                _buildSwitchCard(
                  context,
                  icon: LucideIcons.globe, 
                  color: isDark ? Colors.lightBlue : Colors.blue, 
                  title: 'Web Filter / Anti-Phishing', 
                  subtitle: 'Memblokir situs penipuan secara otomatis', 
                  value: _isAntiPhishingActive, 
                  onChanged: (v) => setState(() => _isAntiPhishingActive = v)
                ),
                const SizedBox(height: 12),
                _buildSwitchCard(
                  context,
                  icon: LucideIcons.smartphone, 
                  color: isDark ? Colors.purpleAccent : Colors.purple, 
                  title: 'Monitor Aplikasi Palsu', 
                  subtitle: 'Memindai aplikasi yang baru diinstal', 
                  value: _isFakeAppMonitorActive, 
                  onChanged: _toggleFakeAppMonitor
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwitchCard(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required bool value, required Function(bool) onChanged}) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return _buildGlassCard(
      context,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLoc.tr(context, title), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                Text(AppLoc.tr(context, subtitle), style: TextStyle(color: subTextColor, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          )
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
