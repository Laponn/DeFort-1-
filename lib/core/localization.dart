import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';

class AppLoc {
  static const Map<String, Map<String, String>> _localizedValues = {
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
    'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).': {'en': 'Real-Time scan is running in the background (Powered by Kaspersky).', 'id': 'Pemindaian Real-Time sedang berjalan di latar belakang (Didukung oleh Kaspersky).'},
    
    'Safe Browsing': {'en': 'Safe Browsing', 'id': 'Safe Browsing'},
    'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.': {'en': 'All malicious links (phishing) will be blocked automatically in real-time.', 'id': 'Semua tautan berbahaya (phishing) akan diblokir otomatis secara real-time.'},
    
    'Izin Aplikasi': {'en': 'App Permissions', 'id': 'Izin Aplikasi'},
    'Aman': {'en': 'Safe', 'id': 'Aman'},
    'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.': {'en': 'No suspicious apps have access to your camera or microphone.', 'id': 'Tidak ada aplikasi mencurigakan yang memiliki akses ke kamera atau mikrofon Anda.'},
    
    'Koneksi': {'en': 'Connection', 'id': 'Koneksi'},
    'Terhubung ke jaringan terenkripsi yang aman (WPA3).': {'en': 'Connected to a secure encrypted network (WPA3).', 'id': 'Terhubung ke jaringan terenkripsi yang aman (WPA3).'},
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
    
    // Identity Tab
    'Identitas & Privasi': {'en': 'Identity & Privacy', 'id': 'Identitas & Privasi'},
    'Lindungi diri dari Phishing dan Aplikasi Palsu.': {'en': 'Protect yourself from Phishing and Fake Apps.', 'id': 'Lindungi diri dari Phishing dan Aplikasi Palsu.'},
    'Periksa Tautan (Anti-Phishing)': {'en': 'Check Link (Anti-Phishing)', 'id': 'Periksa Tautan (Anti-Phishing)'},
    'Cek': {'en': 'Check', 'id': 'Cek'},
    'Tautan Aman': {'en': 'Link Safe', 'id': 'Tautan Aman'},
    'Bahaya Phishing!': {'en': 'Phishing Danger!', 'id': 'Bahaya Phishing!'},
    'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.': {'en': 'Kaspersky WebFilter states this URL is safe to visit.', 'id': 'Kaspersky WebFilter menyatakan URL ini aman untuk dikunjungi.'},
    'URL ini terdeteksi sebagai ancaman. Kategori:': {'en': 'This URL is detected as a threat. Categories:', 'id': 'URL ini terdeteksi sebagai ancaman. Kategori:'},
    'Perlindungan Real-time': {'en': 'Real-time Protection', 'id': 'Perlindungan Real-time'},
    'Web Filter / Anti-Phishing': {'en': 'Web Filter / Anti-Phishing', 'id': 'Web Filter / Anti-Phishing'},
    'Memblokir situs penipuan secara otomatis': {'en': 'Block scam sites automatically', 'id': 'Memblokir situs penipuan secara otomatis'},
    'Monitor Aplikasi Palsu': {'en': 'Fake App Monitor', 'id': 'Monitor Aplikasi Palsu'},
    'Memindai aplikasi yang baru diinstal': {'en': 'Scan newly installed apps', 'id': 'Memindai aplikasi yang baru diinstal'},
    'Pemantauan Aplikasi Palsu Diaktifkan': {'en': 'Fake App Monitor Enabled', 'id': 'Pemantauan Aplikasi Palsu Diaktifkan'},
    
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
    
    // Menu Tab
    'Pengaturan': {'en': 'Settings', 'id': 'Pengaturan'},
    'Akun Saya': {'en': 'My Account', 'id': 'Akun Saya'},
    'Kelola profil & data Anda': {'en': 'Manage profile & data', 'id': 'Kelola profil & data Anda'},
    
    // Premium
    'DeFort Premium': {'en': 'DeFort Premium', 'id': 'DeFort Premium'},
    'Status: Aktif': {'en': 'Status: Active', 'id': 'Status: Aktif'},
    'Tingkatkan untuk perlindungan ekstra': {'en': 'Upgrade for extra protection', 'id': 'Tingkatkan untuk perlindungan ekstra'},
    'Anda saat ini berlangganan Premium. Semua fitur perlindungan tingkat lanjut telah aktif.': {'en': 'You are currently subscribed to Premium. All advanced protection features are active.', 'id': 'Anda saat ini berlangganan Premium. Semua fitur perlindungan tingkat lanjut telah aktif.'},
    'Tingkatkan ke Premium untuk membuka semua fitur perlindungan Kaspersky, termasuk VPN tanpa batas dan WebFilter real-time.': {'en': 'Upgrade to Premium to unlock all Kaspersky protection features, including unlimited VPN and real-time WebFilter.', 'id': 'Tingkatkan ke Premium untuk membuka semua fitur perlindungan Kaspersky, termasuk VPN tanpa batas dan WebFilter real-time.'},
    'VPN Cepat Tanpa Batas': {'en': 'Fast Unlimited VPN', 'id': 'VPN Cepat Tanpa Batas'},
    'Anti-Phishing Tingkat Lanjut': {'en': 'Advanced Anti-Phishing', 'id': 'Anti-Phishing Tingkat Lanjut'},
    'Pembaruan Basis Data Prioritas': {'en': 'Priority Database Updates', 'id': 'Pembaruan Basis Data Prioritas'},
    'Premium berhasil diaktifkan!': {'en': 'Premium activated successfully!', 'id': 'Premium berhasil diaktifkan!'},
    'Langganan Premium dibatalkan.': {'en': 'Premium subscription cancelled.', 'id': 'Langganan Premium dibatalkan.'},
    'Batalkan Premium': {'en': 'Cancel Premium', 'id': 'Batalkan Premium'},
    'Beli Premium - \$9.99/bulan': {'en': 'Buy Premium - \$9.99/month', 'id': 'Beli Premium - Rp149.000/bulan'},
    
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
    
    // Account & Edit Profile
    'Terverifikasi': {'en': 'Verified', 'id': 'Terverifikasi'},
    'Data Pribadi': {'en': 'Personal Data', 'id': 'Data Pribadi'},
    'Nama Lengkap': {'en': 'Full Name', 'id': 'Nama Lengkap'},
    'Alamat Email': {'en': 'Email Address', 'id': 'Alamat Email'},
    'Nomor Telepon': {'en': 'Phone Number', 'id': 'Nomor Telepon'},
    'Keamanan Akun': {'en': 'Account Security', 'id': 'Keamanan Akun'},
    'Ubah Kata Sandi': {'en': 'Change Password', 'id': 'Ubah Kata Sandi'},
    'Kata Sandi Saat Ini': {'en': 'Current Password', 'id': 'Kata Sandi Saat Ini'},
    'Kata Sandi Baru': {'en': 'New Password', 'id': 'Kata Sandi Baru'},
    'Konfirmasi Kata Sandi Baru': {'en': 'Confirm New Password', 'id': 'Konfirmasi Kata Sandi Baru'},
    'Kata sandi berhasil diperbarui!': {'en': 'Password successfully updated!', 'id': 'Kata sandi berhasil diperbarui!'},
    'Simpan Kata Sandi': {'en': 'Save Password', 'id': 'Simpan Kata Sandi'},
    'Autentikasi Dua Faktor (2FA)': {'en': 'Two-Factor Authentication (2FA)', 'id': 'Autentikasi Dua Faktor (2FA)'},
    'Amankan akun Anda dengan mewajibkan verifikasi tambahan saat masuk dari perangkat baru.': {'en': 'Secure your account by requiring additional verification when signing in from a new device.', 'id': 'Amankan akun Anda dengan mewajibkan verifikasi tambahan saat masuk dari perangkat baru.'},
    'Gunakan Aplikasi Authenticator': {'en': 'Use Authenticator App', 'id': 'Gunakan Aplikasi Authenticator'},
    '2FA berhasil diaktifkan!': {'en': '2FA successfully enabled!', 'id': '2FA berhasil diaktifkan!'},
    'Nonaktif': {'en': 'Inactive', 'id': 'Nonaktif'},
    'Simpan Perubahan': {'en': 'Save Changes', 'id': 'Simpan Perubahan'},
    'Edit Profil': {'en': 'Edit Profile', 'id': 'Edit Profil'},
    'Profil Berhasil Diperbarui!': {'en': 'Profile Updated Successfully!', 'id': 'Profil Berhasil Diperbarui!'},
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
    'Masukkan alamat email Anda untuk menerima tautan pemulihan kata sandi.': {'en': 'Enter your email address to receive a password recovery link.', 'id': 'Masukkan alamat email Anda untuk menerima tautan pemulihan kata sandi.'},
    'Kirim Tautan': {'en': 'Send Link', 'id': 'Kirim Tautan'},
    'Tautan pemulihan telah dikirim!': {'en': 'Recovery link has been sent!', 'id': 'Tautan pemulihan telah dikirim!'},
    
    'Preferensi Aplikasi': {'en': 'App Preferences', 'id': 'Preferensi Aplikasi'},
    'Mode Gelap': {'en': 'Dark Mode', 'id': 'Mode Gelap'},
    'Tampilan malam hari': {'en': 'Night mode appearance', 'id': 'Tampilan malam hari'},
    'Bahasa': {'en': 'Language', 'id': 'Bahasa'},
    'Pilih bahasa aplikasi': {'en': 'Choose app language', 'id': 'Pilih bahasa aplikasi'},
    'Keluar': {'en': 'Logout', 'id': 'Keluar'},
    'Apakah Anda yakin ingin keluar dari akun DeFort?': {'en': 'Are you sure you want to log out of DeFort?', 'id': 'Apakah Anda yakin ingin keluar dari akun DeFort?'},
    'Batal': {'en': 'Cancel', 'id': 'Batal'},
    'Anda telah membuka menu ': {'en': 'You opened the menu ', 'id': 'Anda telah membuka menu '},
    '. Halaman ini masih dalam tahap purwarupa.': {'en': '. This page is still a prototype.', 'id': '. Halaman ini masih dalam tahap purwarupa.'},
    
    // Notifications & Extra Pages
    'Notifikasi': {'en': 'Notifications', 'id': 'Notifikasi'},
    'Terima peringatan ancaman instan': {'en': 'Receive instant threat alerts', 'id': 'Terima peringatan ancaman instan'},
    'Status': {'en': 'Status', 'id': 'Status'},
    'Aktif Terverifikasi': {'en': 'Active & Verified', 'id': 'Aktif Terverifikasi'},
    'Kode Lisensi': {'en': 'License Code', 'id': 'Kode Lisensi'},
    'Masa Berlaku': {'en': 'Valid Until', 'id': 'Masa Berlaku'},
    'Lisensi ini mengaktifkan mesin Antivirus, perlindungan Anti-Phishing real-time, dan pemeriksaan keamanan jaringan melalui Kaspersky Security Network (KSN).': {'en': 'This license enables the Antivirus engine, real-time Anti-Phishing protection, and network security checks via Kaspersky Security Network (KSN).', 'id': 'Lisensi ini mengaktifkan mesin Antivirus, perlindungan Anti-Phishing real-time, dan pemeriksaan keamanan jaringan melalui Kaspersky Security Network (KSN).'},
    'Pusat Bantuan (FAQ)': {'en': 'Help Center (FAQ)', 'id': 'Pusat Bantuan (FAQ)'},
    'Apa itu DeFort Security?': {'en': 'What is DeFort Security?', 'id': 'Apa itu DeFort Security?'},
    'DeFort adalah aplikasi keamanan seluler yang didukung oleh Kaspersky SDK untuk melindungi perangkat Anda dari malware, phishing, dan ancaman jaringan.': {'en': 'DeFort is a mobile security app powered by Kaspersky SDK to protect your device from malware, phishing, and network threats.', 'id': 'DeFort adalah aplikasi keamanan seluler yang didukung oleh Kaspersky SDK untuk melindungi perangkat Anda dari malware, phishing, dan ancaman jaringan.'},
    'Bagaimana cara memindai virus?': {'en': 'How do I scan for viruses?', 'id': 'Bagaimana cara memindai virus?'},
    'Buka tab "Pindai" di menu bawah, lalu pilih Pindai Cepat, Pindai Penuh, atau Pindai Folder. Pemindaian akan berjalan secara lokal di perangkat Anda.': {'en': 'Open the "Scan" tab in the bottom menu, then choose Quick Scan, Full Scan, or Folder Scan. Scans will run locally on your device.', 'id': 'Buka tab "Pindai" di menu bawah, lalu pilih Pindai Cepat, Pindai Penuh, atau Pindai Folder. Pemindaian akan berjalan secara lokal di perangkat Anda.'},
    'Apakah data saya aman?': {'en': 'Is my data safe?', 'id': 'Apakah data saya aman?'},
    'Ya, DeFort Security tidak membagikan data pribadi Anda. Pengecekan URL dan jaringan dilakukan secara anonim melalui Kaspersky Security Network (KSN).': {'en': 'Yes, DeFort Security does not share your personal data. URL and network checks are done anonymously via Kaspersky Security Network (KSN).', 'id': 'Ya, DeFort Security tidak membagikan data pribadi Anda. Pengecekan URL dan jaringan dilakukan secara anonim melalui Kaspersky Security Network (KSN).'},
    'Apa keuntungan DeFort Premium?': {'en': 'What are the benefits of DeFort Premium?', 'id': 'Apa keuntungan DeFort Premium?'},
    'Premium membuka fitur lanjutan seperti VPN tanpa batas, perlindungan anti-phishing real-time, dan prioritas pembaruan database virus.': {'en': 'Premium unlocks advanced features such as unlimited VPN, real-time anti-phishing protection, and priority virus database updates.', 'id': 'Premium membuka fitur lanjutan seperti VPN tanpa batas, perlindungan anti-phishing real-time, dan prioritas pembaruan database virus.'},
    'Bagaimana cara mengubah kata sandi?': {'en': 'How do I change my password?', 'id': 'Bagaimana cara mengubah kata sandi?'},
    'Buka "Akun Saya" di menu Pengaturan, lalu pilih "Ubah Kata Sandi". Anda juga dapat mengaktifkan Autentikasi 2-Faktor di sana.': {'en': 'Open "My Account" in the Settings menu, then select "Change Password". You can also enable Two-Factor Authentication there.', 'id': 'Buka "Akun Saya" di menu Pengaturan, lalu pilih "Ubah Kata Sandi". Anda juga dapat mengaktifkan Autentikasi 2-Faktor di sana.'},
    'DeFort Security adalah aplikasi perlindungan perangkat komprehensif yang dirancang untuk memberikan keamanan maksimal terhadap malware, phishing, dan ancaman cyber lainnya.': {'en': 'DeFort Security is a comprehensive device protection app designed to provide maximum security against malware, phishing, and other cyber threats.', 'id': 'DeFort Security adalah aplikasi perlindungan perangkat komprehensif yang dirancang untuk memberikan keamanan maksimal terhadap malware, phishing, dan ancaman cyber lainnya.'},
  };

  static String tr(BuildContext context, String key) {
    // Avoid using watch() directly so we can call tr() in callbacks (like SnackBars)
    final language = Provider.of<AppState>(context, listen: false).language;
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]![language] ?? key;
    }
    return key;
  }
}
