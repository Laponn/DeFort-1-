import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for storing scan history
class ScanRecord {
  final String type; // 'quick', 'full', 'folder'
  final DateTime timestamp;
  final int filesScanned;
  final int malwareCount;
  final List<String> malwareList;
  final bool isRealSdk;
  final String? folderPath;

  ScanRecord({
    required this.type,
    required this.timestamp,
    required this.filesScanned,
    required this.malwareCount,
    required this.malwareList,
    required this.isRealSdk,
    this.folderPath,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp.toIso8601String(),
    'filesScanned': filesScanned,
    'malwareCount': malwareCount,
    'malwareList': malwareList,
    'isRealSdk': isRealSdk,
    'folderPath': folderPath,
  };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
    type: json['type'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    filesScanned: json['filesScanned'] as int,
    malwareCount: json['malwareCount'] as int,
    malwareList: List<String>.from(json['malwareList'] as List),
    isRealSdk: json['isRealSdk'] as bool,
    folderPath: json['folderPath'] as String?,
  );

  String get typeDisplay {
    switch (type) {
      case 'quick': return 'Pindai Cepat';
      case 'full': return 'Pindai Menyeluruh';
      case 'folder': return 'Pindai Folder';
      case 'url': return 'Cek Tautan (Phishing)';
      case 'wifi': return 'Keamanan Wi-Fi';
      case 'dns': return 'Integritas DNS';
      case 'ssl': return 'Validasi SSL';
      case 'app_monitor': return 'Monitor Aplikasi';
      default: return type;
    }
  }

  bool get isSafe => malwareCount == 0;
  
  String get target => folderPath ?? '';
  
  bool get isFileScan => type == 'quick' || type == 'full' || type == 'folder';
}

/// Service for managing scan history persistence
class ScanHistoryService {
  static const String _key = 'scan_history';
  static const int _maxRecords = 50;

  static Future<List<ScanRecord>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    return data.map((e) {
      try {
        return ScanRecord.fromJson(jsonDecode(e) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<ScanRecord>().toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> addRecord(ScanRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_key) ?? [];
    data.insert(0, jsonEncode(record.toJson()));

    // Keep only the latest records
    if (data.length > _maxRecords) {
      data.removeRange(_maxRecords, data.length);
    }

    await prefs.setStringList(_key, data);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<ScanRecord?> getLastScan() async {
    final history = await getHistory();
    if (history.isEmpty) return null;
    return history.first;
  }
}
