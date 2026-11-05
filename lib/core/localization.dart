import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class AppLoc {
  static const Map<String, Map<String, String>> _localizedValues = {
    // Navigation Tabs
    'Beranda': {'en': 'Home', 'id': 'Beranda'},
    'Pindai': {'en': 'Scan', 'id': 'Pindai'},
    'Identitas': {'en': 'Identity', 'id': 'Identitas'},
    'Jaringan': {'en': 'Network', 'id': 'Jaringan'},
    'Menu': {'en': 'Menu', 'id': 'Menu'},
    
    // Dashboard
    'Perangkat Aman': {'en': 'Device Secure', 'id': 'Perangkat Aman'},
    'Sistem berjalan dengan sangat baik.': {'en': 'System is running smoothly.', 'id': 'Sistem berjalan dengan sangat baik.'},
    'Memindai...': {'en': 'Scanning...', 'id': 'Memindai...'},
    'Harap tunggu, SDK sedang bekerja.': {'en': 'Please wait, SDK is working.', 'id': 'Harap tunggu, SDK sedang bekerja.'},
    'Pemindaian Gagal': {'en': 'Scan Failed', 'id': 'Pemindaian Gagal'},
    'Ancaman Ditemukan!': {'en': 'Threats Found!', 'id': 'Ancaman Ditemukan!'},
    'malware dari': {'en': 'malware from', 'id': 'malware dari'},
    '100% Aman': {'en': '100% Safe', 'id': '100% Aman'},
    'file bersih dari ancaman.': {'en': 'files are clean.', 'id': 'file bersih dari ancaman.'},
    'Memproses...': {'en': 'Processing...', 'id': 'Memproses...'},
    'Pindai Sekarang': {'en': 'Scan Now', 'id': 'Pindai Sekarang'},
    'Ringkasan Keamanan': {'en': 'Security Summary', 'id': 'Ringkasan Keamanan'},
    
    'Anti-Malware': {'en': 'Anti-Malware', 'id': 'Anti-Malware'},
    'Aktif': {'en': 'Active', 'id': 'Aktif'},
    'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).': {
      'en': 'Real-Time scan is running in the background (Powered by Kaspersky).',
      'id': 'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).'
    },
    
    'Safe Browsing': {'en': 'Safe Browsing', 'id': 'Safe Browsing'},
    'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.': {
      'en': 'All malicious links (phishing) will be blocked automatically in real-time.',
      'id': 'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.'
    },
    
    'Izin Aplikasi': {'en': 'App Permissions', 'id': 'Izin Aplikasi'},
    'Aman': {'en': 'Safe', 'id': 'Aman'},
    'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.': {
      'en': 'No suspicious apps have access to your camera or microphone.',
      'id': 'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.'
    },
    
    'Koneksi': {'en': 'Connection', 'id': 'Koneksi'},
    'Terhubung ke jaringan terenkripsi yang aman (WPA3).': {
      'en': 'Connected to a secure encrypted network (WPA3).',
      'id': 'Terhubung ke jaringan terenkripsi yang aman (WPA3).'
    },
    'Mengerti': {'en': 'Got it', 'id': 'Mengerti'},
    
    // Scan Tab
    'Pindai Perangkat': {'en': 'Device Scan', 'id': 'Pindai Perangkat'},
    'Pilih metode pemindaian untuk menemukan ancaman.': {'en': 'Choose a scan method to find threats.', 'id': 'Pilih metode pemindaian untuk menemukan ancaman.'},
    'Pindai Cepat': {'en': 'Quick Scan', 'id': 'Pindai Cepat'},
    'Memeriksa aplikasi sistem utama (1-2 Menit)': {'en': 'Checking main system apps (1-2 Minutes)', 'id': 'Memeriksa aplikasi sistem utama (1-2 Menit)'},
    'Pindai Menyeluruh': {'en': 'Full Scan', 'id': 'Pindai Menyeluruh'},
    'Memeriksa seluruh memori internal perangkat (> 5 Menit)': {'en': 'Checking entire internal memory (> 5 Minutes)', 'id': 'Memeriksa seluruh memori internal perangkat (> 5 Menit)'},
    'Pindai Folder': {'en': 'Folder Scan', 'id': 'Pindai Folder'},
    'Pilih direktori spesifik untuk diperiksa': {'en': 'Select specific directory to scan', 'id': 'Pilih direktori spesifik untuk diperiksa'},
    'Tutup': {'en': 'Close', 'id': 'Tutup'},
    'Gagal': {'en': 'Failed', 'id': 'Gagal'},
    'Pindai Selesai': {'en': 'Scan Complete', 'id': 'Pindai Selesai'},
    'file diperiksa. Tidak ada ancaman.': {'en': 'files checked. No threats.', 'id': 'file diperiksa. Tidak ada ancaman.'},
    '34.502 file diperiksa. Perangkat Anda bersih!': {'en': '34,502 files checked. Your device is clean!', 'id': '34.502 file diperiksa. Perangkat Anda bersih!'},
    'Pindai Folder /Downloads': {'en': 'Scan Folder /Downloads', 'id': 'Pindai Folder /Downloads'},
    '152 file diperiksa. Aman.': {'en': '152 files checked. Safe.', 'id': '152 file diperiksa. Aman.'},
    'Ruang Karantina': {'en': 'Quarantine Vault', 'id': 'Ruang Karantina'},
    'Riwayat Pemindaian': {'en': 'Scan History', 'id': 'Riwayat Pemindaian'},
    
    // Identity Tab
    'Identitas & Privasi': {'en': 'Identity & Privacy', 'id': 'Identitas & Privasi'},
    'Lindungi diri dari Phishing dan Aplikasi Palsu.': {'en': 'Protect yourself from Phishing and Fake Apps.', 'id': 'Lindungi diri dari Phishing dan Aplikasi Palsu.'},
    'Periksa Tautan (Anti-Phishing)': {'en': 'Check Link (Anti-Phishing)', 'id': 'Periksa Tautan (Anti-Phishing)'},
    'Cek': {'en': 'Check', 'id': 'Cek'},
    'Tautan Aman': {'en': 'Safe Link', 'id': 'Tautan Aman'},
    'Bahaya Phishing!': {'en': 'Phishing Danger!', 'id': 'Bahaya Phishing!'},
    'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.': {'en': 'Kaspersky WebFilter states this URL is safe to visit.', 'id': 'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.'},
    'URL ini terdeteksi sebagai ancaman. Kategori:': {'en': 'This URL is detected as a threat. Categories:', 'id': 'URL ini terdeteksi sebagai ancaman. Kategori:'},
    'Perlindungan Real-time': {'en': 'Real-time Protection', 'id': 'Perlindungan Real-time'},
    'Web Filter / Anti-Phishing': {'en': 'Web Filter / Anti-Phishing', 'id': 'Web Filter / Anti-Phishing'},
    'Memblokir situs penipuan secara otomatis': {'en': 'Block scam sites automatically', 'id': 'Memblokir situs penipuan secara otomatis'},
    'Monitor Aplikasi Palsu': {'en': 'Fake App Monitor', 'id': 'Monitor Aplikasi Palsu'},
    'Memindai aplikasi yang baru diinstal': {'en': 'Scan newly installed apps', 'id': 'Memindai aplikasi yang baru diinstal'},
    'Pemantauan Aplikasi Palsu Diaktifkan': {'en': 'Fake App Monitor Enabled', 'id': 'Pemantauan Aplikasi Palsu Diaktifkan'},
    'Tautan Berbahaya!': {'en': 'Dangerous Link!', 'id': 'Tautan Berbahaya!'},
    'Tidak Dapat Dipastikan': {'en': 'Cannot Be Confirmed', 'id': 'Tidak Dapat Dipastikan'},
    'Alasan': {'en': 'Reasons', 'id': 'Alasan'},
    'Pemeriksaan Gagal': {'en': 'Check Failed', 'id': 'Pemeriksaan Gagal'},
    
    // Network Tab
    'Keamanan Jaringan': {'en': 'Network Security', 'id': 'Keamanan Jaringan'},
    'Pastikan koneksi Wi-Fi Anda aman dari sadapan.': {'en': 'Ensure your Wi-Fi is safe from eavesdropping.', 'id': 'Pastikan koneksi Wi-Fi Anda aman dari sadapan.'},
    'Wi-Fi Saat Ini': {'en': 'Current Wi-Fi', 'id': 'Wi-Fi Saat Ini'},
    'Menganalisis...': {'en': 'Analyzing...', 'id': 'Menganalisis...'},
    'Analisis Jaringan': {'en': 'Analyze Network', 'id': 'Analisis Jaringan'},
    'Hasil Analisis Kaspersky': {'en': 'Kaspersky Analysis Results', 'id': 'Hasil Analisis Kaspersky'},
    'Reputasi Wi-Fi': {'en': 'Wi-Fi Reputation', 'id': 'Reputasi Wi-Fi'},
    'Integritas DNS': {'en': 'DNS Integrity', 'id': 'Integritas DNS'},
    'Validasi Sertifikat SSL': {'en': 'SSL Certificate Validation', 'id': 'Validasi Sertifikat SSL'},
    'Belum Diperiksa': {'en': 'Not Checked Yet', 'id': 'Belum Diperiksa'},
    'Memeriksa...': {'en': 'Checking...', 'id': 'Memeriksa...'},
    'Aman (Enkripsi WPA)': {'en': 'Safe (WPA Encrypted)', 'id': 'Aman (Enkripsi WPA)'},
    'Berisiko / Terbuka': {'en': 'At Risk / Open', 'id': 'Berisiko / Terbuka'},
    'Aman (Tidak ada Spoofing)': {'en': 'Safe (No Spoofing)', 'id': 'Aman (Tidak ada Spoofing)'},
    'DNS Tidak Aman': {'en': 'Unsafe DNS', 'id': 'DNS Tidak Aman'},
    'Pemeriksaan URL': {'en': 'URL Checker', 'id': 'Pemeriksaan URL'},
    'Aman (Tidak ada Phishing)': {'en': 'Safe (No Phishing)', 'id': 'Aman (Tidak ada Phishing)'},
    'Berbahaya': {'en': 'Dangerous', 'id': 'Berbahaya'},
    'Sertifikat Valid': {'en': 'Valid Certificate', 'id': 'Sertifikat Valid'},
    'Sertifikat Invalid': {'en': 'Invalid Certificate', 'id': 'Sertifikat Invalid'},
    'Tidak Terhubung ke WiFi': {'en': 'Not Connected to WiFi', 'id': 'Tidak Terhubung ke WiFi'},
    'Kecepatan': {'en': 'Speed', 'id': 'Kecepatan'},
    'Frekuensi': {'en': 'Frequency', 'id': 'Frekuensi'},
    'Kekuatan Sinyal': {'en': 'Signal Strength', 'id': 'Kekuatan Sinyal'},
    'Terhubung ke': {'en': 'Connected to', 'id': 'Terhubung ke'},
    'sinyal': {'en': 'signal', 'id': 'sinyal'},
    'Tidak terhubung ke jaringan WiFi.': {'en': 'Not connected to WiFi network.', 'id': 'Tidak terhubung ke jaringan WiFi.'},
    'Terhubung melalui jaringan seluler.': {'en': 'Connected via cellular network.', 'id': 'Terhubung melalui jaringan seluler.'},
    'Tidak Terhubung': {'en': 'Not Connected', 'id': 'Tidak Terhubung'},
    
    // Menu Tab & Settings
    'Pengaturan': {'en': 'Settings', 'id': 'Pengaturan'},
    'Akun Saya': {'en': 'My Account', 'id': 'Akun Saya'},
    'Kelola profil & data Anda': {'en': 'Manage profile & data', 'id': 'Kelola profil & data Anda'},
    'Kelola berkas terisolasi & ancaman': {'en': 'Manage isolated threats & files', 'id': 'Kelola berkas terisolasi & ancaman'},
    'DeFort Premium': {'en': 'DeFort Premium', 'id': 'DeFort Premium'},
    'Status: Aktif': {'en': 'Status: Active', 'id': 'Status: Aktif'},
    'Tingkatkan untuk perlindungan ekstra': {'en': 'Upgrade for extra protection', 'id': 'Tingkatkan untuk perlindungan ekstra'},
    'Lisensi Kaspersky': {'en': 'Kaspersky License', 'id': 'Lisensi Kaspersky'},
    'Aktif hingga 2027': {'en': 'Active until 2027', 'id': 'Aktif hingga 2027'},
    'Preferensi': {'en': 'Preferences', 'id': 'Preferensi'},
    'Bahasa, Tema, Notifikasi': {'en': 'Language, Theme, Notifications', 'id': 'Bahasa, Tema, Notifikasi'},
    'Pusat Bantuan': {'en': 'Help Center', 'id': 'Pusat Bantuan'},
    'FAQ dan dukungan pelanggan': {'en': 'FAQ and customer support', 'id': 'FAQ dan dukungan pelanggan'},
    'Tentang DeFort': {'en': 'About DeFort', 'id': 'Tentang DeFort'},
    'Versi 1.0.0 (Powered by Kaspersky)': {'en': 'Version 1.0.0 (Powered by Kaspersky)', 'id': 'Versi 1.0.0 (Powered by Kaspersky)'},
    'Keluar dari Akun': {'en': 'Log Out', 'id': 'Keluar dari Akun'},
    'Akhiri sesi saat ini': {'en': 'End current session', 'id': 'Akhiri sesi saat ini'},
    
    // App Preferences Sheet
    'Preferensi Aplikasi': {'en': 'App Preferences', 'id': 'Preferensi Aplikasi'},
    'Mode Gelap': {'en': 'Dark Mode', 'id': 'Mode Gelap'},
    'Tampilan malam hari': {'en': 'Night mode appearance', 'id': 'Tampilan malam hari'},
    'Bahasa': {'en': 'Language', 'id': 'Bahasa'},
    'Pilih bahasa aplikasi': {'en': 'Choose app language', 'id': 'Pilih bahasa aplikasi'},
    'Keluar': {'en': 'Logout', 'id': 'Keluar'},
    'Batal': {'en': 'Cancel', 'id': 'Batal'},

    // Notification Settings
    'Pengaturan Notifikasi': {'en': 'Notification Settings', 'id': 'Pengaturan Notifikasi'},
    'Notifikasi Keamanan': {'en': 'Security Notifications', 'id': 'Notifikasi Keamanan'},
    'Izinkan DeFort mengirimkan pemberitahuan penting': {
      'en': 'Allow DeFort to deliver critical security alerts',
      'id': 'Izinkan DeFort mengirimkan pemberitahuan penting'
    },
    'Peringatan Ancaman Real-time': {'en': 'Real-time Threat Alerts', 'id': 'Peringatan Ancaman Real-time'},
    'Pemberitahuan saat mendeteksi file berbahaya atau malware': {
      'en': 'Instant alerts upon detecting dangerous files or malware',
      'id': 'Pemberitahuan saat mendeteksi file berbahaya atau malware'
    },
    'Peringatan Anti-Phishing': {'en': 'Anti-Phishing Warnings', 'id': 'Peringatan Anti-Phishing'},
    'Peringatan darurat saat membuka situs atau link penipuan': {
      'en': 'Emergency warning when visiting malicious or scam links',
      'id': 'Peringatan darurat saat membuka situs atau link penipuan'
    },
    'Laporan Pemindaian Selesai': {'en': 'Scan Complete Reports', 'id': 'Laporan Pemindaian Selesai'},
    'Notifikasi saat pemindaian latar belakang selesai': {
      'en': 'Notification when background scanning completes',
      'id': 'Notifikasi saat pemindaian latar belakang selesai'
    },

    // Permissions & Background Security
    'Perizinan Perangkat': {'en': 'Device Permissions', 'id': 'Perizinan Perangkat'},
    'Izin & Perlindungan Latar Belakang': {
      'en': 'Permissions & Background Protection',
      'id': 'Izin & Perlindungan Latar Belakang'
    },
    'Kelola izin agar perlindungan 24/7 tetap aktif': {
      'en': 'Manage permissions to keep 24/7 background protection active',
      'id': 'Kelola izin agar perlindungan 24/7 tetap aktif'
    },
    'Akses Semua File & Folder': {'en': 'All Files & Folders Access', 'id': 'Akses Semua File & Folder'},
    'Diperlukan untuk memindai berkas terunduh, arsip, dan ransomware di penyimpanan internal.': {
      'en': 'Required to scan downloads, archives, and ransomware payloads across storage.',
      'id': 'Diperlukan untuk memindai berkas terunduh, arsip, dan ransomware di penyimpanan internal.'
    },
    'Izin Notifikasi Sistem': {'en': 'System Notification Permission', 'id': 'Izin Notifikasi Sistem'},
    'Wajib agar DeFort dapat memperingatkan Anda saat ada bahaya di latar belakang.': {
      'en': 'Required so DeFort can warn you instantly about background threats.',
      'id': 'Wajib agar DeFort dapat memperingatkan Anda saat ada bahaya di latar belakang.'
    },
    'Abaikan Optimasi Baterai': {'en': 'Ignore Battery Optimization', 'id': 'Abaikan Optimasi Baterai'},
    'Mencegah sistem Android mematikan perlindungan DeFort saat aplikasi ditutup.': {
      'en': 'Prevents Android OS from stopping DeFort protection when app is closed.',
      'id': 'Mencegah sistem Android mematikan perlindungan DeFort saat aplikasi ditutup.'
    },
    'Perlindungan Anti-Phishing Real-time': {
      'en': 'Real-time Anti-Phishing Protection',
      'id': 'Perlindungan Anti-Phishing Real-time'
    },
    'Mencegah dan menyelamatkan Anda saat tidak sengaja membuka situs/link phishing dari browser atau pesan.': {
      'en': 'Prevents and rescues you when accidentally opening phishing links from browsers or messages.',
      'id': 'Mencegah dan menyelamatkan Anda saat tidak sengaja membuka situs/link phishing dari browser atau pesan.'
    },
    'Status Perlindungan': {'en': 'Protection Status', 'id': 'Status Perlindungan'},
    'Semua Izin Lengkap & Aktif': {'en': 'All Permissions Granted & Active', 'id': 'Semua Izin Lengkap & Aktif'},
    'Perlindungan Belum Maksimal': {'en': 'Protection Partially Enabled', 'id': 'Perlindungan Belum Maksimal'},
    'Berikan Izin': {'en': 'Grant Permission', 'id': 'Berikan Izin'},
    'Diizinkan': {'en': 'Granted', 'id': 'Diizinkan'},
    'Belum Aktif': {'en': 'Not Active', 'id': 'Belum Aktif'},
    'Uji Deteksi Phishing': {'en': 'Test Phishing Detection', 'id': 'Uji Deteksi Phishing'},
    'Simulasi Tautan Phishing': {'en': 'Simulate Phishing Link', 'id': 'Simulasi Tautan Phishing'},
    'Tautan Phishing Berhasil Dicegah!': {
      'en': 'Phishing Link Successfully Intercepted!',
      'id': 'Tautan Phishing Berhasil Dicegah!'
    },
    'DeFort berhasil memblokir akses ke situs berbahaya dan menyelamatkan kredensial Anda.': {
      'en': 'DeFort blocked access to the malicious website and safeguarded your credentials.',
      'id': 'DeFort berhasil memblokir akses ke situs berbahaya dan menyelamatkan kredensial Anda.'
    },

    // Auth Screens
    'Selamat Datang Kembali': {'en': 'Welcome Back', 'id': 'Selamat Datang Kembali'},
    'Masuk untuk mengelola keamanan perangkat Anda.': {'en': 'Sign in to manage your device security.', 'id': 'Masuk untuk mengelola keamanan perangkat Anda.'},
    'Kata Sandi': {'en': 'Password', 'id': 'Kata Sandi'},
    'Lupa Kata Sandi?': {'en': 'Forgot Password?', 'id': 'Lupa Kata Sandi?'},
    'Masuk': {'en': 'Sign In', 'id': 'Masuk'},
    'Belum punya akun? ': {'en': 'Don\'t have an account? ', 'id': 'Belum punya akun? '},
    'Daftar Sekarang': {'en': 'Register Now', 'id': 'Daftar Sekarang'},
    'Buat Akun Baru': {'en': 'Create New Account', 'id': 'Buat Akun Baru'},
    'Daftar sekarang untuk perlindungan penuh.': {'en': 'Register now for full protection.', 'id': 'Daftar sekarang untuk perlindungan penuh.'},
    'Daftar': {'en': 'Register', 'id': 'Daftar'},
  };

  static String tr(BuildContext context, String key, {bool listen = true}) {
    String language;
    try {
      language = Provider.of<AppState>(context, listen: listen).language;
    } catch (_) {
      language = 'id';
    }
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]![language] ?? key;
    }
    return key;
  }

  /// Kode bahasa aktif ('id' atau 'en').
  static String lang(BuildContext context) {
    try {
      return Provider.of<AppState>(context, listen: false).language;
    } catch (_) {
      return 'id';
    }
  }
}
