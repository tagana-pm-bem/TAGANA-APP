import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/ble_telemetry_service.dart';
import '../../core/services/device_service.dart';
import 'models/device_detail_data.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({
    required this.deviceId,
    super.key,
  });

  final String deviceId;

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  bool _isBuzzerOn = false;
  DeviceDetailData? _deviceData;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
    _channel = DeviceService.subscribeToDeviceDetail(
      deviceId: widget.deviceId,
      onChange: _loadDeviceData,
    );
  }

  Future<void> _loadDeviceData() async {
    try {
      final data = await DeviceService.fetchDeviceDetail(widget.deviceId);
      if (mounted) {
        setState(() {
          _deviceData = data;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      DeviceService.unsubscribeDeviceStatus(channel);
    }
    super.dispose();
  }

  void _toggleBuzzer() {
    if (!BleTelemetryService.instance.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bluetooth belum terhubung!')),
      );
      return;
    }

    setState(() {
      _isBuzzerOn = !_isBuzzerOn;
    });

    try {
      BleTelemetryService.instance.sendRawCommand('BUZZER');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBuzzerOn ? 'Buzzer Dinyalakan' : 'Buzzer Dimatikan')),
      );
    } catch (e) {
      setState(() => _isBuzzerOn = !_isBuzzerOn); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim perintah: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: BleTelemetryService.instance.telemetryStream,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final waterRaw = double.tryParse(data?['water']?.toString() ?? '0') ?? 0;
          final isFlood = waterRaw > 50; 
          
          bool isInternetConnected;
          if (BleTelemetryService.instance.isConnected && data != null) {
            final wifiSSID = data['ssid']?.toString();
            isInternetConnected = wifiSSID != null && wifiSSID.isNotEmpty && wifiSSID != 'Unknown';
          } else {
            isInternetConnected = _deviceData?.device.isConnected ?? false;
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEmergencyStatusCard(textTheme, isFlood, data),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPenyebabSection(textTheme, isFlood, isInternetConnected),
                    const SizedBox(height: AppSpacing.lg),
                    _buildKomunikasiDaruratSection(context, textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatusDataBLESection(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDataEmergencySummary(textTheme, isFlood, isInternetConnected, data),
                  ],
                ),
              ),
              // Positioned(
              //   bottom: 0,
              //   left: 0,
              //   right: 0,
              //   child: _buildFooter(textTheme),
              // ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: AppColors.foreground,
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Mode',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            widget.deviceId,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.border, height: 1.0),
      ),
    );
  }

  Widget _buildEmergencyStatusCard(TextTheme textTheme, bool isFlood, Map<String, dynamic>? data) {
    final timeStr = data != null 
        ? "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}"
        : "--:--";

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isFlood ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFlood ? AppColors.destructive.withOpacity(0.2) : AppColors.success.withOpacity(0.2),
        ),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isFlood ? LucideIcons.alertOctagon : LucideIcons.checkCircle2,
                color: isFlood ? AppColors.destructive : AppColors.success,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFlood ? 'Emergency Mode Aktif' : 'Status Perangkat Normal',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isFlood ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFlood 
                          ? 'Perangkat mendeteksi kondisi darurat air.' 
                          : 'Tidak ada tanda-tanda bahaya terdeteksi.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isFlood ? Colors.red.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pemicu:',
                      style: textTheme.labelMedium?.copyWith(
                        color: isFlood ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      isFlood ? 'Water Sensor mendeteksi air' : 'Aman (Normal)',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isFlood ? Colors.red.shade900 : Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Penerimaan Terakhir:',
                      style: textTheme.labelMedium?.copyWith(
                        color: isFlood ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                    Text(
                      data != null ? timeStr : 'Menunggu data...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: isFlood ? Colors.red.shade900 : Colors.green.shade900,
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

  Widget _buildPenyebabSection(TextTheme textTheme, bool isFlood, bool isInternetConnected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Analisis Penyebab',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        Container(
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
            children: [
              Text(
                isFlood
                    ? 'Perangkat mendeteksi adanya ketinggian air melampaui batas aman.'
                    : 'Semua sensor berfungsi normal dan berada dalam batas aman.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 600
                      ? Row(
                          children: [
                            Expanded(child: _buildCauseItem(textTheme, 'Water Sensor', isFlood ? 'Air terdeteksi' : 'Normal', LucideIcons.droplet, isFlood)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildCauseItem(textTheme, 'Koneksi Wi-Fi', isInternetConnected ? 'Terhubung' : 'Tidak tersedia', LucideIcons.wifi, !isInternetConnected)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCauseItem(textTheme, 'Water Sensor', isFlood ? 'Air terdeteksi' : 'Normal', LucideIcons.droplet, isFlood),
                            const SizedBox(height: AppSpacing.md),
                            _buildCauseItem(textTheme, 'Koneksi Wi-Fi', isInternetConnected ? 'Terhubung' : 'Tidak tersedia', LucideIcons.wifi, !isInternetConnected),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCauseItem(TextTheme textTheme, String title, String subtitle, IconData icon, bool isAlert) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: isAlert ? AppColors.destructive : AppColors.success, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelMedium?.copyWith(color: AppColors.mutedForeground),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isAlert ? AppColors.destructive : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKomunikasiDaruratSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Komunikasi Darurat',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth > 600
                ? Row(
                    children: [
                      Expanded(child: _buildBLECard(context, textTheme)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _buildHotspotCard(context, textTheme)),
                    ],
                  )
                : Column(
                    children: [
                      _buildBLECard(context, textTheme),
                      const SizedBox(height: AppSpacing.md),
                      _buildHotspotCard(context, textTheme),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildBLECard(BuildContext context, TextTheme textTheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: BleTelemetryService.instance.isConnectedNotifier,
      builder: (context, isBleConnected, child) {
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Low Energy',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isBleConnected ? AppColors.success.withOpacity(0.1) : AppColors.destructive.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isBleConnected ? AppColors.success : AppColors.destructive,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isBleConnected ? 'Aktif' : 'Terputus',
                          style: textTheme.labelSmall?.copyWith(
                            color: isBleConnected ? AppColors.success : AppColors.destructive
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Perangkat mengirimkan data real-time langsung ke aplikasi melalui Bluetooth.',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isBleConnected ? null : () => context.push('/device/${widget.deviceId}/ble?returnTo=emergency'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBleConnected ? AppColors.muted : Colors.indigo,
                        foregroundColor: isBleConnected ? AppColors.mutedForeground : Colors.white,
                        disabledBackgroundColor: AppColors.muted,
                        disabledForegroundColor: AppColors.mutedForeground,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(LucideIcons.bluetooth, size: 18),
                      label: const Text('Hubungkan BLE'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _toggleBuzzer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isBuzzerOn ? AppColors.destructive : AppColors.card,
                        foregroundColor: _isBuzzerOn ? AppColors.destructiveForeground : AppColors.destructive,
                        side: BorderSide(color: isBleConnected ? AppColors.destructive : AppColors.border),
                        disabledForegroundColor: AppColors.mutedForeground,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_isBuzzerOn ? LucideIcons.volumeX : LucideIcons.volume2, size: 18),
                      label: Text(_isBuzzerOn ? 'Matikan Buzzer' : 'Bunyikan Buzzer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHotspotCard(BuildContext context, TextTheme textTheme) {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hotspot',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.foreground,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Aktif',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Jaringan lokal perangkat tersedia untuk mengakses Web Lokal TAGANA.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Web Lokal:',
                  style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                ),
                Text(
                  'tagana.local',
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/device/${widget.deviceId}/hotspot'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.muted,
                foregroundColor: AppColors.foreground,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(LucideIcons.wifi, size: 18),
              label: const Text('Hubungkan ke Hotspot'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDataBLESection(TextTheme textTheme) {
    return ValueListenableBuilder<bool>(
      valueListenable: BleTelemetryService.instance.isConnectedNotifier,
      builder: (context, isConnected, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status Data BLE',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      isConnected ? LucideIcons.bluetoothConnected : LucideIcons.bluetoothOff, 
                      color: isConnected ? AppColors.success : AppColors.mutedForeground, 
                      size: 16
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isConnected ? 'Terhubung' : 'Terputus',
                      style: textTheme.labelSmall?.copyWith(color: isConnected ? AppColors.success : AppColors.mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.foreground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StreamBuilder<Map<String, dynamic>>(
                stream: BleTelemetryService.instance.telemetryStream,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final time = data != null ? "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}" : "--:--:--";
                  final waterVal = double.tryParse(data?['water']?.toString() ?? '0') ?? 0;
                  final isWaterDetect = waterVal > 50; 
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isConnected ? (data != null ? AppColors.success : Colors.orange) : AppColors.destructive,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '> Data diterima: $time',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '> Water Sensor = ${data == null ? 'Unknown' : (isWaterDetect ? 'Banjir' : 'Kering')} (${waterVal.toStringAsFixed(0)})',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '> Battery = ${data != null ? data['battery'] : 'Unknown'}',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '> Syncing logs... ${isConnected ? 'OK' : 'Waiting'}',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildDataEmergencySummary(TextTheme textTheme, bool isFlood, bool isInternetConnected, Map<String, dynamic>? data) {
    final timeStr = data != null ? "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}" : "--:--:--";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Data Emergency',
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
              _buildSummaryRow(textTheme, 'Status Water Sensor', data == null ? 'Menunggu...' : (isFlood ? 'Air Terdeteksi' : 'Normal'), isFlood),
              const Divider(height: 1),
              _buildSummaryRow(textTheme, 'Status Perangkat', _deviceData == null ? 'Offline' : (isFlood ? 'Emergency' : 'Aman'), isFlood, isStripe: true),
              const Divider(height: 1),
              _buildSummaryRow(textTheme, 'Koneksi Wi-Fi', isInternetConnected ? 'Terhubung' : 'Terputus', !isInternetConnected),
              const Divider(height: 1),
              _buildSummaryRow(textTheme, 'Data Terakhir', timeStr, false, isStripe: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(TextTheme textTheme, String label, String value, bool isEmergency, {bool isStripe = false}) {
    return Container(
      color: isStripe ? AppColors.muted.withOpacity(0.3) : Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isEmergency ? AppColors.destructive : AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Terhubung ke perangkat | Data diperbarui secara real-time',
            style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}