import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:ui';
import '../../../core/database_helper.dart';
import '../../../core/scan_history_item.dart';
import '../../../core/localization.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanHistoryItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final items = await DatabaseHelper.instance.getAllScans();
    if (!mounted) return;
    setState(() {
      _historyItems = items;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    await DatabaseHelper.instance.clearHistory();
    _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(AppLoc.tr(context, 'Riwayat Pemindaian'), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Riwayat?'),
                    content: const Text('Semua data riwayat pemindaian akan dihapus permanen.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _clearHistory();
                        }, 
                        child: const Text('Hapus', style: TextStyle(color: Colors.red))
                      ),
                    ],
                  )
                );
              },
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _historyItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.history, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                    const SizedBox(height: 16),
                    Text(AppLoc.tr(context, 'Belum ada riwayat pemindaian'), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _historyItems.length,
                itemBuilder: (context, index) {
                  final item = _historyItems[index];
                  return _buildHistoryCard(item, isDark);
                },
              ),
    );
  }

  Widget _buildHistoryCard(ScanHistoryItem item, bool isDark) {
    final date = DateTime.fromMillisecondsSinceEpoch(item.timestamp);
    final dateString = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    
    IconData icon;
    if (item.scanType == 'NETWORK') icon = LucideIcons.wifi;
    else if (item.scanType == 'MALWARE') icon = LucideIcons.shieldAlert;
    else icon = LucideIcons.search;

    Color statusColor;
    if (item.statusLevel == 'SAFE') statusColor = Colors.green;
    else if (item.statusLevel == 'WARNING') statusColor = Colors.orange;
    else statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: statusColor),
        ),
        title: Text(AppLoc.tr(context, item.scanType), style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(item.summary, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(dateString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.grey),
        onTap: () => _showDetailsDialog(item),
      ),
    );
  }

  void _showDetailsDialog(ScanHistoryItem item) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final detailsMap = item.parsedDetails;
    final reasons = List<String>.from(detailsMap['reasons'] ?? []);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        title: Text(item.scanType),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.summary, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Alasan:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...reasons.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(r)),
                  ],
                ),
              )).toList(),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }
}
