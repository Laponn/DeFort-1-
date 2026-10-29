/// Hasil satu pemeriksaan keamanan jaringan (Wi-Fi, DNS, URL, SSL).
class NetCheck {
  /// IDLE, CHECKING, SAFE, WARNING, DANGER, ERROR, UNKNOWN
  final String level;

  /// Teks singkat untuk ditampilkan, mis. "Berbahaya".
  final String summary;

  /// Alasan lengkap kenapa hasilnya seperti itu.
  final List<String> reasons;

  /// Data tambahan dari native (mis. ssid, encryption).
  final Map<String, dynamic> extra;

  const NetCheck(this.level, this.summary, {this.reasons = const [], this.extra = const {}});

  static const idle = NetCheck('IDLE', 'Belum Diperiksa');
  static const checking = NetCheck('CHECKING', 'Memeriksa...');

  factory NetCheck.fromMap(Map<dynamic, dynamic> m) {
    final map = Map<String, dynamic>.from(m);
    return NetCheck(
      map['level'] as String? ?? 'UNKNOWN',
      map['summary'] as String? ?? '-',
      reasons: List<String>.from(map['reasons'] as List? ?? const []),
      extra: map,
    );
  }

  factory NetCheck.error(String reason) =>
      NetCheck('ERROR', 'Tidak dapat diperiksa', reasons: [reason]);

  bool get isPending => level == 'IDLE' || level == 'CHECKING';
  bool get isSafe => level == 'SAFE';
}
