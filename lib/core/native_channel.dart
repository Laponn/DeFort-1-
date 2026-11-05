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

  // ==========================================
  // 4. TINDAKAN LANJUTAN: KARANTINA & REMEDIATION
  // ==========================================

  /// Karantina berkas berbahaya menggunakan engine Kaspersky (atau fallback vault DeFort).
  static Future<Map<String, dynamic>> quarantineThreat(
    String threatId, {
    String? filePath,
  }) async {
    try {
      final result = await _channel.invokeMethod('quarantineThreat', {
        'id': threatId,
        'filePath': filePath ?? '',
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      return {
        'success': false,
        'id': threatId,
        'message': 'Gagal melakukan karantina: $e',
      };
    }
  }

  /// Hapus permanen berkas berbahaya atau minta uninstal aplikasi jahat.
  static Future<Map<String, dynamic>> deleteThreat(
    String threatId, {
    String? filePath,
    String? packageName,
  }) async {
    try {
      final result = await _channel.invokeMethod('deleteThreat', {
        'id': threatId,
        'filePath': filePath ?? '',
        'packageName': packageName ?? '',
      });
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      return {
        'success': false,
        'id': threatId,
        'message': 'Gagal menghapus ancaman: $e',
      };
    }
  }

  /// Ambil daftar seluruh berkas yang sedang diisolasi di ruang karantina.
  static Future<List<Map<String, dynamic>>> getQuarantineList() async {
    try {
      final result = await _channel.invokeMethod('getQuarantineList');
      if (result is List) {
        return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Pulihkan berkas dari ruang karantina ke penyimpanan semula / Downloads.
  static Future<bool> restoreQuarantineItem(
    String quarantineName, {
    String? targetPath,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('restoreQuarantineItem', {
        'quarantineName': quarantineName,
        'targetPath': targetPath ?? '',
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hapus permanen berkas yang ada di dalam karantina.
  static Future<bool> deleteQuarantineItem(String quarantineName) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteQuarantineItem', {
        'quarantineName': quarantineName,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  // ==========================================
  // 5. PERIZINAN & PERLINDUNGAN LATAR BELAKANG
  // ==========================================

  /// Periksa status perizinan perangkat secara lengkap (Storage, Notifikasi, Baterai, Lokasi, Aksesibilitas, Pemantau Unduhan).
  static Future<Map<String, bool>> getDevicePermissionsStatus() async {
    try {
      final res = await _channel.invokeMethod('getDevicePermissionsStatus');
      if (res is Map) {
        return {
          'storage': res['storage'] == true,
          'notification': res['notification'] == true,
          'batteryOptimization': res['batteryOptimization'] == true,
          'location': res['location'] == true,
          'accessibility': res['accessibility'] == true,
          'downloadWatcher': res['downloadWatcher'] == true,
        };
      }
    } catch (_) {}
    return {
      'storage': false,
      'notification': false,
      'batteryOptimization': false,
      'location': false,
      'accessibility': false,
      'downloadWatcher': false,
    };
  }

  /// Cek apakah Layanan Aksesibilitas Anti-Phishing aktif di Pengaturan Android
  static Future<bool> isAccessibilityEnabled() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityEnabled') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Buka Pengaturan Aksesibilitas Android agar pengguna dapat mengaktifkan DeFort Anti-Phishing
  static Future<bool> openAccessibilitySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAccessibilitySettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Jalankan Pemantau Berkas Unduhan Latar Belakang (FolderMonitor + FileObserver)
  static Future<bool> startDownloadMonitor() async {
    try {
      return await _channel.invokeMethod<bool>('startDownloadMonitor') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Hentikan Pemantau Berkas Unduhan Latar Belakang
  static Future<bool> stopDownloadMonitor() async {
    try {
      return await _channel.invokeMethod<bool>('stopDownloadMonitor') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Cek apakah Pemantau Berkas Unduhan Latar Belakang sedang aktif
  static Future<bool> isDownloadMonitorActive() async {
    try {
      return await _channel.invokeMethod<bool>('isDownloadMonitorActive') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Pindai paket aplikasi tertentu secara langsung (Auto-scan verification)
  static Future<Map<String, dynamic>> scanInstalledAppNow(String packageName) async {
    try {
      final res = await _channel.invokeMethod('scanInstalledAppNow', {
        'packageName': packageName,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {'isSafe': true, 'threatCount': 0, 'threats': []};
  }

  /// Minta izin notifikasi Android (POST_NOTIFICATIONS)
  static Future<bool> requestNotificationPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestNotificationPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Minta izin agar aplikasi tidak dibatasi penghemat baterai (Background Run)
  static Future<bool> requestBatteryOptimization() async {
    try {
      return await _channel.invokeMethod<bool>('requestBatteryOptimization') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Jalankan uji coba / simulasi pencegahan tautan phishing latar belakang
  static Future<Map<String, dynamic>> testPhishingDetection({
    String url = 'https://secure-login-account-update.xyz/phishing',
    String reason = 'Phishing / Fake Banking Portal',
  }) async {
    try {
      final res = await _channel.invokeMethod('testPhishingDetection', {
        'url': url,
        'reason': reason,
      });
      if (res is Map) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {}
    return {'blocked': true, 'url': url, 'reason': reason};
  }
}
