import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static const String envFile = '.env';

  static Future<void> load() async {
    await dotenv.load(fileName: envFile);

    _validate();
  }

  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static void _validate() {
    if (url.isEmpty) {
      throw Exception(
        'SUPABASE_URL is not configured in $envFile',
      );
    }

    if (anonKey.isEmpty) {
      throw Exception(
        'SUPABASE_ANON_KEY is not configured in $envFile',
      );
    }
  }
}