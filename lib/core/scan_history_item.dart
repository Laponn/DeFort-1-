import 'dart:convert';

/// Model untuk merepresentasikan satu entri riwayat pemindaian.
class ScanHistoryItem {
  final int? id;
  final String scanType;
  final int timestamp;
  final String statusLevel;
  final String summary;
  final String details; // Data tambahan (JSON format)

  ScanHistoryItem({
    this.id,
    required this.scanType,
    required this.timestamp,
    required this.statusLevel,
    required this.summary,
    required this.details,
  });

  /// Mengonversi objek menjadi Map untuk disimpan ke SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'scan_type': scanType,
      'timestamp': timestamp,
      'status': statusLevel,
      'summary': summary,
      'details': details,
    };
  }

  /// Membentuk objek dari hasil query SQLite
  factory ScanHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScanHistoryItem(
      id: map['id'] as int?,
      scanType: map['scan_type'] as String,
      timestamp: map['timestamp'] as int,
      statusLevel: map['status'] as String,
      summary: map['summary'] as String,
      details: map['details'] as String,
    );
  }

  /// Mengekstrak detail string (JSON) kembali menjadi Map Dart
  Map<String, dynamic> get parsedDetails {
    try {
      return jsonDecode(details) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
