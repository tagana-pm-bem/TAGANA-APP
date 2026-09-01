class DeviceWithStatus {
  final String id;
  final String deviceCode;
  final String deviceName;
  final String? firmwareVersion;
  final bool isActive;
  final DateTime registeredAt;

  final String? status; // online | offline | warning | critical
  final num? waterLevel;
  final num? batteryLevel;
  final int? signalStrength;
  final bool isFloodDetected;
  final DateTime? lastSeenAt;

  const DeviceWithStatus({
    required this.id,
    required this.deviceCode,
    required this.deviceName,
    this.firmwareVersion,
    required this.isActive,
    required this.registeredAt,
    this.status,
    this.waterLevel,
    this.batteryLevel,
    this.signalStrength,
    this.isFloodDetected = false,
    this.lastSeenAt,
  });

  bool get isConnected {
    // Timeout 6 menit seperti di DeviceDetail
    if (lastSeenAt != null) {
      final difference = DateTime.now().toUtc().difference(lastSeenAt!.toUtc());
      if (difference.inMinutes > 35) return false;
    }
    return status == 'online' || status == 'warning' || status == 'critical';
  }

  factory DeviceWithStatus.fromJson(Map<String, dynamic> json) {
    // device_status bisa balik sebagai object atau list-of-1 tergantung
    // bentuk join/select yang dipakai.
    final rawStatus = json['device_status'];
    final Map<String, dynamic>? statusJson = rawStatus is List
        ? (rawStatus.isNotEmpty ? rawStatus.first as Map<String, dynamic> : null)
        : rawStatus as Map<String, dynamic>?;

    return DeviceWithStatus(
      id: json['id'] as String,
      deviceCode: json['device_code'] as String,
      deviceName: json['device_name'] as String,
      firmwareVersion: json['firmware_version'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      status: statusJson?['status'] as String?,
      waterLevel: _parseNum(statusJson?['water_level']),
      batteryLevel: _parseNum(statusJson?['battery_level']),
      signalStrength: _parseInt(statusJson?['signal_strength']),
      isFloodDetected: statusJson?['is_flood_detected'] as bool? ?? false,
      lastSeenAt: statusJson?['last_seen_at'] != null
          ? DateTime.parse(statusJson!['last_seen_at'] as String)
          : null,
    );
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class AlertSummary {
  final String id;
  final String type;
  final String severity; // info | warning | critical
  final String status; // active | resolved
  final num? value;
  final num? threshold;
  final String message;
  final DateTime triggeredAt;
  final String? deviceCode;
  final String? deviceName;

  const AlertSummary({
    required this.id,
    required this.type,
    required this.severity,
    required this.status,
    this.value,
    this.threshold,
    required this.message,
    required this.triggeredAt,
    this.deviceCode,
    this.deviceName,
  });

  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    final rawDevice = json['devices'];
    final Map<String, dynamic>? deviceJson = rawDevice is List
        ? (rawDevice.isNotEmpty ? rawDevice.first as Map<String, dynamic> : null)
        : rawDevice as Map<String, dynamic>?;

    return AlertSummary(
      id: json['id'] as String,
      type: json['type'] as String,
      severity: json['severity'] as String,
      status: json['status'] as String,
      value: DeviceWithStatus._parseNum(json['value']),
      threshold: DeviceWithStatus._parseNum(json['threshold']),
      message: json['message'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      deviceCode: deviceJson?['device_code'] as String?,
      deviceName: deviceJson?['device_name'] as String?,
    );
  }
}

class DashboardData {
  final List<DeviceWithStatus> devices;
  final List<AlertSummary> alerts;

  const DashboardData({required this.devices, required this.alerts});

  int get totalDevices => devices.length;
  int get connectedDevices => devices.where((d) => d.isConnected).length;
  int get activeAlertsCount => alerts.where((a) => a.status == 'active').length;
  bool get hasCriticalAlert =>
      alerts.any((a) => a.status == 'active' && a.severity == 'critical');
  String get systemCondition => hasCriticalAlert ? 'Kritis' : 'Stabil';

  static const empty = DashboardData(devices: [], alerts: []);
}