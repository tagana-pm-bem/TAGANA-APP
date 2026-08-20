import 'package:flutter/material.dart';

import 'app.dart';
import 'core/supabase/supabase_client.dart';
import 'core/supabase/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseConfig.load();
  await SupabaseClientService.initialize();

  runApp(const TaganaApp());
}