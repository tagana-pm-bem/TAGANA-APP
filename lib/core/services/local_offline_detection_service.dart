import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'ble_telemetry_service.dart';
import 'push_notification_service.dart';

class LocalOfflineDetectionService {
  LocalOfflineDetectionService._();

  static final LocalOfflineDetectionService _instance =
      LocalOfflineDetectionService._();
  static LocalOfflineDetectionService get instance => _instance;

  Timer? _offlineCheckTimer;
  final Map<String, DateTime> _lastOnlineTime = {};
  final Set<String> _notifiedOfflineDevices = {};
  bool _isMonitoring = false;

  /// Threshold untuk menandai device offline via local detection (seconds)
  /// Jika tidak ada komunikasi BLE selama threshold ini, dianggap offline
  static const int LOCAL_OFFLINE_THRESHOLD_SEC = 30;

  /// Start monitoring for local offline detection
  /// Dijalankan saat HP offline tapi punya BLE connection ke device
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Check connectivity setiap 5 detik
    _offlineCheckTimer = Timer.periodic(Duration(seconds: 5), (_) async {
      await _checkDeviceConnectivity();
    });

    print('[LocalOfflineDetection] Monitoring started');
  }

  Future<void> stopMonitoring() async {
    _offlineCheckTimer?.cancel();
    _offlineCheckTimer = null;
    _lastOnlineTime.clear();
    _notifiedOfflineDevices.clear();
    _isMonitoring = false;
    print('[LocalOfflineDetection] Monitoring stopped');
  }

  /// Record last successful communication time via BLE/Hotspot
  void recordDeviceOnline(String deviceId) {
    _lastOnlineTime[deviceId] = DateTime.now();
    _notifiedOfflineDevices.remove(deviceId);
    print('[LocalOfflineDetection] Device $deviceId marked online');
  }

  /// Check if device has been offline locally (no BLE/Hotspot communication)
  Future<void> _checkDeviceConnectivity() async {
    // Hanya jalankan jika HP offline (tidak ada internet)
    final isOnline = await _checkHostsConnectivity();
    if (isOnline) {
      // HP punya internet, server-side monitoring (FCM) yang handle
      return;
    }

    // HP offline, check device connectivity via BLE/Hotspot
    final bleService = BleTelemetryService.instance;
    if (!bleService.isConnected) {
      // Tidak ada BLE connection, skip
      return;
    }

    final deviceId = bleService.connectedDeviceId;
    final deviceCode = bleService.connectedDeviceCode ?? 'TAGANA';
    if (deviceId == null) return;

    final lastOnline = _lastOnlineTime[deviceId];
    if (lastOnline == null) {
      // Baru koneksi, set waktu sekarang
      _lastOnlineTime[deviceId] = DateTime.now();
      return;
    }

    final secondsSinceLastOnline = DateTime.now()
        .difference(lastOnline)
        .inSeconds;

    if (secondsSinceLastOnline > LOCAL_OFFLINE_THRESHOLD_SEC) {
      // Device sudah offline selama > threshold
      if (!_notifiedOfflineDevices.contains(deviceId)) {
        _notifyDeviceOffline(deviceId, deviceCode);
        _notifiedOfflineDevices.add(deviceId);
      }
    }
  }

  void _notifyDeviceOffline(String deviceId, String deviceCode) {
    print(
      '[LocalOfflineDetection] Device $deviceCode ($deviceId) detected offline locally',
    );

    PushNotificationService.instance.showLocalNotification(
      title: 'Perangkat Tidak Terkoneksi',
      body:
          'Perangkat $deviceCode tidak merespons komunikasi Bluetooth/Hotspot.',
      payload:
          '{"device_id":"$deviceId","event":"device_offline","source":"local"}',
      id: deviceId.hashCode,
    );
  }

  /// Simple check: try connect to Google DNS (8.8.8.8:53) dengan timeout
  /// Return true jika HP punya internet
  Future<bool> _checkHostsConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Untuk debug: check current online status
  Future<bool> isDeviceOnline(String deviceId) async {
    final lastOnline = _lastOnlineTime[deviceId];
    if (lastOnline == null) return true;

    final secondsSinceLastOnline = DateTime.now()
        .difference(lastOnline)
        .inSeconds;
    return secondsSinceLastOnline <= LOCAL_OFFLINE_THRESHOLD_SEC;
  }
}
