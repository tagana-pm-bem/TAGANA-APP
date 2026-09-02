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

  bool get isConnected {
    // Karena ESP32 mengirim HTTP POST secara stateless, server tidak tahu saat Wi-Fi putus mendadak.
    // Jika tidak ada kabar selama lebih dari 6 menit (karena interval normal 5 menit), anggap Offline.
    if (lastSeenAt != null) {
      final difference = DateTime.now().toUtc().difference(lastSeenAt!.toUtc());
      if (difference.inMinutes > 6) return false;
    }
    return status == 'online' || status == 'warning' || status == 'critical';
  }

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
      waterLevel: _parseNum(statusJson?['water_level']),
      batteryLevel: _parseNum(statusJson?['battery_level']),
      signalStrength: _parseInt(statusJson?['signal_strength']),
      isFloodDetected: statusJson?['is_flood_detected'] as bool? ?? false,
      lastSeenAt: statusJson?['last_seen_at'] != null
          ? DateTime.parse(statusJson!['last_seen_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device_code': deviceCode,
      'device_name': deviceName,
      'firmware_version': firmwareVersion,
      'is_active': isActive,
      'registered_at': registeredAt.toIso8601String(),
      'device_status': [{
        'status': status,
        'water_level': waterLevel,
        'battery_level': batteryLevel,
        'signal_strength': signalStrength,
        'is_flood_detected': isFloodDetected,
        'last_seen_at': lastSeenAt?.toIso8601String(),
      }],
    };
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
      latitude: DeviceDetail._parseNum(json['latitude']) ?? 0,
      longitude: DeviceDetail._parseNum(json['longitude']) ?? 0,
      accuracy: DeviceDetail._parseNum(json['accuracy']),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'recorded_at': recordedAt.toIso8601String(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
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

  factory DeviceDetailData.fromJson(Map<String, dynamic> json) {
    return DeviceDetailData(
      device: DeviceDetail.fromJson(json['device'] as Map<String, dynamic>),
      location: json['location'] != null ? DeviceLocationInfo.fromJson(json['location'] as Map<String, dynamic>) : null,
      activities: (json['activities'] as List).map((e) => DeviceActivity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device': device.toJson(),
      'location': location?.toJson(),
      'activities': activities.map((e) => e.toJson()).toList(),
    };
  }
}