import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/device_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'models/device_detail_data.dart';
import '../../core/services/ble_telemetry_service.dart';
import '../../features/dashboard/models/dashboard_models.dart';

const _kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

class DeviceDetailPage extends StatefulWidget {
  const DeviceDetailPage({
    required this.deviceId,
    this.isOnline = true,
    this.initialDeviceCode,
    super.key,
  });

  final String deviceId;
  final bool isOnline;
  final String? initialDeviceCode;

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  DeviceDetailData? _data;
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;
  bool _isBleConnecting = false;
  bool _isBleConnected = false;
  StreamSubscription? _bleTelemetrySub;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = DeviceService.subscribeToDeviceDetail(
      deviceId: widget.deviceId,
      onChange: _load,
    );


    _isBleConnected = BleTelemetryService.instance.isConnectedNotifier.value;
    BleTelemetryService.instance.isConnectedNotifier.addListener(_onBleConnectionChanged);
    _bleTelemetrySub = BleTelemetryService.instance.telemetryStream.listen(_onBleDataReceived);

    // ponytail: auto-refresh tiap 2 detik jika supabase realtime blm narik UI otomatis
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_isBleConnected) _load();
    });
  }

  void _onBleConnectionChanged() {
    if (mounted) {
      setState(() {
        _isBleConnected = BleTelemetryService.instance.isConnectedNotifier.value;
        if (!_isBleConnected) {
          _isBleConnecting = false; // Reset loading state if disconnected
        }
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    final channel = _channel;
    if (channel != null) {
      DeviceService.unsubscribeDeviceStatus(channel);
    }
    BleTelemetryService.instance.isConnectedNotifier.removeListener(_onBleConnectionChanged);
    _bleTelemetrySub?.cancel();
    super.dispose();
  }

  Future<void> _connectToBle() async {
    if (_isBleConnecting || _isBleConnected) return;

    setState(() {
      _isBleConnecting = true;
      _errorMessage = null;
    });

    try {
      // Prioritaskan deviceCode dari data Supabase, jika offline/null ambil dari parameter route
      final deviceCode = _data?.device.deviceCode ?? widget.initialDeviceCode;
      
      if (deviceCode == null) {
        throw Exception("Kode alat (TGN_XXXX) belum tersedia. Harap sinkronisasi internet sekali saja.");
      }
      
      await BleTelemetryService.instance.connect(deviceCode);

      if (mounted) {
        setState(() {
          _isBleConnecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil terhubung ke Bluetooth Telemetri!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBleConnecting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Koneksi BLE Gagal: $_errorMessage'),
            backgroundColor: AppColors.destructive,
          ),
        );
      }
    }
  }

  void _onBleDataReceived(Map<String, dynamic> bleData) {
    if (!mounted || _data == null) return;
    
    setState(() {
      // Data dari BLE (JSON format di ESP32 html_ui/ble_setup)
      // "battery": "100% (2183)", "water": 450, "lat": null, "lng": null, "gps_valid": false, "buzzer_manual": false
      
      final String batStr = bleData['battery']?.toString() ?? '0%';
      final batPercentStr = batStr.split('%').first;
      final int batPercent = int.tryParse(batPercentStr) ?? 0;
      
      final waterRaw = double.tryParse(bleData['water']?.toString() ?? '0') ?? 0;
      // Konversi RAW (1900 max) ke CM (maks 4.0 cm) seperti di ESP32
      double waterCm = (waterRaw / 1900.0) * 4.0;
      if (waterCm > 4.0) waterCm = 4.0;
      if (waterCm < 0.0) waterCm = 0.0;
      
      final bool isFlood = waterRaw > 50; // Threshold baru dari ESP32 config.h

      final bool gpsValid = bleData['gps_valid'] == true || bleData['gps_valid'] == 'true';
      final double? lat = gpsValid ? double.tryParse(bleData['lat']?.toString() ?? '') : null;
      final double? lng = gpsValid ? double.tryParse(bleData['lng']?.toString() ?? '') : null;
      

      final currentDevice = _data!.device;
      
      _data = DeviceDetailData(
        device: DeviceDetail(
          id: currentDevice.id,
          deviceCode: currentDevice.deviceCode,
          deviceName: currentDevice.deviceName,
          firmwareVersion: currentDevice.firmwareVersion,
          isActive: currentDevice.isActive,
          registeredAt: currentDevice.registeredAt,
          status: 'Bluetooth Connected',
          waterLevel: waterCm,
          batteryLevel: batPercent,
          signalStrength: -40, // Asumsi BLE kuat jika terkoneksi
          isFloodDetected: isFlood,
          lastSeenAt: DateTime.now(),
        ),
        location: gpsValid && lat != null && lng != null
            ? DeviceLocationInfo(
                latitude: lat,
                longitude: lng,
                accuracy: 10.0,
                recordedAt: DateTime.now(),
              )
            : _data!.location,
        activities: _data!.activities,
      );
    });
  }

  Future<void> _load() async {
    try {
      final data = await DeviceService.fetchDeviceDetail(widget.deviceId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat detail perangkat. Tarik untuk coba lagi.';
      });
    }
  }

  bool get _isConnected => _isBleConnected || (_data?.device.isConnected ?? widget.isOnline);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(textTheme),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (_data != null) ...[
                      _buildMapSection(textTheme, _data!),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMonitoringSection(textTheme, _data!),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDeviceInfo(textTheme, _data!),
                      const SizedBox(height: AppSpacing.lg),
                      _buildRecentActivity(textTheme, _data!),
                      const SizedBox(height: AppSpacing.lg),
                      _buildActions(context, textTheme),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildErrorBanner(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.destructive.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.destructive.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.alertTriangle, color: AppColors.destructive, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextTheme textTheme) {
    final subtitle = _data?.device.deviceCode ?? widget.deviceId;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: AppColors.primary,
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Detail Perangkat',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            subtitle,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.moreVertical),
          color: AppColors.mutedForeground,
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.border, height: 1.0),
      ),
    );
  }

  Widget _buildMapSection(TextTheme textTheme, DeviceDetailData data) {
    final device = data.device;
    final location = data.location;
    final isConnected = _isConnected;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: location != null
                ? _buildMap(location)
                : _buildMapPlaceholder(textTheme),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      'ID: ${device.deviceCode}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? AppColors.success : AppColors.destructive,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isConnected ? const Color(0x8010B981) : const Color(0x80EF4444),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isBleConnected ? 'Terhubung (BLE)' : (isConnected ? 'Terhubung' : 'Offline'),
                      style: textTheme.labelSmall?.copyWith(
                        color: isConnected ? AppColors.success : AppColors.destructive,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(DeviceLocationInfo location) {
    final point = latlong.LatLng(location.latitude.toDouble(), location.longitude.toDouble());

    return FlutterMap(
      options: MapOptions(
        initialCenter: point,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.tagana_app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: point,
              width: 40,
              height: 40,
              child: Icon(LucideIcons.mapPin, color: AppColors.primary, size: 40),
            ),
          ],
        ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(TextTheme textTheme) {
    return Container(
      color: AppColors.muted,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.mapPin, color: AppColors.mutedForeground, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Belum ada data lokasi',
              style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringSection(TextTheme textTheme, DeviceDetailData data) {
    final device = data.device;

    final waterValue = device.waterLevel != null
        ? device.waterLevel!.toStringAsFixed(1)
        : '-';
    final waterStatus = device.isFloodDetected
        ? 'Banjir Terdeteksi'
        : (device.waterLevel != null ? 'Aman' : 'Tidak ada data');
    final waterStatusColor = device.isFloodDetected ? AppColors.destructive : AppColors.success;

    final battery = device.batteryLevel?.round();
    final batteryStatus = battery == null
        ? 'Tidak ada data'
        : battery > 80
            ? 'Optimal'
            : battery > 30
                ? 'Sedang'
                : 'Rendah';
    final batteryStatusColor = battery == null
        ? AppColors.mutedForeground
        : battery > 80
            ? AppColors.mutedForeground
            : battery > 30
                ? AppColors.warning
                : AppColors.destructive;

    final signal = device.signalStrength;
    final signalStatus = signal == null
        ? 'Tidak ada data'
        : signal > -70
            ? 'Kuat'
            : signal > -90
                ? 'Sedang'
                : 'Lemah';

    final location = data.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Monitoring Aktif',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.droplets,
              label: 'Water Lvl',
              value: waterValue,
              unit: device.waterLevel != null ? 'cm' : null,
              status: waterStatus,
              statusColor: waterStatusColor,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withOpacity(0.1),
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.batteryFull,
              label: 'Baterai',
              value: battery != null ? '$battery' : '-',
              unit: battery != null ? '%' : null,
              status: batteryStatus,
              statusColor: batteryStatusColor,
              iconColor: AppColors.mutedForeground,
              iconBgColor: AppColors.muted,
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.signal,
              label: 'Sinyal',
              value: signal != null ? '$signal' : '-',
              unit: signal != null ? 'dBm' : null,
              status: signalStatus,
              statusColor: AppColors.mutedForeground,
              iconColor: Colors.indigo,
              iconBgColor: Colors.indigo.shade50,
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.compass,
              label: 'Koordinat',
              value: location != null ? 'Lat: ${location.latitude.toStringAsFixed(4)}' : '-',
              status: location != null ? 'Long: ${location.longitude.toStringAsFixed(4)}' : 'Belum ada data',
              statusColor: AppColors.foreground,
              iconColor: AppColors.destructive,
              iconBgColor: AppColors.destructive.withOpacity(0.1),
              isCoordinate: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitorCard(
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required String value,
    String? unit,
    required String status,
    required Color statusColor,
    required Color iconColor,
    required Color iconBgColor,
    bool isCoordinate = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          if (isCoordinate) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
                ),
                Text(
                  status,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                    children: [
                      TextSpan(text: value),
                      if (unit != null)
                        TextSpan(
                          text: unit,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
                ),
                Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(color: statusColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day} ${_kMonths[d.month - 1]} ${d.year}';

  Future<void> _openMaps(DeviceLocationInfo location) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDeviceInfo(TextTheme textTheme, DeviceDetailData data) {
    final device = data.device;
    final location = data.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Informasi Perangkat',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(textTheme, 'Kode Perangkat', device.deviceCode),
              const Divider(height: 1),
              _buildInfoRow(textTheme, 'Versi Firmware', device.firmwareVersion ?? '-'),
              const Divider(height: 1),
              _buildInfoRow(textTheme, 'Tanggal Instalasi', _formatDate(device.registeredAt)),
              const Divider(height: 1),
              _buildInfoRow(
                textTheme,
                'Lokasi',
                location != null
                    ? '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'
                    : 'Belum ada data',
                isLink: location != null,
                onTap: location != null ? () => _openMaps(location) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    TextTheme textTheme,
    String label,
    String value, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
            ),
            if (isLink)
              Row(
                children: [
                  Text(
                    value,
                    style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
                ],
              )
            else
              Text(
                value,
                style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
              ),
          ],
        ),
      ),
    );
  }

  String _formatActivityTime(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday =
        dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Hari ini, $hm';
    if (isYesterday) return 'Kemarin, $hm';
    return '${dt.day} ${_kMonths[dt.month - 1]}, $hm';
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'device_connected':
      case 'wifi_connected':
        return LucideIcons.wifi;
      case 'device_disconnected':
      case 'wifi_disconnected':
      case 'ble_disconnected':
        return LucideIcons.wifiOff;
      case 'wifi_configured':
      case 'ble_connected':
        return LucideIcons.settings;
      case 'data_sync':
        return LucideIcons.refreshCw;
      case 'network_reset':
        return LucideIcons.refreshCw;
      case 'emergency_mode':
        return LucideIcons.alertTriangle;
      case 'device_registered':
      case 'firmware_updated':
      default:
        return LucideIcons.activity;
    }
  }

  Widget _buildRecentActivity(TextTheme textTheme, DeviceDetailData data) {
    final activities = data.activities;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Aktivitas',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              if (activities.length > 2)
                TextButton(
                  onPressed: () {},
                  child: const Text('Lihat Semua'),
                ),
            ],
          ),
        ),
        if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Belum ada aktivitas tercatat.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
            ),
          )
        else
          for (var i = 0; i < activities.length && i < 2; i++) ...[
            _buildActivityItem(
              textTheme,
              icon: _activityIcon(activities[i].type),
              title: activities[i].title,
              description: activities[i].description ?? '-',
              time: _formatActivityTime(activities[i].createdAt),
              isPrimary: i == 0,
            ),
            if (i == 0) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }

  Widget _buildActivityItem(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String description,
    required String time,
    bool isPrimary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary.withOpacity(0.1) : AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.primary : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, TextTheme textTheme) {
    final isConnected = _isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isConnected) ..._buildOfflineBanner(context, textTheme),
        
        // [PONYTAIL FIX]: Tombol Bluetooth SELALU DIMUNCULKAN di luar banner offline.
        // Karena meskipun status Supabase masih nyangkut di "Online", pengguna harus tetap bisa 
        // membajak koneksinya lewat Bluetooth kapan saja mereka mau (Mode Taktis Instan).
        if (!_isBleConnected)
          ElevatedButton.icon(
            onPressed: _isBleConnecting ? null : _connectToBle,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isBleConnecting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(LucideIcons.bluetooth, size: 18),
            label: Text(
              _isBleConnecting ? 'Mencari Perangkat...' : 'Hubungkan Bluetooth (Mode Taktis)',
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          ),
        if (!_isBleConnected) const SizedBox(height: AppSpacing.sm),

        // [PONYTAIL FIX]: Selalu tampilkan tombol setting Wi-Fi.
        // Konfigurasi Wi-Fi dikirim via Bluetooth, jadi tombol ini harus selalu ada.
        ElevatedButton.icon(
          onPressed: () => context.push('/device/${widget.deviceId}/wifi-config'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary, // Ganti warna agar tidak terlalu merah/destruktif
            foregroundColor: AppColors.secondaryForeground,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(LucideIcons.wifi, size: 18),
          label: const Text('Pengaturan Wi-Fi (via BLE)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildEmergencyBtn(context),
        const SizedBox(height: AppSpacing.sm),
        _buildTestConnectionBtn(context),
        const SizedBox(height: AppSpacing.sm),
        _buildCalibrateBtn(),
      ],
    );
  }

  List<Widget> _buildOfflineBanner(BuildContext context, TextTheme textTheme) {
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: AppColors.destructive, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perangkat Offline',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Perangkat belum terhubung ke internet.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.destructive.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
    ];
  }

  Widget _buildEmergencyBtn(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/device/${widget.deviceId}/emergency'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.destructive,
        foregroundColor: AppColors.destructiveForeground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.alertTriangle, size: 18),
      label: const Text('Mode Darurat', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTestConnectionBtn(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/device/${widget.deviceId}/test-connection'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.radio, size: 18),
      label: const Text('Uji Koneksi', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCalibrateBtn() {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade50,
        foregroundColor: Colors.indigo.shade900,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.sliders, size: 18),
      label: const Text('Kalibrasi', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}