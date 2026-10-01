import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../core/scan_history.dart';
import '../../../ui/shared/glass_widgets.dart';
import 'package:provider/provider.dart';
import '../../../main.dart';

class IdentityTab extends StatefulWidget {
  const IdentityTab({super.key});

  @override
  State<IdentityTab> createState() => _IdentityTabState();
}

class _IdentityTabState extends State<IdentityTab> {
  final TextEditingController _urlController = TextEditingController();
  bool _isCheckingUrl = false;
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _checkUrl() async {
    // Validate URL first
    final validationError = Validators.url(_urlController.text);
    if (validationError != null) {
      setState(() => _urlError = validationError);
      return;
    }
    setState(() => _urlError = null);
    
    setState(() => _isCheckingUrl = true);
    
    final result = await KasperskyChannel.checkUrlPhishing(_urlController.text);
    
    if (!mounted) return;
    setState(() => _isCheckingUrl = false);
    
    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${result['error']}'),
        backgroundColor: AppColors.error,
      ));
    } else {
      bool isSafe = result['isSafe'] ?? false;
      List<dynamic> categories = result['categories'] ?? [];
      
      // Simpan ke riwayat
      ScanHistoryService.addRecord(ScanRecord(
        type: 'url',
        timestamp: DateTime.now(),
        filesScanned: 0,
        malwareCount: isSafe ? 0 : (categories.isEmpty ? 1 : categories.length),
        malwareList: isSafe ? [] : categories.map((e) => e.toString()).toList(),
        isRealSdk: result['isRealSdk'] == true,
        folderPath: _urlController.text,
      ));
      
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = AppColors.textPrimary(isDark);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isSafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isSafe ? AppColors.success : AppColors.error),
              const SizedBox(width: 8),
              Text(AppLoc.tr(context, isSafe ? 'Tautan Aman' : 'Bahaya Phishing!'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            isSafe 
                ? AppLoc.tr(context, 'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.') 
                : '${AppLoc.tr(context, 'URL ini terdeteksi sebagai ancaman. Kategori:')} ${categories.join(", ")}',
            style: TextStyle(color: textColor)
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
  }

  void _toggleFakeAppMonitor(bool val, AppState appState) async {
    if (val) {
       bool success = await KasperskyChannel.startFakeAppMonitor();
       if (success) {
         appState.toggleFakeAppMonitor(true);
         
         // Simpan log aktivitas
         ScanHistoryService.addRecord(ScanRecord(
           type: 'app_monitor',
           timestamp: DateTime.now(),
           filesScanned: 0,
           malwareCount: 0,
           malwareList: [],
           isRealSdk: true,
           folderPath: 'Monitor diaktifkan',
         ));

         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text(AppLoc.tr(context, 'Pemantauan Aplikasi Palsu Diaktifkan')),
             backgroundColor: AppColors.success,
           ));
         }
       }
    } else {
       appState.toggleFakeAppMonitor(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = AppColors.textPrimary(isDark);
    final subTextColor = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: AppColors.bg(isDark),
      body: Stack(
        children: [
          Positioned(top: 50, left: -50, child: BackgroundBlob(color: AppColors.blobRed, size: 300)),
          Positioned(bottom: 100, right: -50, child: BackgroundBlob(color: AppColors.blobOrange, size: 250)),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(AppLoc.tr(context, 'Identitas & Privasi'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Lindungi diri dari Phishing dan Aplikasi Palsu.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),

                // Manual URL Check
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.search, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(AppLoc.tr(context, 'Periksa Tautan (Anti-Phishing)'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _urlController,
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                                  onChanged: (_) {
                                    if (_urlError != null) setState(() => _urlError = null);
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'https://example.com',
                                    hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
                                    filled: true,
                                    fillColor: isDark ? Colors.grey[800]!.withOpacity(0.8) : Colors.white.withOpacity(0.9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(color: _urlError != null ? AppColors.error : subTextColor.withOpacity(0.2), width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(color: _urlError != null ? AppColors.error : subTextColor.withOpacity(0.2), width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12), 
                                      borderSide: BorderSide(color: _urlError != null ? AppColors.error : AppColors.warning, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    errorText: _urlError,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ElevatedButton(
                              onPressed: _isCheckingUrl ? null : _checkUrl,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isCheckingUrl 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                  : Text(AppLoc.tr(context, 'Cek')),
                            ),
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
                  icon: LucideIcons.globe, 
                  color: isDark ? Colors.lightBlue : Colors.blue, 
                  title: 'Web Filter / Anti-Phishing', 
                  subtitle: 'Memblokir situs penipuan secara otomatis', 
                  value: appState.isAntiPhishingActive, 
                  onChanged: (v) => appState.toggleAntiPhishing(v),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 12),
                _buildSwitchCard(
                  icon: LucideIcons.smartphone, 
                  color: isDark ? Colors.purpleAccent : Colors.purple, 
                  title: 'Monitor Aplikasi Palsu', 
                  subtitle: 'Memindai aplikasi yang baru diinstal', 
                  value: appState.isFakeAppMonitorActive, 
                  onChanged: (v) => _toggleFakeAppMonitor(v, appState),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),

                const SizedBox(height: 100), // Bottom nav padding
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return GlassCard(
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
}
