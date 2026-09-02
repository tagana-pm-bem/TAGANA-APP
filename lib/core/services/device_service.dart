import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tagana_app/core/supabase/supabase_client.dart';
import 'package:tagana_app/features/onboarding/verifying_device.dart';
import 'package:tagana_app/features/auth/data/user_repository.dart';
import '../../features/dashboard/models/dashboard_models.dart';
import '../../features/device/models/device_detail_data.dart';
import '../supabase/supabase_client.dart';

/// Service untuk verifikasi dan pairing perangkat TAGANA ke akun pengguna,
/// serta pengambilan data perangkat (list & detail) untuk kebutuhan UI.
class DeviceService {
  DeviceService._();

  /// Verifikasi kode perangkat [deviceCode] dan pasangkan ke akun pengguna
  /// yang sedang login.
  ///
  /// Alur:
  /// 1. Pastikan user sudah login (ada session).
  /// 2. Panggil edge function `pair-device` dengan device_code + user_id.
  /// 4. Return [DeviceVerificationResult] sesuai hasil.
  static Future<DeviceVerificationResult> verifyAndPairDevice(
    String deviceCode,
  ) async {
    print('[DeviceService] Memulai verifikasi perangkat untuk kode: $deviceCode');
    // 1. Pastikan user sudah login
    final user = UserRepository.currentUser;
    if (user == null) {
      print('[DeviceService] Error: User belum login / sesi tidak ada.');
      return const DeviceVerificationResult.failure(
        'Sesi tidak ditemukan. Silakan login ulang.',
      );
    }

    try {
      print('[DeviceService] Memanggil edge function pair-device dengan device_code: $deviceCode, user_id: ${user.id}');
      // 2. Panggil edge function pair-device
      final response = await SupabaseClientService.client.functions.invoke(
        'pair-device',
        body: {
          'device_code': deviceCode,
          'user_id': user.id,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      print('[DeviceService] Response dari edge function: $data');

      if (data == null || data['success'] != true) {
        print('[DeviceService] Pairing gagal dari response success=false');
        final message = (data?['message'] as String?) ?? '';
        
        if (message.contains('sudah terpasang') || 
            message.contains('terdaftar') || 
            message.contains('dimiliki') ||
            message.contains('terpakai')) {
          print('[DeviceService] Device sudah memiliki pemilik, memeriksa kepemilikan (reconnect)...');
          return _handleAlreadyPaired(deviceCode: deviceCode, currentUserId: user.id);
        }

        return DeviceVerificationResult.failure(
          message.isNotEmpty ? message : 'Verifikasi perangkat gagal.',
        );
      }

      print('[DeviceService] Pairing berhasil.');
      // 3. Pairing berhasil — ambil info device dari respons
      return _buildSuccessResult(
        deviceCode: deviceCode,
        deviceFromResponse: data['device'] as Map<String, dynamic>?,
        userId: user.id,
      );
    } on FunctionException catch (e) {
      print('[DeviceService] FunctionException dari edge function: status ${e.status}, details: ${e.details}');
      // FunctionException dilempar untuk status HTTP non-2xx dari Edge Function.
      // Kita parse body-nya untuk mendapatkan pesan error yang sesuai.
      final body = e.details;

      String? message;
      if (body is Map<String, dynamic>) {
        message = body['message'] as String?;
      } else if (body is String) {
        message = body;
      }

      // Kasus khusus: device sudah milik user yang sama (reconnect) atau user lain.
      // Edge function mengembalikan error karena user_id != null.
      // Cek apakah user_id di DB sudah milik user yang login.
      if (message != null && (
          message.contains('sudah terpasang') || 
          message.contains('terdaftar') || 
          message.contains('dimiliki') ||
          message.contains('terpakai')
      )) {
        print('[DeviceService] Device sudah memiliki pemilik, memeriksa kepemilikan (reconnect)...');
        return _handleAlreadyPaired(deviceCode: deviceCode, currentUserId: user.id);
      }

      return DeviceVerificationResult.failure(
        _friendlyMessage(message ?? e.toString()),
      );
    } catch (e, stackTrace) {
      print('[DeviceService] Exception tidak terduga saat memanggil edge function: $e');
      return DeviceVerificationResult.failure(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Hanya memverifikasi ketersediaan kode perangkat (tanpa melakukan pairing).
  static Future<DeviceVerificationResult> verifyDeviceOnly(
    String deviceCode,
  ) async {
    print('[DeviceService] Memulai verifikasi perangkat (tanpa pairing) untuk kode: $deviceCode');
    final user = UserRepository.currentUser;
    if (user == null) {
      return const DeviceVerificationResult.failure('Sesi tidak ditemukan.');
    }
    try {
      final result = await SupabaseClientService.client
          .from('devices')
          .select('id, device_code, device_name, firmware_version, user_id')
          .ilike('device_code', deviceCode)
          .maybeSingle();

      if (result == null) {
        return const DeviceVerificationResult.failure('Kode perangkat tidak terdaftar.');
      }

      final ownerId = result['user_id'] as String?;
      if (ownerId != null && ownerId != user.id) {
        return const DeviceVerificationResult.failure('Perangkat ini sudah terpasang pada akun lain.');
      }

      return DeviceVerificationResult.success(
        DeviceInfo(
          name: (result['device_name'] as String?) ?? deviceCode,
          code: (result['device_code'] as String?) ?? deviceCode,
          type: 'ESP32-TAGANA',
          firmware: (result['firmware_version'] as String?) ?? '-',
          region: '-',
        ),
      );
    } catch (_) {
      return const DeviceVerificationResult.failure('Gagal memverifikasi perangkat.');
    }
  }

  /// Cek apakah device yang sudah "terpasang" memang milik user yang sama.
  /// Jika iya, ini adalah reconnect yang valid — anggap sukses.
  /// Jika milik user lain, kembalikan failure.
  static Future<DeviceVerificationResult> _handleAlreadyPaired({
    required String deviceCode,
    required String currentUserId,
  }) async {
    try {
      final result = await SupabaseClientService.client
          .from('devices')
          .select('id, device_code, device_name, firmware_version, user_id')
          .ilike('device_code', deviceCode)
          .maybeSingle();

      if (result == null) {
        // Jika Edge Function bilang ini sudah terpasang (ada), tapi query ini 
        // mengembalikan null, itu karena RLS memblokirnya (milik user lain).
        return const DeviceVerificationResult.failure(
          'Perangkat ini sudah terpasang pada akun lain.',
        );
      }

      final ownerId = result['user_id'] as String?;

      if (ownerId == currentUserId) {
        // Device memang milik user yang sama → reconnect sukses
        return DeviceVerificationResult.success(
          DeviceInfo(
            name: (result['device_name'] as String?) ?? deviceCode,
            code: (result['device_code'] as String?) ?? deviceCode,
            type: 'ESP32-TAGANA',
            firmware: (result['firmware_version'] as String?) ?? '-',
            region: '-',
          ),
          alreadyOwned: true,
        );
      } else {
        // Benar-benar milik user lain
        return const DeviceVerificationResult.failure(
          'Perangkat ini sudah terpasang pada akun lain.',
        );
      }
    } catch (_) {
      return const DeviceVerificationResult.failure(
        'Gagal memverifikasi kepemilikan perangkat.',
      );
    }
  }

  /// Buat [DeviceVerificationResult.success] dari respons edge function.
  /// Jika firmware_version tidak ada di respons, query terpisah ke tabel devices.
  static Future<DeviceVerificationResult> _buildSuccessResult({
    required String deviceCode,
    required Map<String, dynamic>? deviceFromResponse,
    required String userId,
  }) async {
    final deviceName =
        (deviceFromResponse?['device_name'] as String?)?.isNotEmpty == true
            ? deviceFromResponse!['device_name'] as String
            : deviceCode;

    final deviceCodeResult =
        (deviceFromResponse?['device_code'] as String?) ?? deviceCode;

    // Ambil firmware_version via query langsung (tidak ada di respons pair-device)
    String firmwareVersion = '-';
    final deviceId = deviceFromResponse?['id'] as String?;
    if (deviceId != null) {
      try {
        final fw = await SupabaseClientService.client
            .from('devices')
            .select('firmware_version')
            .eq('id', deviceId)
            .maybeSingle();
        firmwareVersion = (fw?['firmware_version'] as String?) ?? 'v1.0.0';
      } catch (_) {
        // Tidak kritis — lanjut dengan default
        firmwareVersion = 'v1.0.0';
      }
    }

    return DeviceVerificationResult.success(
      DeviceInfo(
        name: deviceName,
        code: deviceCodeResult,
        type: 'ESP32-TAGANA',
        firmware: firmwareVersion,
        region: '-',
      ),
    );
  }

  /// Ambil semua perangkat milik user yang login beserta status terbarunya.  
  /// RLS otomatis membatasi ke device milik auth.uid(), sama seperti di
  /// DashboardService.
  static Future<List<DeviceWithStatus>> fetchDevices() async {
    final raw = await SupabaseClientService.client
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
          )
        ''')
        .order('registered_at', ascending: false);

    return (raw as List)
        .map((e) => DeviceWithStatus.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Subscribe realtime ke perubahan device_status, khusus dipakai halaman
  /// daftar perangkat. Channel diberi nama berbeda dari yang dipakai
  /// DashboardService supaya tidak bentrok kalau kedua halaman aktif.
  static RealtimeChannel subscribeToDeviceStatus({
    required void Function() onChange,
  }) {
    final channel = SupabaseClientService.client
        .channel('devices-page-status')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_status',
          callback: (payload) => onChange(),
        )
        .subscribe();

    return channel;
  }

  /// Ambil detail satu perangkat: info dasar + status terbaru + lokasi
  /// terbaru + log aktivitas terbaru. RLS otomatis membatasi ke device
  /// milik auth.uid(), sama seperti fetchDevices().
  static Future<DeviceDetailData> fetchDeviceDetail(String deviceId) async {
    final deviceRaw = await SupabaseClientService.client
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
          )
        ''')
        .eq('id', deviceId)
        .single();

    final locationRaw = await SupabaseClientService.client
        .from('device_locations')
        .select('latitude, longitude, accuracy, recorded_at')
        .eq('device_id', deviceId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final activitiesRaw = await SupabaseClientService.client
        .from('device_activities')
        .select('id, type, title, description, created_at')
        .eq('device_id', deviceId)
        .order('created_at', ascending: false)
        .limit(10);

    return DeviceDetailData(
      device: DeviceDetail.fromJson(deviceRaw),
      location: locationRaw != null
          ? DeviceLocationInfo.fromJson(locationRaw)
          : null,
      activities: (activitiesRaw as List)
          .map((e) => DeviceActivity.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Subscribe realtime khusus satu perangkat: status, lokasi, dan
  /// aktivitas. Dipakai di halaman DeviceDetailPage.
  static RealtimeChannel subscribeToDeviceDetail({
    required String deviceId,
    required void Function() onChange,
  }) {
    // Note: Filter dihapus karena filtering UUID di Supabase Realtime sering bermasalah (casing/format).
    // Karena jumlah device per user kecil, me-reload saat ada perubahan di tabel tersebut sudah cukup efisien.
    final channel = SupabaseClientService.client
        .channel('device-detail-$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_status',
          callback: (payload) {
            print('[REALTIME] device_status berubah! Payload: ${payload.newRecord}');
            final changedDeviceId = payload.newRecord['device_id'] ?? payload.oldRecord['device_id'];
            if (changedDeviceId?.toString().toLowerCase() == deviceId.toLowerCase()) onChange();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_locations',
          callback: (payload) {
            print('[REALTIME] device_locations berubah!');
            final changedDeviceId = payload.newRecord['device_id'] ?? payload.oldRecord['device_id'];
            if (changedDeviceId?.toString().toLowerCase() == deviceId.toLowerCase()) onChange();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_activities',
          callback: (payload) {
            print('[REALTIME] device_activities berubah!');
            final changedDeviceId = payload.newRecord['device_id'] ?? payload.oldRecord['device_id'];
            if (changedDeviceId?.toString().toLowerCase() == deviceId.toLowerCase()) onChange();
          },
        )
        .subscribe((status, [error]) {
           print('[REALTIME] Status channel device-detail: $status');
        });

    return channel;
  }

  /// Unsubscribe generik — dipakai untuk channel apa pun: daftar perangkat
  /// (subscribeToDeviceStatus) maupun detail perangkat
  /// (subscribeToDeviceDetail).
  static Future<void> unsubscribeDeviceStatus(RealtimeChannel channel) async {
    await SupabaseClientService.client.removeChannel(channel);
  }

  /// Terjemahkan pesan error teknis ke pesan yang ramah pengguna.
  static String _friendlyMessage(String raw) {
    if (raw.contains('Kode device tidak ditemukan') ||
        raw.contains('tidak ditemukan')) {
      return 'Kode perangkat tidak terdaftar. Periksa kembali kode pada label perangkat TAGANA.';
    }
    if (raw.contains('Device tidak aktif')) {
      return 'Perangkat tidak aktif. Hubungi administrator TAGANA.';
    }
    if (raw.contains('device_code dan user_id')) {
      return 'Data tidak lengkap. Silakan coba lagi.';
    }
    if (raw.contains('Internal server error')) {
      return 'Terjadi kesalahan server. Coba beberapa saat lagi.';
    }
    return raw.isNotEmpty ? raw : 'Verifikasi perangkat gagal. Coba lagi.';
  }

  static Future<void> logActivity({
    required String deviceId,
    required String type, // contoh: 'ble_connected', 'wifi_configured', dll
    required String title,
    String? description,
  }) async {
    try {
      final client = SupabaseClientService.client;
      await client.from('device_activities').insert({
        'device_id': deviceId,
        'type': type,
        'title': title,
        'description': description,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print('[LOG] Aktivitas "$title" berhasil dicatat.');
    } catch (e) {
      print('[LOG] Gagal mencatat aktivitas: $e');
    }
  }

  static Future<void> forceDeviceOffline(String deviceId) async {
    try {
      final client = SupabaseClientService.client;
      await client.from('device_status').update({
        'status': 'offline',
      }).eq('device_id', deviceId);
      print('[DeviceService] Status perangkat diset offline.');
    } catch (e) {
      print('[DeviceService] Gagal set offline: $e');
    }
  }
}