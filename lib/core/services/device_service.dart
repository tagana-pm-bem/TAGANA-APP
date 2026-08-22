import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tagana_app/core/supabase/supabase_client.dart';
import 'package:tagana_app/features/onboarding/verifying_device.dart';
import 'package:tagana_app/features/auth/data/user_repository.dart';

/// Service untuk verifikasi dan pairing perangkat TAGANA ke akun pengguna.
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
        return DeviceVerificationResult.failure(
          (data?['message'] as String?) ?? 'Verifikasi perangkat gagal.',
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

      // Kasus khusus: device sudah milik user yang sama (reconnect)
      // Edge function mengembalikan 409 karena user_id != null.
      // Cek apakah user_id di DB sudah milik user yang login.
      if (message != null && message.contains('sudah terpasang')) {
        print('[DeviceService] Device sudah terpasang, memeriksa kepemilikan (reconnect)...');
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
        return const DeviceVerificationResult.failure(
          'Kode perangkat tidak terdaftar.',
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
}
