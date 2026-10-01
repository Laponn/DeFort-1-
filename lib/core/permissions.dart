import 'package:flutter/services.dart';

/// Handles runtime permission requests via platform channel
/// Since we already have a native bridge, we extend it rather than adding another plugin
class PermissionService {
  static const MethodChannel _channel = MethodChannel('com.defort/permissions');

  /// Check and request storage permissions for scan features
  static Future<bool> requestStoragePermission() async {
    try {
      final result = await _channel.invokeMethod('requestStoragePermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check and request location permission for Wi-Fi SSID
  static Future<bool> requestLocationPermission() async {
    try {
      final result = await _channel.invokeMethod('requestLocationPermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request all necessary permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestAllPermissions');
      return Map<String, bool>.from(result as Map);
    } catch (e) {
      return {
        'storage': false,
        'location': false,
      };
    }
  }

  /// Check if all essential permissions are granted
  static Future<bool> hasEssentialPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkEssentialPermissions');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }
}
