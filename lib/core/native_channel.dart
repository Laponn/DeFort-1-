import 'dart:async';
import 'package:flutter/services.dart';
import 'net_check.dart';

class KasperskyChannel {
  static const MethodChannel _channel = MethodChannel('com.defort/native_sdk');

  static final StreamController<Map<String, dynamic>> _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  static bool _handlerInitialized = false;

  /// Stream event dari native (onScanProgress, onScanCompleted, onNetworkScanStep)
  static Stream<Map<String, dynamic>> get events {
    _ensureHandler();
    return _eventController.stream;
  }

  static void _ensureHandler() {
    if (_handlerInitialized) return;
    _handlerInitialized = true;
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map
          ? Map<String, dynamic>.from(call.arguments as Map)
          : <String, dynamic>{};
      _eventController.add({
        'event': call.method,
        ...args,
      });
    });
  }

  /// Inisialisasi SDK di Native (License Check)
  static Future<bool> initSdk() async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMethod('initializeSdk');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// Cek apakah ada pemindaian yang sedang berjalan di background
  static Future<Map<String, dynamic>> getActiveScanState() async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMethod('getActiveScanState');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'isScanning': false};
    } catch (_) {
      return {'isScanning': false};
    }
  }

  /// Pindahkan aplikasi ke background tanpa mematikan FlutterEngine
  static Future<bool> moveTaskToBack() async {
    try {
      return await _channel.invokeMethod<bool>('moveTaskToBack') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah aplikasi sudah memiliki izin akses penyimpanan penuh (untuk Pindai Folder / Full Scan)
  static Future<bool> checkStoragePermission() async {
    try {
      return await _channel.invokeMethod<bool>('checkStoragePermission') ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Minta izin akses seluruh file (Android 11+ MANAGE_EXTERNAL_STORAGE / READ_EXTERNAL_STORAGE)
  static Future<bool> requestStoragePermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestStoragePermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 1. MALWARE DETECTION
  // ==========================================

  /// Mulai Pemindaian Malware (EasyScan) — tetap berjalan di background lewat Foreground Service
  static Future<Map<String, dynamic>> scanMalware({
    String mode = 'Quick',
    String source = 'ScanTab',
  }) async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMethod('startEasyScan', {
        'mode': mode,
        'source': source,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Pemindaian Folder Spesifik — tetap berjalan di background lewat Foreground Service
  static Future<Map<String, dynamic>> scanFolder(String path) async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMethod('scanFolder', {'path': path});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==========================================
  // 2. ANTI-PHISHING & FAKE APPS
  // ==========================================

  /// Pengecekan Keamanan Jaringan / URL
  ///
  /// Sukses: {url, verdict: GOOD|BAD|UNKNOWN, verdictCode, categories, isSafe}
  /// Gagal : {error: pesan, code: INVALID_URL|SDK_NOT_READY|LICENSE_INVALID|NETWORK_ERROR|TIMEOUT|...}
  static Future<Map<String, dynamic>> checkUrlPhishing(
    String url, {
    bool showNotification = true,
  }) async {
    _ensureHandler();
    try {
      final result = await _channel
          .invokeMethod('checkUrlPhishing', {
            'url': url,
            'showNotification': showNotification,
          })
          .timeout(const Duration(seconds: 30));
      return Map<String, dynamic>.from(result);
    } on TimeoutException {
      return {'error': 'Server Kaspersky tidak merespons', 'code': 'TIMEOUT'};
    } on PlatformException catch (e) {
      return {'error': e.message ?? e.code, 'code': e.code};
    } catch (e) {
      return {'error': e.toString(), 'code': 'UNKNOWN_ERROR'};
    }
  }

  /// Mulai Monitor Aplikasi Palsu
  static Future<bool> startFakeAppMonitor() async {
    try {
      final result = await _channel.invokeMethod('startFakeAppMonitor');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 3. SECURE CONNECTIVITY
  // ==========================================

  /// Jalankan seluruh pemeriksaan keamanan jaringan (Wi-Fi, DNS, URL, SSL)
  /// di dalam Foreground Service agar tetap selesai meski keluar aplikasi.
  static Future<Map<String, NetCheck>> runFullNetworkScan() async {
    _ensureHandler();
    try {
      final result = await _channel
          .invokeMethod('runFullNetworkScan')
          .timeout(const Duration(seconds: 60));
      final map = Map<String, dynamic>.from(result as Map);
      return {
        'wifi': NetCheck.fromMap(map['wifi'] as Map? ?? {}),
        'dns': NetCheck.fromMap(map['dns'] as Map? ?? {}),
        'url': NetCheck.fromMap(map['url'] as Map? ?? {}),
        'ssl': NetCheck.fromMap(map['ssl'] as Map? ?? {}),
      };
    } on TimeoutException {
      final err = NetCheck.error('Pemeriksaan tidak merespons dalam 60 detik. Periksa koneksi internet Anda.');
      return {'wifi': err, 'dns': err, 'url': err, 'ssl': err};
    } on PlatformException catch (e) {
      final err = NetCheck.error(e.message ?? e.code);
      return {'wifi': err, 'dns': err, 'url': err, 'ssl': err};
    } catch (e) {
      final err = NetCheck.error(e.toString());
      return {'wifi': err, 'dns': err, 'url': err, 'ssl': err};
    }
  }

  /// Helper umum: panggil method native yang mengembalikan {level, summary, reasons}.
  static Future<NetCheck> _invokeCheck(String method, [Map<String, dynamic>? args]) async {
    try {
      final result = await _channel
          .invokeMethod(method, args)
          .timeout(const Duration(seconds: 20));
      return NetCheck.fromMap(result as Map);
    } on TimeoutException {
      return NetCheck.error('Pemeriksaan tidak merespons dalam 20 detik. Periksa koneksi internet Anda.');
    } on PlatformException catch (e) {
      return NetCheck.error(e.message ?? e.code);
    } catch (e) {
      return NetCheck.error(e.toString());
    }
  }

  /// Cek Keamanan Wi-Fi (reputasi Kaspersky + enkripsi)
  static Future<NetCheck> checkWifiSecurity() => _invokeCheck('checkWifiSecurity');

  /// Cek Integritas DNS
  static Future<NetCheck> checkDns(String domain) => _invokeCheck('checkDns', {'domain': domain});

  /// Validasi Sertifikat SSL
  static Future<NetCheck> validateSsl(String url) => _invokeCheck('validateSsl', {'url': url});

  /// Minta izin lokasi (dibutuhkan Android untuk membaca nama Wi-Fi)
  static Future<bool> requestLocationPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestLocationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openLocationSettings() => _channel.invokeMethod('openLocationSettings');
  static Future<void> openAppSettings() => _channel.invokeMethod('openAppSettings');

  /// Ambil Informasi WiFi Real dari Device
  static Future<Map<String, dynamic>> getWifiInfo() async {
    try {
      final result = await _channel.invokeMethod('getWifiInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {
        'isConnected': false,
        'ssid': 'Error',
        'ssidAvailable': false,
        'ssidReason': 'Gagal membaca info Wi-Fi: $e',
        'bssid': '00:00:00:00:00:00',
        'linkSpeed': -1,
        'frequency': -1,
        'rssi': -127,
        'signalLevel': 0,
        'connectionType': 'Tidak Diketahui',
      };
    }
  }
}
