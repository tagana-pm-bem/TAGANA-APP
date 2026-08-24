import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/ble_telemetry_service.dart';

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
      // Firmware ESP32 mengharapkan string mentah "BUZZER" sebagai perintah toggle
      BleTelemetryService.instance.sendRawCommand('BUZZER');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBuzzerOn ? 'Buzzer Dinyalakan' : 'Buzzer Dimatikan')),
      );
    } catch (e) {
      setState(() => _isBuzzerOn = !_isBuzzerOn); // Revert on failure
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.md,
              bottom: 100, // Padding for footer
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmergencyStatusCard(textTheme),
                const SizedBox(height: AppSpacing.lg),
                _buildPenyebabSection(textTheme),
                const SizedBox(height: AppSpacing.lg),
                _buildKomunikasiDaruratSection(context, textTheme),
                const SizedBox(height: AppSpacing.lg),
                _buildStatusDataBLESection(textTheme),
                const SizedBox(height: AppSpacing.lg),
                _buildDataEmergencySummary(textTheme),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildFooter(textTheme),
          ),
        ],
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
            '${widget.deviceId} | TGN_0001', // Example static mapped ID
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

  Widget _buildEmergencyStatusCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.destructive.withOpacity(0.2)),
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
              const Icon(
                LucideIcons.alertOctagon,
                color: AppColors.destructive,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Mode Aktif',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Perangkat mendeteksi kondisi darurat.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade800,
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
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      'Water Sensor mendeteksi air',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Waktu Kejadian:',
                      style: textTheme.labelMedium?.copyWith(
                        color: Colors.red.shade700,
                      ),
                    ),
                    Text(
                      '17 Agustus 2026 · 10:42',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade900,
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

  Widget _buildPenyebabSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Penyebab',
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
                'Perangkat masuk ke mode komunikasi darurat karena mendeteksi air saat jaringan Wi-Fi tidak tersedia.',
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
                            Expanded(child: _buildCauseItem(textTheme, 'Water Sensor', 'Air terdeteksi', LucideIcons.droplet)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildCauseItem(textTheme, 'Koneksi Wi-Fi', 'Tidak tersedia', LucideIcons.wifiOff)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCauseItem(textTheme, 'Water Sensor', 'Air terdeteksi', LucideIcons.droplet),
                            const SizedBox(height: AppSpacing.md),
                            _buildCauseItem(textTheme, 'Koneksi Wi-Fi', 'Tidak tersedia', LucideIcons.wifiOff),
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

  Widget _buildCauseItem(TextTheme textTheme, String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.destructive, size: 24),
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
                  color: AppColors.destructive,
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
            'Perangkat dapat mengirimkan data emergency langsung ke aplikasi melalui Bluetooth.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/device/${widget.deviceId}/ble'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
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
                    side: const BorderSide(color: AppColors.destructive),
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
                color: AppColors.foreground, // Dark background
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
                  final waterVal = data != null ? data['water'] : 0;
                  // Asumsikan > 1000 artinya basah (batas banjir ESP32 = 1900 max)
                  final isWaterDetect = waterVal > 1000; 
                  
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
                        '> Water Sensor = ${data == null ? 'Unknown' : (isWaterDetect ? 'Banjir' : 'Kering')} ($waterVal)',
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
                      const SizedBox(height: AppSpacing.md),
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () {
                            if (isConnected) {
                              BleTelemetryService.instance.disconnect();
                            } else {
                              BleTelemetryService.instance.connect(widget.deviceId);
                            }
                          },
                          child: Text(
                            isConnected ? 'Putuskan BLE' : 'Hubungkan BLE',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                              decoration: TextDecoration.underline,
                            ),
                          ),
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

  Widget _buildDataEmergencySummary(TextTheme textTheme) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: BleTelemetryService.instance.telemetryStream,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final waterVal = data != null ? data['water'] : 0;
        final isFlood = waterVal > 1000;
        final wifiSSID = data != null ? data['ssid'] : 'Unknown';
        final time = data != null ? "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}" : "--:--:--";
        
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
                  _buildSummaryRow(textTheme, 'Status Perangkat', data == null ? 'Offline' : (isFlood ? 'Emergency' : 'Aman'), isFlood, isStripe: true),
                  const Divider(height: 1),
                  _buildSummaryRow(textTheme, 'Koneksi Wi-Fi', wifiSSID.toString(), false),
                  const Divider(height: 1),
                  _buildSummaryRow(textTheme, 'Data Terakhir', time, false, isStripe: true),
                ],
              ),
            ),
          ],
        );
      }
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
            width: 8,
            height: 8,
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
