import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;

  Timer? _checkTimer;
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  bool _isMonitoring = false;

  bool get isOnline => isOnlineNotifier.value;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Check connectivity setiap 10 detik
    _checkTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await _checkInternetConnectivity();
    });

    // Check immediately
    await _checkInternetConnectivity();
    print('[Connectivity] Monitoring started');
  }

  Future<void> stopMonitoring() async {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isMonitoring = false;
    print('[Connectivity] Monitoring stopped');
  }

  /// Check internet connectivity dengan DNS lookup
  Future<bool> _checkInternetConnectivity() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(Duration(seconds: 3));
      final isOnline = result.isNotEmpty && result.first.rawAddress.isNotEmpty;

      if (isOnline != isOnlineNotifier.value) {
        isOnlineNotifier.value = isOnline;
        print('[Connectivity] Status changed: $isOnline');
      }
      return isOnline;
    } on SocketException catch (_) {
      if (isOnlineNotifier.value != false) {
        isOnlineNotifier.value = false;
        print('[Connectivity] Lost internet connection');
      }
      return false;
    } catch (_) {
      if (isOnlineNotifier.value != false) {
        isOnlineNotifier.value = false;
      }
      return false;
    }
  }

  /// Manual check
  Future<bool> checkNow() async {
    return await _checkInternetConnectivity();
  }
}
