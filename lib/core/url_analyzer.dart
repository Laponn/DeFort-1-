/// Analisis hasil pengecekan URL.
///
/// Menggabungkan dua sumber:
/// 1. Verdict & kategori dari Kaspersky SDK (sumber utama penentu status).
/// 2. Pemeriksaan heuristik lokal pada struktur URL (sebagai alasan/catatan tambahan).
///
/// Hasilnya berupa [UrlCheckResult] yang berisi status akhir dan daftar alasan
/// yang mudah dipahami pengguna.
library;

/// Status akhir sebuah URL.
enum UrlSafety { safe, dangerous, unknown }

/// Tingkat keparahan setiap alasan (menentukan ikon & warna di UI).
enum ReasonLevel { ok, info, warning, danger }

/// Satu baris alasan, tersedia dalam Bahasa Indonesia dan Inggris.
class UrlReason {
  final ReasonLevel level;
  final String id;
  final String en;

  const UrlReason(this.level, this.id, this.en);

  String text(String lang) => lang == 'en' ? en : id;
}

/// Hasil akhir analisis sebuah URL.
class UrlCheckResult {
  final String url;
  final String host;
  final UrlSafety safety;
  final String verdict;
  final List<String> categories;
  final List<UrlReason> reasons;

  const UrlCheckResult({
    required this.url,
    required this.host,
    required this.safety,
    required this.verdict,
    required this.categories,
    required this.reasons,
  });

  bool get hasWarnings => reasons.any((r) => r.level == ReasonLevel.warning);

  /// Kalimat kesimpulan singkat yang ditampilkan di atas daftar alasan.
  String summary(String lang) {
    final en = lang == 'en';
    switch (safety) {
      case UrlSafety.dangerous:
        return en
            ? 'Do NOT open this link. It was identified as a threat.'
            : 'JANGAN buka tautan ini. Tautan teridentifikasi sebagai ancaman.';
      case UrlSafety.safe:
        if (hasWarnings) {
          return en
              ? 'Safe according to Kaspersky, but please note the warnings below.'
              : 'Aman menurut Kaspersky, namun perhatikan catatan di bawah.';
        }
        return en ? 'This link is safe to visit.' : 'Tautan ini aman untuk dikunjungi.';
      case UrlSafety.unknown:
        return en
            ? 'Be careful. The safety of this link cannot be confirmed.'
            : 'Berhati-hatilah. Keamanan tautan ini belum dapat dipastikan.';
    }
  }
}

class UrlAnalyzer {
  UrlAnalyzer._();

  // ---------------------------------------------------------------------------
  // 1. NORMALISASI & VALIDASI INPUT
  // ---------------------------------------------------------------------------

  static final RegExp _schemeRegex = RegExp(r'^https?://', caseSensitive: false);
  static final RegExp _ipv4Regex = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$');

  /// Merapikan input pengguna menjadi URL lengkap.
  ///
  /// Mengembalikan `null` jika input bukan URL yang valid.
  /// Contoh: `"  Google.com "` -> `"https://google.com"`.
  static String? normalize(String input) {
    var url = input.trim();
    if (url.isEmpty || url.contains(RegExp(r'\s'))) return null;

    if (!_schemeRegex.hasMatch(url)) {
      // Skema lain (ftp://, javascript:, dll.) tidak didukung.
      if (url.contains('://')) return null;
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;

    final host = uri.host.toLowerCase();
    final isIp = _ipv4Regex.hasMatch(host);
    if (!isIp && !host.contains('.')) return null; // contoh: "localhost", "abc"

    return uri.replace(host: host).toString();
  }

  /// `true` jika pengguna menulis skema (http/https) sendiri.
  static bool hasExplicitScheme(String input) => _schemeRegex.hasMatch(input.trim());

  // ---------------------------------------------------------------------------
  // 2. KAMUS KATEGORI KASPERSKY
  // Nama kunci = nama enum UrlCategory / UrlCategoryExt dari Kaspersky SDK.
  // ---------------------------------------------------------------------------

  /// Kategori yang berarti URL BERBAHAYA.
  static const Map<String, List<String>> _threatCategories = {
    'Phishing': [
      'Phishing: halaman palsu yang meniru situs resmi untuk mencuri data login, OTP, atau kartu kredit.',
      'Phishing: a fake page imitating an official site to steal logins, OTPs, or card data.',
    ],
    'Malware': [
      'Malware: situs ini menyebarkan program jahat (virus, trojan, spyware).',
      'Malware: this site distributes malicious software (virus, trojan, spyware).',
    ],
    'CryptoFraud': [
      'Penipuan kripto: investasi atau giveaway mata uang kripto palsu.',
      'Crypto fraud: fake cryptocurrency investment or giveaway.',
    ],
    'Counterfeit': [
      'Penipuan toko online / barang palsu.',
      'Counterfeit goods / fraudulent online shop.',
    ],
    'SpamSites': [
      'Situs yang disebarkan melalui pesan spam massal.',
      'Site promoted through mass spam messages.',
    ],
    'UFOMaliciousIP': [
      'Alamat IP server situs ini tercatat berbahaya.',
      'The server IP address of this site is known to be malicious.',
    ],
    'UFOAdware': [
      'Adware: memunculkan iklan paksa atau mengunduh aplikasi yang tidak diinginkan.',
      'Adware: forces ads or downloads unwanted applications.',
    ],
    'RATNode': [
      'Server kendali jarak jauh (RAT) yang digunakan peretas.',
      'Remote Access Trojan (RAT) command server used by attackers.',
    ],
    'AptDomain': [
      'Domain terkait serangan siber tertarget (APT).',
      'Domain linked to targeted cyber attacks (APT).',
    ],
    'FOHasAVDetect': [
      'File pada situs ini terdeteksi oleh antivirus Kaspersky.',
      'Files on this site are detected by Kaspersky antivirus.',
    ],
    'KPSNBlackList': [
      'Masuk daftar hitam Kaspersky Security Network.',
      'Listed in the Kaspersky Security Network blacklist.',
    ],
  };

  /// Kategori yang BERISIKO (bukan ancaman langsung, tapi perlu diwaspadai).
  static const Map<String, List<String>> _riskyCategories = {
    'DomainMayContainPhishingPaths': [
      'Domain ini diketahui pernah memuat halaman phishing di sebagian alamatnya.',
      'This domain is known to host phishing pages on some of its paths.',
    ],
    'DomainMayContainMalwarePaths': [
      'Domain ini diketahui pernah memuat file malware di sebagian alamatnya.',
      'This domain is known to host malware on some of its paths.',
    ],
    'Anonymizers': [
      'Layanan anonymizer/proxy yang dapat menyembunyikan tujuan sebenarnya.',
      'Anonymizer/proxy service that may hide the real destination.',
    ],
    'Tor': ['Terkait jaringan Tor.', 'Related to the Tor network.'],
    'DynDNS': [
      'Memakai DNS dinamis, sering dipakai situs sementara atau penipuan.',
      'Uses dynamic DNS, often used by temporary or scam sites.',
    ],
    'IllegalSoft': [
      'Software bajakan/ilegal, rawan disisipi malware.',
      'Pirated/illegal software, often bundled with malware.',
    ],
    'IllegalSoftware': [
      'Software bajakan/ilegal, rawan disisipi malware.',
      'Pirated/illegal software, often bundled with malware.',
    ],
    'Torrents': [
      'Situs torrent, file unduhan rawan disisipi malware.',
      'Torrent site, downloads are often bundled with malware.',
    ],
    'Gambling': ['Situs perjudian online.', 'Online gambling site.'],
    'Gambling2': ['Situs perjudian online.', 'Online gambling site.'],
    'GamblingLotteriesSweepstakes': ['Situs perjudian / undian online.', 'Online gambling / lottery site.'],
    'CasinoCardGames': ['Situs kasino online.', 'Online casino site.'],
    'Betting': ['Situs taruhan online.', 'Online betting site.'],
    'AdultContent': [
      'Konten dewasa, sering memuat iklan berbahaya.',
      'Adult content, often contains malicious ads.',
    ],
    'PornoAndErotic': [
      'Konten dewasa, sering memuat iklan berbahaya.',
      'Adult content, often contains malicious ads.',
    ],
  };

  /// Layanan pemendek URL: tujuan asli tersembunyi.
  static const Set<String> _shorteners = {
    'bit.ly', 'tinyurl.com', 's.id', 't.co', 'goo.gl', 'cutt.ly', 'is.gd',
    'ow.ly', 'rebrand.ly', 'shorturl.at', 'rb.gy', 'tiny.cc', 'v.gd',
  };

  /// Ekstensi domain yang sering disalahgunakan untuk situs penipuan.
  static const Set<String> _suspiciousTlds = {
    'tk', 'ml', 'ga', 'cf', 'gq', 'xyz', 'top', 'zip', 'mov', 'click', 'work', 'rest', 'cam',
  };

  // ---------------------------------------------------------------------------
  // 3. ANALISIS UTAMA
  // ---------------------------------------------------------------------------

  /// Menggabungkan hasil dari Kaspersky ([native]) dengan pemeriksaan lokal.
  ///
  /// [input] = teks asli yang diketik pengguna,
  /// [url]   = hasil [normalize] yang dikirim ke Kaspersky.
  static UrlCheckResult analyze({
    required String input,
    required String url,
    required Map<String, dynamic> native,
  }) {
    final uri = Uri.parse(url);
    final verdict = (native['verdict'] as String?) ?? 'UNKNOWN';
    final categories = List<String>.from(native['categories'] ?? const []);

    final threatHits = categories.where(_threatCategories.containsKey).toList();
    final riskyHits = categories.where(_riskyCategories.containsKey).toList();
    final otherCats = categories
        .where((c) => !_threatCategories.containsKey(c) && !_riskyCategories.containsKey(c))
        .toList();

    // Status akhir ditentukan oleh Kaspersky (verdict + kategori ancaman).
    final UrlSafety safety;
    if (verdict == 'BAD' || threatHits.isNotEmpty) {
      safety = UrlSafety.dangerous;
    } else if (verdict == 'GOOD') {
      safety = UrlSafety.safe;
    } else {
      safety = UrlSafety.unknown;
    }

    final reasons = <UrlReason>[];

    // a) Alasan utama dari Kaspersky
    switch (verdict) {
      case 'BAD':
        reasons.add(const UrlReason(
          ReasonLevel.danger,
          'Kaspersky Security Network menandai URL ini sebagai BERBAHAYA.',
          'Kaspersky Security Network flagged this URL as DANGEROUS.',
        ));
        break;
      case 'GOOD':
        reasons.add(const UrlReason(
          ReasonLevel.ok,
          'Reputasi URL baik menurut Kaspersky Security Network (tidak ada catatan phishing atau malware).',
          'Kaspersky Security Network reports a good reputation (no phishing or malware records).',
        ));
        break;
      default:
        reasons.add(const UrlReason(
          ReasonLevel.info,
          'Kaspersky belum memiliki data reputasi untuk URL ini (kemungkinan situs baru atau jarang dikunjungi).',
          'Kaspersky has no reputation data for this URL yet (possibly a new or rarely visited site).',
        ));
    }

    // b) Kategori ancaman & berisiko
    for (final c in threatHits) {
      final d = _threatCategories[c]!;
      reasons.add(UrlReason(ReasonLevel.danger, d[0], d[1]));
    }
    for (final c in riskyHits) {
      final d = _riskyCategories[c]!;
      reasons.add(UrlReason(ReasonLevel.warning, d[0], d[1]));
    }

    // c) Kategori umum (informasi saja)
    if (otherCats.isNotEmpty) {
      final names = otherCats.map(_prettify).join(', ');
      reasons.add(UrlReason(
        ReasonLevel.info,
        'Kategori situs menurut Kaspersky: $names.',
        'Site category according to Kaspersky: $names.',
      ));
    }

    // d) Pemeriksaan struktur URL secara lokal
    reasons.addAll(_heuristics(uri, explicitScheme: hasExplicitScheme(input)));

    return UrlCheckResult(
      url: url,
      host: uri.host,
      safety: safety,
      verdict: verdict,
      categories: categories,
      reasons: reasons,
    );
  }

  // ---------------------------------------------------------------------------
  // 4. HEURISTIK LOKAL (ciri-ciri umum URL phishing)
  // ---------------------------------------------------------------------------

  static List<UrlReason> _heuristics(Uri uri, {required bool explicitScheme}) {
    final r = <UrlReason>[];
    final host = uri.host.toLowerCase();
    final labels = host.split('.');
    final tld = labels.last;

    // Protokol (hanya dinilai jika pengguna menulisnya sendiri)
    if (explicitScheme) {
      if (uri.scheme == 'http') {
        r.add(const UrlReason(
          ReasonLevel.warning,
          'Koneksi tidak terenkripsi (HTTP). Data yang Anda kirim bisa disadap.',
          'Unencrypted connection (HTTP). Data you send can be intercepted.',
        ));
      } else {
        r.add(const UrlReason(
          ReasonLevel.ok,
          'Menggunakan koneksi terenkripsi (HTTPS).',
          'Uses an encrypted connection (HTTPS).',
        ));
      }
    }

    // Host berupa alamat IP
    if (_ipv4Regex.hasMatch(host)) {
      r.add(const UrlReason(
        ReasonLevel.warning,
        'Alamat berupa angka IP, bukan nama domain. Situs resmi hampir selalu memakai nama domain.',
        'The address is a raw IP, not a domain name. Official sites almost always use a domain name.',
      ));
    }

    // Punycode (serangan homograf, mis. "аpple.com" dengan huruf Kiril)
    if (labels.any((l) => l.startsWith('xn--'))) {
      r.add(const UrlReason(
        ReasonLevel.warning,
        'Domain memakai karakter internasional (punycode) yang bisa meniru tampilan domain asli.',
        'The domain uses international characters (punycode) that can imitate a real domain.',
      ));
    }

    // Simbol '@' untuk menyamarkan domain asli
    if (uri.userInfo.isNotEmpty) {
      r.add(const UrlReason(
        ReasonLevel.warning,
        "URL mengandung simbol '@'. Teks sebelum '@' diabaikan browser dan sering dipakai untuk menyamarkan domain asli.",
        "The URL contains '@'. Text before '@' is ignored by browsers and often used to disguise the real domain.",
      ));
    }

    // Pemendek URL
    if (_shorteners.contains(host)) {
      r.add(UrlReason(
        ReasonLevel.warning,
        'Tautan memakai layanan pemendek URL ($host). Tujuan aslinya tersembunyi, jadi yang dinilai hanya domain pemendeknya.',
        'The link uses a URL shortener ($host). The real destination is hidden; only the shortener domain was assessed.',
      ));
    }

    // Ekstensi domain yang sering disalahgunakan
    if (!_ipv4Regex.hasMatch(host) && _suspiciousTlds.contains(tld)) {
      r.add(UrlReason(
        ReasonLevel.warning,
        'Ekstensi domain ".$tld" sering disalahgunakan untuk situs penipuan.',
        'The ".$tld" domain extension is frequently abused by scam sites.',
      ));
    }

    // Terlalu banyak subdomain, mis. "bca.co.id.login.verify-akun.xyz"
    if (labels.length > 4) {
      r.add(UrlReason(
        ReasonLevel.warning,
        'Terlalu banyak subdomain (${labels.length} bagian). Teknik ini sering dipakai agar URL terlihat seperti situs resmi.',
        'Too many subdomains (${labels.length} parts). This trick is often used to look like an official site.',
      ));
    }

    // Port tidak standar
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      r.add(UrlReason(
        ReasonLevel.info,
        'Menggunakan port tidak standar (${uri.port}).',
        'Uses a non-standard port (${uri.port}).',
      ));
    }

    // URL sangat panjang
    final length = uri.toString().length;
    if (length > 120) {
      r.add(UrlReason(
        ReasonLevel.info,
        'URL sangat panjang ($length karakter). URL panjang dapat menyembunyikan domain sebenarnya.',
        'Very long URL ($length characters). Long URLs can hide the real domain.',
      ));
    }

    return r;
  }

  /// "SearchEnginesAndServices" -> "Search Engines And Services"
  static String _prettify(String name) =>
      name.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}');
}
