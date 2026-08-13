import 'package:flutter/material.dart';

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({
    required this.deviceId,
    super.key,
  });

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Device: $deviceId'),
      ),
    );
  }
}