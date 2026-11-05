import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/native_channel.dart';
import '../../../core/localization.dart';

class QuarantineScreen extends StatefulWidget {
  const QuarantineScreen({super.key});

  @override
  State<QuarantineScreen> createState() => _QuarantineScreenState();
}

class _QuarantineScreenState extends State<QuarantineScreen> {
  List<Map<String, dynamic>> _quarantineItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final items = await KasperskyChannel.getQuarantineList();
    if (!mounted) return;
    setState(() {
      _quarantineItems = items;
      _isLoading = false;
    });
  }

  Future<void> _restoreItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pulihkan Berkas?'),
        content: Text(
          'Berkas "${item['fileName']}" akan dipindahkan kembali ke folder Downloads. Pastikan Anda hanya memulihkan berkas jika yakin aman.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Pulihkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final qName = item['quarantineName']?.toString() ?? '';
    final success = await KasperskyChannel.restoreQuarantineItem(qName);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Berkas berhasil dipulihkan ke folder Downloads.'
              : 'Gagal memulihkan berkas.',
        ),
      ),
    );
    _loadItems();
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Permanen?'),
        content: Text(
          'Berkas "${item['fileName']}" akan dimusnahkan secara permanen dari perangkat dan tidak dapat dipulihkan lagi.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final qName = item['quarantineName']?.toString() ?? '';
    final success = await KasperskyChannel.deleteQuarantineItem(qName);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Berkas berhasil dimusnahkan secara permanen.'
              : 'Gagal menghapus berkas.',
        ),
      ),
    );
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          AppLoc.tr(context, 'Ruang Karantina'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Segarkan',
            onPressed: _loadItems,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quarantineItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.shieldCheck, size: 64, color: Colors.green),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Ruang Karantina Bersih',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada berkas atau malware yang sedang diisolasi. Perangkat Anda dalam kondisi terlindungi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: subTextColor, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quarantineItems.length,
                  itemBuilder: (context, index) {
                    final item = _quarantineItems[index];
                    return _buildQuarantineCard(item, isDark, textColor, subTextColor);
                  },
                ),
    );
  }

  Widget _buildQuarantineCard(
    Map<String, dynamic> item,
    bool isDark,
    Color textColor,
    Color subTextColor,
  ) {
    final fileName = item['fileName']?.toString() ?? 'Berkas Tidak Dikenal';
    final virusName = item['virusName']?.toString() ?? 'Malware / Berbahaya';
    final dateStr = item['dateStr']?.toString() ?? '-';
    final filePath = item['filePath']?.toString() ?? '';
    final source = item['source']?.toString() ?? 'Kaspersky Vault';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.packageCheck, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Deteksi: $virusName',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  source,
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (filePath.isNotEmpty) ...[
            Text(
              'Lokasi Asli: $filePath',
              style: TextStyle(color: subTextColor, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            'Diisolasi pada: $dateStr',
            style: TextStyle(color: subTextColor, fontSize: 11),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _restoreItem(item),
                icon: const Icon(LucideIcons.rotateCcw, size: 14),
                label: const Text('Pulihkan', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _deleteItem(item),
                icon: const Icon(LucideIcons.trash2, size: 14),
                label: const Text('Hapus Permanen', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

