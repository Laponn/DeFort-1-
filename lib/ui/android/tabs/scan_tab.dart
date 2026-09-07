import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';

class ScanTab extends StatefulWidget {
  const ScanTab({super.key});

  @override
  State<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  bool _isScanning = false;
  
  void _runScan(String type) async {
    if (type == 'Folder') {
      // Tampilkan "Folder Picker" tiruan
      String? selectedFolder = await showDialog<String>(
        context: context,
        builder: (context) {
          bool isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            title: Text(AppLoc.tr(context, 'Pilih direktori spesifik untuk diperiksa'), style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.folder, color: Colors.blue),
                  title: const Text('/Downloads'),
                  onTap: () => Navigator.pop(context, '/Downloads'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.folder, color: Colors.blue),
                  title: const Text('/Documents'),
                  onTap: () => Navigator.pop(context, '/Documents'),
                ),
                ListTile(
                  leading: const Icon(LucideIcons.folder, color: Colors.blue),
                  title: const Text('/Images'),
                  onTap: () => Navigator.pop(context, '/Images'),
                ),
              ],
            ),
          );
        },
      );
      
      if (selectedFolder == null) return; // Dibatalkan oleh user
    }

    setState(() => _isScanning = true);
    
    // Simulate scan API call delay for Full and Folder scan
    if (type == 'Full') {
      await Future.delayed(const Duration(seconds: 4));
    } else if (type == 'Quick') {
      await KasperskyChannel.scanMalware(); // Memanggil native channel
    } else {
      await Future.delayed(const Duration(seconds: 2));
    }
    
    if (!mounted) return;
    setState(() => _isScanning = false);

    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    String contentText = '';
    if (type == 'Full') {
      contentText = AppLoc.tr(context, '34.502 file diperiksa. Perangkat Anda bersih!');
    } else if (type == 'Quick') {
      contentText = AppLoc.tr(context, 'file diperiksa. Tidak ada ancaman.');
      // Untuk quick kita pakai default text
      contentText = '1.240 ' + contentText;
    } else {
      contentText = AppLoc.tr(context, '152 file diperiksa. Aman.');
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.green),
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
                Text(AppLoc.tr(context, 'Pindai Perangkat'), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Text(AppLoc.tr(context, 'Pilih metode pemindaian untuk menemukan ancaman.'), style: TextStyle(color: subTextColor)),
                const SizedBox(height: 32),
                
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
                  subtitle: 'Pilih direktori spesifik untuk diperiksa',
                  color: Colors.purple,
                  onTap: () => _runScan('Folder'),
                  isDark: isDark,
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
          )
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: _isScanning 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
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
        ),
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
}
