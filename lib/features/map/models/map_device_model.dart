class MapDeviceModel {
  final String id;
  final String deviceCode;
  final String deviceName;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  MapDeviceModel({
    required this.id,
    required this.deviceCode,
    required this.deviceName,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory MapDeviceModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['device_status'];
    final statusJson = rawStatus is List
        ? (rawStatus.isNotEmpty ? rawStatus.first as Map<String, dynamic> : null)
        : rawStatus as Map<String, dynamic>?;

    final status = statusJson?['status'] as String? ?? 'offline';

    final rawLocation = json['device_locations'];
    final locationJson = rawLocation is List
        ? (rawLocation.isNotEmpty ? rawLocation.first as Map<String, dynamic> : null)
        : rawLocation as Map<String, dynamic>?;

    return MapDeviceModel(
      id: json['id'] as String,
      deviceCode: json['device_code'] as String,
      deviceName: json['device_name'] as String,
      status: status,
      latitude: (locationJson?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (locationJson?['longitude'] as num?)?.toDouble() ?? 0.0,
      recordedAt: locationJson?['recorded_at'] != null 
          ? DateTime.parse(locationJson!['recorded_at'])
          : DateTime.now(),
    );
  }
}
