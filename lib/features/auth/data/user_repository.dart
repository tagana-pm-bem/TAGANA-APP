import 'dart:io';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/device_alert_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/local_offline_detection_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/error_handler_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();

  static final _client = SupabaseClientService.client;
  static UserProfile? currentUser;

  static Future<void> _saveFcmTokenInBackground() async {
    try {
      final token = await PushNotificationService.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      await updateFcmToken(token);
    } catch (_) {
      // no-op: token hanya disimpan jika user sudah login dan permission tersedia
    }
  }

  static Future<UserProfile> register({
    required String name,
    required String phone,
  }) async {
    try {
      final res = await _client.functions.invoke(
        'register-user',
        body: {'name': name.trim(), 'phone': phone.trim()},
      );

      final data = res.data;
      if (data == null || data['success'] != true || data['user'] == null) {
        throw Exception(data?['message'] ?? 'Gagal membuat akun');
      }

      await _establishSession(data['auth'] as Map<String, dynamic>?);

      final userProfile = UserProfile.fromJson(data['user']);
      currentUser = userProfile;
      await _cacheProfile(userProfile);
      _saveFcmTokenInBackground();
      DeviceAlertService.instance.startMonitoring();
      return userProfile;
    } catch (e) {
      await ErrorHandlerService.instance.handleDatabaseError(
        e,
        operation: 'Register',
      );
      rethrow;
    }
  }

  static Future<UserProfile?> login({required String phone}) async {
    try {
      final res = await _client.functions.invoke(
        'login-user',
        body: {'phone': phone.trim()},
      );

      final data = res.data;
      if (data == null || data['success'] != true || data['user'] == null) {
        return null;
      }

      await _establishSession(data['auth'] as Map<String, dynamic>?);

      final userProfile = UserProfile.fromJson(data['user']);
      currentUser = userProfile;
      await _cacheProfile(userProfile);

      // Simpan FCM token setelah login berhasil
      _saveFcmTokenInBackground();
      DeviceAlertService.instance.startMonitoring();

      return userProfile;
    } on Exception catch (e) {
      await ErrorHandlerService.instance.handleDatabaseError(
        e,
        operation: 'Login',
      );
      return null;
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

    await _client.auth.verifyOTP(type: OtpType.magiclink, tokenHash: tokenHash);
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
          .select(
            'id, name, phone, email, avatar_url, fcm_token, created_at, updated_at',
          )
          .eq('id', session.user.id)
          .maybeSingle();

      if (result == null) {
        currentUser = null;
        return null;
      }

      final userProfile = UserProfile.fromJson(result);
      currentUser = userProfile;
      await _cacheProfile(userProfile);
      _saveFcmTokenInBackground();
      DeviceAlertService.instance.startMonitoring();
      return userProfile;
    } catch (e) {
      // Jika offline, gagal mengambil dari server. Coba ambil dari local storage.
      // Jangan tampilkan error ke user di sini, karena mereka mungkin offline
      return await _loadCachedProfile();
    }
  }

  static Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_user_profile',
        jsonEncode(profile.toJson()),
      );
    } catch (_) {}
  }

  static Future<UserProfile?> _loadCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('cached_user_profile');
      if (str != null) {
        final userProfile = UserProfile.fromJson(jsonDecode(str));
        currentUser = userProfile;
        return userProfile;
      }
    } catch (_) {}
    currentUser = null;
    return null;
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
    currentUser = null;
    await DeviceAlertService.instance.stopMonitoring();
    await LocalOfflineDetectionService.instance.stopMonitoring();
    await ConnectivityService.instance.stopMonitoring();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
  }

  static Future<String?> uploadAvatar(String filePath, String fileName) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final file = await _client.storage
          .from('avatars')
          .upload(
            '$userId/$fileName',
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      // get public url
      return _client.storage.from('avatars').getPublicUrl('$userId/$fileName');
    } catch (e) {
      await ErrorHandlerService.instance.handleDatabaseError(
        e,
        operation: 'Upload Avatar',
      );
      return null;
    }
  }

  static Future<UserProfile> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    try {
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
      await _cacheProfile(userProfile);
      return userProfile;
    } catch (e) {
      await ErrorHandlerService.instance.handleDatabaseError(
        e,
        operation: 'Update Profile',
      );
      rethrow;
    }
  }

  static Future<void> updateFcmToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      print('[FCM] Skipping token update — user not logged in');
      return;
    }

    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      print('[FCM] Skipping token update — token empty');
      return;
    }

    // Retry with exponential backoff for transient failures.
    const int maxAttempts = 4;
    int attempt = 0;
    int delayMs = 500;

    while (attempt < maxAttempts) {
      try {
        await _client.from('user_profiles').upsert({
          'id': userId,
          'fcm_token': normalizedToken,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'id');
        print('[FCM] Token saved successfully for user $userId');
        return;
      } catch (e) {
        attempt++;
        print('[FCM] Failed to save FCM token (attempt $attempt): $e');
        if (attempt >= maxAttempts) {
          print('[FCM] Giving up after $attempt attempts');
          await ErrorHandlerService.instance.handleDatabaseError(
            e,
            operation: 'Save FCM Token',
          );
          return;
        }
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
  }
}
