import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/localization.dart';
import 'permissions_screen.dart';
import 'quarantine_screen.dart';

class _FaqItem {
  final String category;
  final String questionId;
  final String answerId;
  final String questionEn;
  final String answerEn;

  const _FaqItem({
    required this.category,
    required this.questionId,
    required this.answerId,
    required this.questionEn,
    required this.answerEn,
  });
}

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _query = '';

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      category: 'protection',
      questionId: 'Bagaimana cara kerja Perlindungan Latar Belakang 24/7?',
      answerId:
          'DeFort menjalankan tiga lapis pengamanan otomatis meski aplikasi sedang ditutup:\n'
          '1. Install Guard: Memindai otomatis setiap aplikasi/APK baru yang dipasang.\n'
          '2. Download Shield: Memantau folder Unduhan (Download) dan langsung mengisolasi file berbahaya.\n'
          '3. Anti-Phishing Shield: Memeriksa tautan yang dibuka di browser secara real-time melalui Layanan Aksesibilitas.',
      questionEn: 'How does 24/7 Background Protection work?',
      answerEn:
          'DeFort runs three automatic layers even when the app is closed:\n'
          '1. Install Guard: Automatically scans every newly installed APK/app.\n'
          '2. Download Shield: Monitors the Download folder and isolates malicious files.\n'
          '3. Anti-Phishing Shield: Inspects browser URLs in real time via Accessibility Service.',
    ),
    _FaqItem(
      category: 'phishing',
      questionId: 'Bagaimana cara kerja pemblokiran tautan phishing otomatis?',
      answerId:
          'Saat Layanan Aksesibilitas DeFort aktif, sistem membaca alamat URL di bilah alamat browser (Chrome, Firefox, Edge, Samsung Internet, Brave, dll.) dan memeriksanya ke Kaspersky WebFilter. Jika situs terindikasi phishing atau penipuan, DeFort otomatis menutup halaman (perintah Kembali) dan menampilkan notifikasi darurat merah.',
      questionEn: 'How does automatic phishing link blocking work?',
      answerEn:
          'When DeFort Accessibility Service is active, it checks URLs opened in major browsers (Chrome, Firefox, Edge, Samsung Internet, Brave, etc.) against Kaspersky WebFilter. If a phishing site is detected, DeFort automatically navigates back to protect your credentials and triggers a red emergency alert.',
    ),
    _FaqItem(
      category: 'scan',
      questionId: 'Apa perbedaan Pindai Cepat dan Pindai Menyeluruh?',
      answerId:
          'Pindai Cepat (Quick Scan) memeriksa aplikasi terpasang dan area sistem utama dalam waktu singkat. Pindai Menyeluruh (Full Scan) memeriksa seluruh berkas penyimpanan internal, arsip terkompresi, dan aplikasi secara mendalam. Anda juga dapat memilih Pindai Folder untuk memeriksa direktori tertentu saja.',
      questionEn: 'What is the difference between Quick Scan and Full Scan?',
      answerEn:
          'Quick Scan inspects installed apps and critical system areas rapidly. Full Scan deeply scans all internal storage files, archives, and applications. You can also use Folder Scan to inspect a specific directory.',
    ),
    _FaqItem(
      category: 'quarantine',
      questionId: 'Apa itu Ruang Karantina dan apakah berkas bisa dipulihkan?',
      answerId:
          'Ruang Karantina adalah brankas isolasi aman tempat berkas berbahaya atau mencurigakan disimpan tanpa izin baca/eksekusi agar tidak dapat merusak perangkat. Jika Anda yakin sebuah berkas aman (false positive), Anda dapat memulihkannya kembali atau menghapusnya permanen melalui menu Pengaturan > Ruang Karantina.',
      questionEn: 'What is Quarantine and can files be restored?',
      answerEn:
          'Quarantine is a secure isolation vault where malicious or suspicious files are stored without read/execute permissions so they cannot harm your device. If a file is safe (false positive), you can restore it or permanently delete it via Settings > Quarantine.',
    ),
    _FaqItem(
      category: 'permissions',
      questionId: 'Mengapa DeFort meminta izin Akses Semua File dan Aksesibilitas?',
      answerId:
          'Izin Akses Semua File diperlukan oleh Android 11+ agar engine Kaspersky dapat memindai berkas unduhan, dokumen, dan APK di penyimpanan. Izin Aksesibilitas diperlukan khusus untuk membaca URL di peramban guna mencegah serangan phishing secara otomatis. DeFort tidak pernah mengumpulkan atau menjual data pribadi Anda.',
      questionEn: 'Why does DeFort request All Files Access and Accessibility permissions?',
      answerEn:
          'All Files Access is required on Android 11+ so the Kaspersky engine can scan downloads, documents, and APKs. Accessibility is used solely to inspect browser URLs and block phishing sites automatically. DeFort never collects or sells your personal data.',
    ),
    _FaqItem(
      category: 'scan',
      questionId: 'Mengapa pemindaian Wi-Fi membutuhkan izin Lokasi (GPS)?',
      answerId:
          'Sistem operasi Android mewajibkan izin Lokasi Akurat agar aplikasi keamanan diizinkan membaca nama jaringan Wi-Fi (SSID), alamat BSSID, dan jenis enkripsi router (WPA2/WPA3/Terbuka) saat melakukan audit keamanan jaringan.',
      questionEn: 'Why does Wi-Fi security scanning require Location (GPS) permission?',
      answerEn:
          'Android requires Fine Location permission to allow security apps to read the Wi-Fi network name (SSID), BSSID, and router encryption type (WPA2/WPA3/Open) during network security audits.',
    ),
    _FaqItem(
      category: 'protection',
      questionId: 'Apa yang harus dilakukan jika ditemukan aplikasi berbahaya?',
      answerId:
          'Jangan membuka aplikasi tersebut. Ketuk notifikasi peringatan DeFort atau buka hasil pemindaian, lalu tekan tombol "Hapus / Copot Pemasangan" untuk segera menghapus aplikasi berbahaya dari perangkat Anda.',
      questionEn: 'What should I do if a malicious app is detected?',
      answerEn:
          'Do not open the app. Tap the DeFort alert notification or open the scan result, then tap "Delete / Uninstall" to immediately remove the malicious app from your device.',
    ),
    _FaqItem(
      category: 'permissions',
      questionId: 'Mengapa perlindungan latar belakang kadang berhenti di beberapa HP?',
      answerId:
          'Beberapa produsen HP memiliki penghemat baterai agresif yang menutup layanan latar belakang. Pastikan Anda telah mengaktifkan opsi "Abaikan Optimasi Baterai" di halaman Pengaturan > Izin & Perlindungan Latar Belakang.',
      questionEn: 'Why might background protection stop on some phones?',
      answerEn:
          'Some phone manufacturers use aggressive battery savers that stop background services. Make sure you enable "Ignore Battery Optimization" under Settings > Permissions & Background Protection.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copySupportEmail(bool isEn) {
    Clipboard.setData(const ClipboardData(text: 'support@defort-security.id'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn
              ? 'Support email copied: support@defort-security.id'
              : 'Email dukungan disalin: support@defort-security.id',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLoc.lang(context) == 'en';
    final textColor = isDark ? Colors.white : Colors.black87;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final descController = TextEditingController();
    String issueType = isEn ? 'Bug / App Error' : 'Bug / Kendala Aplikasi';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final categories = isEn
                ? ['Bug / App Error', 'False Positive Detection', 'Phishing URL Report', 'Account & License']
                : ['Bug / Kendala Aplikasi', 'Deteksi Keliru (False Positive)', 'Laporkan Tautan Phishing', 'Akun & Lisensi'];

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(LucideIcons.messageSquarePlus, color: Colors.indigoAccent),
                        const SizedBox(width: 10),
                        Text(
                          isEn ? 'Submit Support Ticket' : 'Kirim Laporan Bantuan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEn ? 'Category' : 'Kategori Laporan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final selected = issueType == cat;
                        return ChoiceChip(
                          label: Text(cat, style: TextStyle(fontSize: 12, color: selected ? Colors.white : textColor)),
                          selected: selected,
                          selectedColor: Colors.indigo,
                          backgroundColor: textColor.withOpacity(0.08),
                          onSelected: (_) => setModalState(() => issueType = cat),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isEn
                            ? 'Describe your issue or suspicious link here...'
                            : 'Jelaskan kendala Anda atau tautan mencurigakan di sini...',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.45)),
                        filled: true,
                        fillColor: textColor.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: textColor.withOpacity(0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: textColor.withOpacity(0.15)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (descController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isEn ? 'Please enter a description first.' : 'Mohon isi deskripsi terlebih dahulu.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEn
                                    ? 'Report submitted ($issueType). Our security team will review it shortly.'
                                    : 'Laporan terkirim ($issueType). Tim keamanan DeFort akan segera meninjaunya.',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        icon: const Icon(LucideIcons.send, size: 18),
                        label: Text(
                          isEn ? 'Send Report' : 'Kirim Laporan',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEn = AppLoc.lang(context) == 'en';
    final bgColor = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final categories = [
      {'id': 'all', 'label': isEn ? 'All' : 'Semua'},
      {'id': 'protection', 'label': isEn ? 'Protection' : 'Perlindungan'},
      {'id': 'phishing', 'label': 'Anti-Phishing'},
      {'id': 'scan', 'label': isEn ? 'Scanning' : 'Pemindaian'},
      {'id': 'quarantine', 'label': isEn ? 'Quarantine' : 'Karantina'},
      {'id': 'permissions', 'label': isEn ? 'Permissions' : 'Perizinan'},
    ];

    final filteredFaqs = _faqs.where((item) {
      final matchesCat = _selectedCategory == 'all' || item.category == _selectedCategory;
      if (!matchesCat) return false;
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      final question = (isEn ? item.questionEn : item.questionId).toLowerCase();
      final answer = (isEn ? item.answerEn : item.answerId).toLowerCase();
      return question.contains(q) || answer.contains(q);
    }).toList();

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
          AppLoc.tr(context, 'Pusat Bantuan'),
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -30, left: -40, child: _buildBlob(const Color(0xFF38BDF8), 220)),
          Positioned(bottom: 40, right: -50, child: _buildBlob(const Color(0xFF818CF8), 240)),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              // Search Box
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.85) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: isEn ? 'Search help topics or FAQs...' : 'Cari topik bantuan atau FAQ...',
                    hintStyle: TextStyle(color: subTextColor.withOpacity(0.7)),
                    prefixIcon: Icon(LucideIcons.search, color: subTextColor, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: Icon(LucideIcons.x, color: subTextColor, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Category Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final selected = _selectedCategory == cat['id'];
                    return ChoiceChip(
                      label: Text(
                        cat['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : textColor,
                        ),
                      ),
                      selected: selected,
                      selectedColor: Colors.indigo,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      side: BorderSide(color: selected ? Colors.indigo : textColor.withOpacity(0.12)),
                      onSelected: (_) => setState(() => _selectedCategory = cat['id']!),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Quick Shortcuts
              Text(
                isEn ? 'Quick Actions' : 'Pintasan Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      isDark: isDark,
                      icon: LucideIcons.shieldCheck,
                      color: const Color(0xFF10B981),
                      title: isEn ? 'Setup Permissions' : 'Atur Izin 24/7',
                      subtitle: isEn ? 'Enable full shield' : 'Aktifkan proteksi penuh',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PermissionsScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildShortcutCard(
                      isDark: isDark,
                      icon: LucideIcons.packageCheck,
                      color: Colors.amber,
                      title: isEn ? 'Quarantine Vault' : 'Ruang Karantina',
                      subtitle: isEn ? 'Manage isolated files' : 'Kelola berkas aman',
                      textColor: textColor,
                      subTextColor: subTextColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QuarantineScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // FAQ Header
              Text(
                isEn ? 'Frequently Asked Questions (FAQ)' : 'Pertanyaan yang Sering Diajukan (FAQ)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),

              if (filteredFaqs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(LucideIcons.searchX, size: 36, color: subTextColor),
                      const SizedBox(height: 10),
                      Text(
                        isEn ? 'No matching help articles found.' : 'Tidak ada topik bantuan yang cocok.',
                        style: TextStyle(color: subTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...filteredFaqs.map((faq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withOpacity(0.75) : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        iconColor: Colors.indigoAccent,
                        collapsedIconColor: subTextColor,
                        title: Text(
                          isEn ? faq.questionEn : faq.questionId,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        children: [
                          Text(
                            isEn ? faq.answerEn : faq.answerId,
                            style: TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // Customer Support Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
                        : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.headset, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Need More Help?' : 'Butuh Bantuan Lebih Lanjut?',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEn ? 'DeFort Security Support Team 24/7' : 'Tim Dukungan Keamanan DeFort 24/7',
                                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _copySupportEmail(isEn),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.mail, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'support@defort-security.id',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            Icon(LucideIcons.copy, color: Colors.white.withOpacity(0.85), size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () => _showReportSheet(context),
                        icon: const Icon(LucideIcons.messageSquarePlus, size: 18),
                        label: Text(
                          isEn ? 'Report an Issue / Phishing' : 'Laporkan Masalah / Phishing',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF312E81),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard({
    required bool isDark,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B).withOpacity(0.75) : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: subTextColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.16), shape: BoxShape.circle),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
