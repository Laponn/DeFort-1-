import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';
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

  void _checkUrl() async {
    if (_urlController.text.isEmpty) return;
    
    setState(() => _isCheckingUrl = true);
    
    final result = await KasperskyChannel.checkUrlPhishing(_urlController.text);
    
    setState(() => _isCheckingUrl = false);
    
    if (result.containsKey('error')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['error']}')));
    } else {
      bool isSafe = result['isSafe'] ?? false;
      List<dynamic> categories = result['categories'] ?? [];
      
      bool isDark = Theme.of(context).brightness == Brightness.dark;
      final textColor = isDark ? Colors.white : Colors.black87;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isSafe ? LucideIcons.checkCircle : LucideIcons.alertTriangle, color: isSafe ? Colors.green : Colors.red),
              const SizedBox(width: 8),
              Text(AppLoc.tr(context, isSafe ? 'Tautan Aman' : 'Bahaya Phishing!'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            isSafe 
                ? AppLoc.tr(context, 'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.') 
                : AppLoc.tr(context, 'URL ini terdeteksi sebagai ancaman. Kategori:') + ' ${categories.join(", ")}',
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
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLoc.tr(context, 'Pemantauan Aplikasi Palsu Diaktifkan'))));
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
                Text(AppLoc.tr(context, 'Identitas & Privasi'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
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
                  value: appState.isAntiPhishingActive, 
                  onChanged: (v) => appState.toggleAntiPhishing(v)
                ),
                const SizedBox(height: 12),
                _buildSwitchCard(
                  context,
                  icon: LucideIcons.smartphone, 
                  color: isDark ? Colors.purpleAccent : Colors.purple, 
                  title: 'Monitor Aplikasi Palsu', 
                  subtitle: 'Memindai aplikasi yang baru diinstal', 
                  value: appState.isFakeAppMonitorActive, 
                  onChanged: (v) => _toggleFakeAppMonitor(v, appState)
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
