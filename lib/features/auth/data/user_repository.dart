import 'dart:io';
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
          .select('id, name, phone, email, avatar_url, fcm_token, created_at, updated_at')
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

  static Future<String?> uploadAvatar(String filePath, String fileName) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final file = await _client.storage.from('avatars').upload(
          '$userId/$fileName',
          File(filePath),
          fileOptions: const FileOptions(upsert: true),
        );
    
    // get public url
    return _client.storage.from('avatars').getPublicUrl('$userId/$fileName');
  }
  
  static Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final response = await _client
        .from('user_profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    final userProfile = UserProfile.fromJson(response);
    currentUser = userProfile;
    return userProfile;
  }

  static Future<void> updateFcmToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('[FCM] Skipping token update — user not logged in');
      return;
    }

    try {
      await _client
          .from('user_profiles')
          .update({'fcm_token': token, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);
      print('[FCM] Token saved successfully for user $userId');
    } catch (e) {
      print('[FCM] Failed to save FCM token: $e');
    }
  }
}