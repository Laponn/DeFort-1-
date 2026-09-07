import 'package:flutter/services.dart';

class KasperskyChannel {
  static const MethodChannel _channel = MethodChannel('com.defort/native_sdk');

  /// Inisialisasi SDK di Native (License Check)
  static Future<bool> initSdk() async {
    try {
      final result = await _channel.invokeMethod('initializeSdk');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 1. MALWARE DETECTION
  // ==========================================
  
  /// Mulai Pemindaian Malware (EasyScan)
  static Future<Map<String, dynamic>> scanMalware() async {
    try {
      final result = await _channel.invokeMethod('startEasyScan');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==========================================
  // 2. ANTI-PHISHING & FAKE APPS
  // ==========================================
  
  /// Pengecekan Keamanan Jaringan / URL
  static Future<Map<String, dynamic>> checkUrlPhishing(String url) async {
    try {
      final result = await _channel.invokeMethod('checkUrlPhishing', {'url': url});
      return Map<String, dynamic>.from(result);
    } catch (e) {
       return {'error': e.toString()};
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
  
  /// Cek Keamanan Wi-Fi
  static Future<bool> checkWifiSecurity(String bssid) async {
    try {
      final result = await _channel.invokeMethod('checkWifiSecurity', {'bssid': bssid});
      if (result is Map) {
        return result['isSafe'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cek Integritas DNS
  static Future<bool> checkDns(String domain) async {
    try {
      final result = await _channel.invokeMethod('checkDns', {'domain': domain});
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  /// Validasi Sertifikat SSL
  static Future<bool> validateSsl(String url) async {
    try {
      final result = await _channel.invokeMethod('validateSsl', {'url': url});
      return result as bool;
    } catch (e) {
      return false;
    }
  }
}
