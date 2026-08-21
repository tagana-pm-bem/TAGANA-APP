import '../../../core/supabase/supabase_client.dart';
import '../models/user_profile.dart';

class UserRepository {
  UserRepository._();

  static final _client = SupabaseClientService.client;

  static Future<UserProfile> register({
    required String name,
    required String phone,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    try {
      await _client.functions.invoke(
        'register-user',
        body: {
          'name': name.trim(),
          'phone': normalizedPhone,
        },
      );
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('phone', normalizedPhone)
        .maybeSingle();

    if (response == null) {
      throw Exception('Gagal mendapatkan profil pengguna.');
    }

    return UserProfile.fromJson(response);
  }

  static Future<UserProfile?> login({
    required String phone,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    final response = await _client
        .from('user_profiles')
        .select()
        .eq('phone', normalizedPhone)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return UserProfile.fromJson(response);
  }

  static String _normalizePhone(String phone) {
    var value = phone.trim();

    if (value.startsWith('+62')) {
      return value;
    }

    if (value.startsWith('62')) {
      return '+$value';
    }

    if (value.startsWith('0')) {
      return '+62${value.substring(1)}';
    }

    throw const FormatException(
      'Format nomor telepon tidak valid.',
    );
  }
}