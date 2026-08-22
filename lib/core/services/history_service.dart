import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';
import '../../features/history/models/history_event.dart';

class HistoryService {
  HistoryService._();

  static SupabaseClient get _client => SupabaseClientService.client;

  /// Ambil gabungan alert + activity sejak [since], milik semua perangkat
  /// user yang login (RLS otomatis membatasi ke device milik auth.uid()).
  /// Hasil sudah diurutkan terbaru dulu.
  static Future<List<HistoryEvent>> fetchHistory({required DateTime since}) async {
    final sinceIso = since.toIso8601String();

    final alertsRaw = await _client
        .from('alerts')
        .select('''
          id,
          type,
          severity,
          status,
          message,
          triggered_at,
          devices ( device_code, device_name )
        ''')
        .gte('triggered_at', sinceIso)
        .order('triggered_at', ascending: false);

    final activitiesRaw = await _client
        .from('device_activities')
        .select('''
          id,
          type,
          title,
          description,
          created_at,
          devices ( device_code, device_name )
        ''')
        .gte('created_at', sinceIso)
        .order('created_at', ascending: false);

    final events = <HistoryEvent>[
      ...(alertsRaw as List)
          .map((e) => HistoryEvent.fromAlertJson(e as Map<String, dynamic>)),
      ...(activitiesRaw as List)
          .map((e) => HistoryEvent.fromActivityJson(e as Map<String, dynamic>)),
    ];

    events.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return events;
  }

  /// Subscribe realtime ke perubahan alerts & device_activities, dipakai
  /// halaman Riwayat supaya timeline auto-update.
  static RealtimeChannel subscribe({required void Function() onChange}) {
    final channel = _client
        .channel('history-page')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alerts',
          callback: (payload) => onChange(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'device_activities',
          callback: (payload) => onChange(),
        )
        .subscribe();

    return channel;
  }

  static Future<void> unsubscribe(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}