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
      
      final userProfile = UserProfile.fromJson(data['user']);
      currentUser = userProfile;
      return userProfile;
    } catch (e) {
      return null;
    }
  }
}