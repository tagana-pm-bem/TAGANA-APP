import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import '../../features/dashboard/models/dashboard_models.dart';

class DashboardService {
  DashboardService._();

  static SupabaseClient get _client => SupabaseClientService.client;

  /// Ambil snapshot data dashboard sekali (dipakai saat halaman pertama
  /// dibuka / pull-to-refresh). RLS otomatis membatasi hasil ke device
  /// milik user yang sedang login (auth.uid()), jadi tidak perlu filter
  /// user_id manual di sisi client.
  static Future<DashboardData> fetchDashboardData() async {
    try {
      final devicesRaw = await _client
          .from('devices')
        .select('''
          id,
          device_code,
          device_name,
          firmware_version,
          is_active,
          registered_at,
          device_status (
            status,
            water_level,
            battery_level,
            signal_strength,
            is_flood_detected,
            last_seen_at,
            updated_at
        ''')
        .order('registered_at', ascending: false)
        .timeout(const Duration(seconds: 2));

    final devices = (devicesRaw as List)
        .map((e) => DeviceWithStatus.fromJson(e as Map<String, dynamic>))
        .toList();

    final deviceIds = devices.map((d) => d.id).toList();

    List<AlertSummary> alerts = [];
    if (deviceIds.isNotEmpty) {
      final alertsRaw = await _client
          .from('alerts')
          .select('''
            id,
            type,
            severity,
            status,
            value,
            threshold,
            message,
            triggered_at,
            resolved_at,
            devices ( device_code, device_name )
          ''')
          .inFilter('device_id', deviceIds)
          .order('triggered_at', ascending: false)
          .limit(10)
          .timeout(const Duration(seconds: 4));

      alerts = (alertsRaw as List)
          .map((e) => AlertSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final dashboardData = DashboardData(devices: devices, alerts: alerts);
    
    // Simpan ke cache lokal
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_dashboard_data', jsonEncode(dashboardData.toJson()));
    } catch (_) {}

    return dashboardData;
    } catch (e) {
      // Jika gagal fetch (misal tidak ada internet), coba baca dari cache
      try {
        final prefs = await SharedPreferences.getInstance();
        final str = prefs.getString('cached_dashboard_data');
        if (str != null) {
          return DashboardData.fromJson(jsonDecode(str));
        }
      } catch (_) {}
      
      rethrow;
    }
  }

  /// Subscribe ke perubahan `device_status` secara realtime. RLS untuk
  /// realtime tetap berlaku (butuh session Auth aktif), jadi hanya baris
  /// milik device user yang login yang akan diterima.
  ///
  /// Panggil [onChange] setiap kali ada insert/update, lalu di UI cukup
  /// panggil ulang [fetchDashboardData] (paling simpel) atau update state
  /// secara granular kalau mau lebih optimal nanti.
  static RealtimeChannel subscribeToDeviceStatus({
    required void Function() onChange,
  }) {
    final channel = _client
        .channel('dashboard-device-status')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_status',
          callback: (payload) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerts',
          callback: (payload) => onChange(),
        )
        .subscribe();

    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}