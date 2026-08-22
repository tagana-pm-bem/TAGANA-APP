class DeviceDetail {
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

  const DeviceDetail({
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

  bool get isConnected =>
      status == 'online' || status == 'warning' || status == 'critical';

  factory DeviceDetail.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['device_status'];
    final Map<String, dynamic>? statusJson = rawStatus is List
        ? (rawStatus.isNotEmpty ? rawStatus.first as Map<String, dynamic> : null)
        : rawStatus as Map<String, dynamic>?;

    return DeviceDetail(
      id: json['id'] as String,
      deviceCode: json['device_code'] as String,
      deviceName: json['device_name'] as String,
      firmwareVersion: json['firmware_version'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      status: statusJson?['status'] as String?,
      waterLevel: statusJson?['water_level'] as num?,
      batteryLevel: statusJson?['battery_level'] as num?,
      signalStrength: statusJson?['signal_strength'] as int?,
      isFloodDetected: statusJson?['is_flood_detected'] as bool? ?? false,
      lastSeenAt: statusJson?['last_seen_at'] != null
          ? DateTime.parse(statusJson!['last_seen_at'] as String)
          : null,
    );
  }
}

class DeviceLocationInfo {
  final num latitude;
  final num longitude;
  final num? accuracy;
  final DateTime recordedAt;

  const DeviceLocationInfo({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.recordedAt,
  });

  factory DeviceLocationInfo.fromJson(Map<String, dynamic> json) {
    return DeviceLocationInfo(
      latitude: json['latitude'] as num,
      longitude: json['longitude'] as num,
      accuracy: json['accuracy'] as num?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }
}

class DeviceActivity {
  final String id;
  final String type;
  final String title;
  final String? description;
  final DateTime createdAt;

  const DeviceActivity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory DeviceActivity.fromJson(Map<String, dynamic> json) {
    return DeviceActivity(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class DeviceDetailData {
  final DeviceDetail device;
  final DeviceLocationInfo? location;
  final List<DeviceActivity> activities;

  const DeviceDetailData({
    required this.device,
    this.location,
    required this.activities,
  });
}