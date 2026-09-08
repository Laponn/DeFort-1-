import 'package:flutter/services.dart';

class KasperskyChannel {
  static const MethodChannel _channel = MethodChannel('com.defort/native_sdk');

  /// Inisialisasi SDK di Native (License Check)
  static Future<Map<String, dynamic>> initSdk() async {
    try {
      final result = await _channel.invokeMethod('initializeSdk');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isReady': false, 'error': e.toString()};
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
  
  /// Pengecekan Keamanan URL via Kaspersky KSN Cloud
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
  static Future<Map<String, dynamic>> checkWifiSecurity(String bssid) async {
    try {
      final result = await _channel.invokeMethod('checkWifiSecurity', {'bssid': bssid});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isSafe': false, 'error': e.toString()};
    }
  }

  /// Cek Integritas DNS
  static Future<Map<String, dynamic>> checkDns(String domain) async {
    try {
      final result = await _channel.invokeMethod('checkDns', {'domain': domain});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isSafe': false, 'error': e.toString()};
    }
  }

  /// Validasi Sertifikat SSL
  static Future<Map<String, dynamic>> validateSsl(String url) async {
    try {
      final result = await _channel.invokeMethod('validateSsl', {'url': url});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'isValid': false, 'error': e.toString()};
    }
  }
}
