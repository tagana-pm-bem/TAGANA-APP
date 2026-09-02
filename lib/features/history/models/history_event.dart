enum HistorySource { alert, activity }

/// Representasi satu kejadian di timeline Riwayat — bisa berasal dari
/// tabel `alerts` atau `device_activities`, disatukan supaya bisa
/// ditampilkan dalam satu timeline yang sama.
class HistoryEvent {
  final String id;
  final HistorySource source;
  final String type;
  final String? severity; // hanya untuk alert: info | warning | critical
  final String title;
  final String? description;
  final DateTime occurredAt;
  final String? deviceCode;
  final String? deviceName;

  const HistoryEvent({
    required this.id,
    required this.source,
    required this.type,
    this.severity,
    required this.title,
    this.description,
    required this.occurredAt,
    this.deviceCode,
    this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source.name,
      'type': type,
      'severity': severity,
      'title': title,
      'description': description,
      'occurred_at': occurredAt.toIso8601String(),
      'device_code': deviceCode,
      'device_name': deviceName,
    };
  }

  factory HistoryEvent.fromJson(Map<String, dynamic> json) {
    return HistoryEvent(
      id: json['id'] as String,
      source: HistorySource.values.firstWhere((e) => e.name == json['source']),
      type: json['type'] as String,
      severity: json['severity'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      deviceCode: json['device_code'] as String?,
      deviceName: json['device_name'] as String?,
    );
  }

  /// Kategori untuk filter tampilan: peringatan | kritis | perangkat | sistem
  String get category {
    if (source == HistorySource.alert) {
      switch (severity) {
        case 'critical':
          return 'kritis';
        case 'warning':
          return 'peringatan';
        default:
          return 'sistem';
      }
    }
    switch (type) {
      case 'network_reset':
      case 'firmware_updated':
        return 'sistem';
      case 'emergency_mode':
        return 'kritis';
      default:
        return 'perangkat';
    }
  }

  static Map<String, dynamic>? _deviceJson(dynamic raw) {
    if (raw is List) {
      return raw.isNotEmpty ? raw.first as Map<String, dynamic> : null;
    }
    return raw as Map<String, dynamic>?;
  }

  factory HistoryEvent.fromAlertJson(Map<String, dynamic> json) {
    final deviceJson = _deviceJson(json['devices']);

    return HistoryEvent(
      id: json['id'] as String,
      source: HistorySource.alert,
      type: json['type'] as String,
      severity: json['severity'] as String?,
      title: _alertTitle(json['type'] as String),
      description: json['message'] as String?,
      occurredAt: DateTime.parse(json['triggered_at'] as String),
      deviceCode: deviceJson?['device_code'] as String?,
      deviceName: deviceJson?['device_name'] as String?,
    );
  }

  factory HistoryEvent.fromActivityJson(Map<String, dynamic> json) {
    final deviceJson = _deviceJson(json['devices']);

    return HistoryEvent(
      id: json['id'] as String,
      source: HistorySource.activity,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      occurredAt: DateTime.parse(json['created_at'] as String),
      deviceCode: deviceJson?['device_code'] as String?,
      deviceName: deviceJson?['device_name'] as String?,
    );
  }

  static String _alertTitle(String type) {
    switch (type) {
      case 'high_water_level':
        return 'Ketinggian Air Tinggi';
      case 'flood_detected':
        return 'Banjir Terdeteksi';
      case 'low_battery':
        return 'Baterai Rendah';
      case 'device_offline':
        return 'Perangkat Offline';
      case 'connection_lost':
        return 'Koneksi Terputus';
      default:
        return 'Peringatan Perangkat';
    }
  }
}