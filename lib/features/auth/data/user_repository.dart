import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();

  static final _client = SupabaseClientService.client;
  static UserProfile? currentUser;

  static Future<UserProfile> register({
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'register-user',
        body: {
          'name': name.trim(),
          'phone': phone.trim(),
        },
      );

      final data = res.data;
      if (data == null || data['success'] != true || data['user'] == null) {
        throw Exception(data?['message'] ?? 'Gagal membuat akun');
      }

      await _establishSession(data['auth'] as Map<String, dynamic>?);

      final userProfile = UserProfile.fromJson(data['user']);
      currentUser = userProfile;
      return userProfile;
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  static Future<UserProfile?> login({
    required String phone,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'login-user',
        body: {
          'phone': phone.trim(),
        },
      );

      final data = res.data;
      if (data == null || data['success'] != true || data['user'] == null) {
        return null;
      }

      await _establishSession(data['auth'] as Map<String, dynamic>?);

      final userProfile = UserProfile.fromJson(data['user']);
      currentUser = userProfile;
      return userProfile;
    } catch (e) {
      return null;
    }
  }

  /// Tukar `token_hash` yang dikembalikan edge function menjadi session
  /// Supabase Auth asli di client, supaya `auth.uid()` terisi di sisi
  /// database (dipakai oleh RLS policy & Realtime).
  static Future<void> _establishSession(Map<String, dynamic>? auth) async {
    final tokenHash = auth?['token_hash'] as String?;

    if (tokenHash == null) {
      throw Exception('Data sesi tidak lengkap dari server.');
    }

    await _client.auth.verifyOTP(
      type: OtpType.magiclink,
      tokenHash: tokenHash,
    );
  }

  /// Dipanggil saat app start untuk memulihkan profile dari session yang
  /// sudah tersimpan (supabase_flutter otomatis restore session-nya sendiri
  /// lewat local storage; kita hanya perlu re-fetch data profile).
  static Future<UserProfile?> restoreSessionProfile() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      currentUser = null;
      return null;
    }

    try {
      final result = await _client
          .from('user_profiles')
          .select('id, name, phone, email, created_at, updated_at')
          .eq('id', session.user.id)
          .maybeSingle();

      if (result == null) {
        currentUser = null;
        return null;
      }

      final userProfile = UserProfile.fromJson(result);
      currentUser = userProfile;
      return userProfile;
    } catch (_) {
      currentUser = null;
      return null;
    }
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
  }
}