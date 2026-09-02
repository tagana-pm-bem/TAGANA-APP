import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import 'push_notification_service.dart';

class DeviceAlertService {
  DeviceAlertService._();

  static final DeviceAlertService _instance = DeviceAlertService._();
  static DeviceAlertService get instance => _instance;

  final Map<String, String> _lastTriggered = {};
  RealtimeChannel? _channel;
  bool _isMonitoring = false;

  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;

    _channel = SupabaseClientService.client
        .channel('tagana-device-alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_status',
          callback: (payload) async {
            final deviceId =
                payload.newRecord['device_id'] ??
                payload.oldRecord['device_id'];
            if (deviceId == null) return;
            await _evaluateDevice(deviceId.toString());
          },
        )
        .subscribe();

    final devices = await _fetchUserDevices();
    for (final device in devices) {
      final deviceId = device['id']?.toString();
      if (deviceId != null) {
        await _evaluateDevice(deviceId);
      }
    }
  }

  Future<void> stopMonitoring() async {
    if (_channel != null) {
      await SupabaseClientService.client.removeChannel(_channel!);
      _channel = null;
    }
    _lastTriggered.clear();
    _isMonitoring = false;
  }

  Future<List<Map<String, dynamic>>> _fetchUserDevices() async {
    final data = await SupabaseClientService.client.from('devices').select('''
      id,
      device_code,
      device_name,
      user_id,
      device_status (
        status,
        water_level,
        is_flood_detected,
        last_seen_at,
        updated_at
      )
    ''');

    final list = data as List? ?? const [];
    return list
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> _evaluateDevice(String deviceId) async {
    try {
      final currentUserId = SupabaseClientService.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final data = await SupabaseClientService.client
          .from('devices')
          .select('''
        id,
        device_code,
        device_name,
        user_id,
        device_status (
          status,
          water_level,
          is_flood_detected,
          last_seen_at,
          updated_at
        )
      ''')
          .eq('id', deviceId)
          .maybeSingle();

      if (data == null) return;
      final ownerId = data['user_id']?.toString();
      if (ownerId == null || ownerId != currentUserId) return;

      final statusList = data['device_status'];
      final status = statusList is List && statusList.isNotEmpty
          ? statusList.first as Map<String, dynamic>
          : statusList is Map<String, dynamic>
          ? statusList
          : null;

      if (status == null) return;

      final deviceCode = (data['device_code'] ?? 'TAGANA').toString();
      final currentStatus = (status['status'] ?? '').toString().toLowerCase();
      final waterLevelRaw = status['water_level'];
      final waterLevel = waterLevelRaw is num ? waterLevelRaw.toDouble() : 0.0;
      final isFlood = status['is_flood_detected'] == true || waterLevel > 50;
      final isOffline =
          currentStatus == 'offline' ||
          currentStatus == 'disconnected' ||
          currentStatus == 'not_connected' ||
          currentStatus == 'lost' ||
          currentStatus == 'error';

      if (isOffline) {
        _maybeTriggerAlert(
          deviceId: deviceId,
          userId: ownerId,
          key: 'offline',
          title: 'Sensor Offline',
          body: 'Sensor $deviceCode tidak terhubung ke Wi‑Fi / jaringan internet.',
          notificationType: 'device_offline',
        );
        return;
      }

      if (isFlood) {
        _maybeTriggerAlert(
          deviceId: deviceId,
          userId: ownerId,
          key: 'flood',
          title: 'Air Terdeteksi',
          body: 'Sensor $deviceCode mendeteksi air / level air tinggi ($waterLevel).',
          notificationType: 'flood_warning',
        );
        return;
      }

      _lastTriggered.remove(deviceId);
    } catch (_) {
      // Ignore transient Realtime errors; retry next update.
    }
  }

  void _maybeTriggerAlert({
    required String deviceId,
    required String userId,
    required String key,
    required String title,
    required String body,
    required String notificationType,
  }) {
    final lastKey = _lastTriggered[deviceId];
    if (lastKey == key) return;

    _lastTriggered[deviceId] = key;

    SupabaseClientService.client.from('notifications').insert({
      'user_id': userId,
      'device_id': deviceId,
      'type': notificationType,
      'title': title,
      'message': body,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });

    PushNotificationService.instance.showLocalNotification(
      title: title,
      body: body,
      payload: '{"device_id":"$deviceId","type":"$key","user_id":"$userId"}',
    );
  }
}
