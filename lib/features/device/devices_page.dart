import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/device_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../dashboard/models/dashboard_models.dart';
import '../../core/services/ble_telemetry_service.dart';

enum _DeviceFilter { semua, terhubung, tidakTerhubung, peringatan }

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DeviceWithStatus> _devices = [];
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;

  final _searchController = TextEditingController();
  String _query = '';
  _DeviceFilter _filter = _DeviceFilter.semua;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = DeviceService.subscribeToDeviceStatus(onChange: _load);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    BleTelemetryService.instance.isConnectedNotifier.addListener(_onBleStatusChanged);
  }

  void _onBleStatusChanged() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      DeviceService.unsubscribeDeviceStatus(channel);
    }
    _searchController.dispose();
    BleTelemetryService.instance.isConnectedNotifier.removeListener(_onBleStatusChanged);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final devices = await DeviceService.fetchDevices();
      if (!mounted) return;
      setState(() {
        _devices = devices;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data perangkat. Tarik untuk coba lagi.';
      });
    }
  }

  bool _isWarning(DeviceWithStatus d) =>
      d.status == 'warning' || d.status == 'critical';

  List<DeviceWithStatus> get _filteredDevices {
    return _devices.where((d) {
      final matchesQuery = _query.isEmpty ||
          d.deviceName.toLowerCase().contains(_query) ||
          d.deviceCode.toLowerCase().contains(_query);
      if (!matchesQuery) return false;

      switch (_filter) {
        case _DeviceFilter.semua:
          return true;
        case _DeviceFilter.terhubung:
          return d.isConnected;
        case _DeviceFilter.tidakTerhubung:
          return !d.isConnected;
        case _DeviceFilter.peringatan:
          return _isWarning(d);
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? _buildSkeleton()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(textTheme),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _buildStatsGrid(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSearchAndFilter(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDeviceList(context, textTheme),
                    // Padding for FAB
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/enter-device'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Hubungkan Perangkat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row skeleton
          Row(
            children: List.generate(
              4,
              (index) => const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Skeleton(height: 70),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Search skeleton
          const Skeleton(height: 48),
          const SizedBox(height: AppSpacing.md),
          
          // Filter chips skeleton
          Row(
            children: List.generate(
              3,
              (index) => const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: Skeleton(width: 80, height: 32, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Devices list skeleton
          ...List.generate(
            4,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: Skeleton(height: 120),
            ),
          ),
        ],
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

  Widget _buildStatsGrid(TextTheme textTheme) {
    final total = _devices.length;
    final connected = _devices.where((d) => d.isConnected).length;
    final disconnected = total - connected;
    final warning = _devices.where(_isWarning).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '$total',
            label: 'Total',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '$connected',
            label: 'Terhubung',
            valueColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '$disconnected',
            label: 'Tidak\nTerhubung',
            valueColor: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '$warning',
            label: 'Peringatan',
            valueColor: AppColors.destructive,
            isWarning: warning > 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    TextTheme textTheme, {
    required String value,
    required String label,
    required Color valueColor,
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: 4),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.shade50 : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning ? AppColors.destructive : AppColors.border,
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
        children: [
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: isWarning ? AppColors.destructive : AppColors.mutedForeground,
              fontSize: 10,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(TextTheme textTheme) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Cari perangkat...',
            prefixIcon: const Icon(LucideIcons.search, color: AppColors.mutedForeground),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('Semua', _DeviceFilter.semua),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Terhubung', _DeviceFilter.terhubung),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Tidak Terhubung', _DeviceFilter.tidakTerhubung),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Peringatan', _DeviceFilter.peringatan),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, _DeviceFilter value) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryForeground : AppColors.mutedForeground,
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context, TextTheme textTheme) {
    final devices = _filteredDevices;

    if (_devices.isEmpty) {
      return _buildEmptyState(
        textTheme,
        context,
        message: 'Belum ada perangkat terhubung',
        showAction: true,
      );
    }

    if (devices.isEmpty) {
      return _buildEmptyState(
        textTheme,
        context,
        message: 'Tidak ada perangkat yang cocok dengan pencarian/filter',
        showAction: false,
      );
    }

    return Column(
      children: [
        for (final device in devices) ...[
          _buildDeviceItem(context, textTheme, device),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    TextTheme textTheme,
    BuildContext context, {
    required String message,
    required bool showAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.radio, size: 32, color: AppColors.mutedForeground),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          if (showAction) ...[
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.push('/enter-device'),
              child: const Text('Hubungkan Perangkat'),
            ),
          ],
        ],
      ),
    );
  }

  String _statusText(DeviceWithStatus d) {
    switch (d.status) {
      case 'online':
        return 'Normal';
      case 'warning':
        return 'Peringatan';
      case 'critical':
        return 'Kritis';
      default:
        return 'Tidak Terhubung';
    }
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Belum pernah terhubung';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  Widget _buildDeviceItem(
    BuildContext context,
    TextTheme textTheme,
    DeviceWithStatus device,
  ) {
    final isBleConnected = BleTelemetryService.instance.isConnected && 
                           BleTelemetryService.instance.connectedDeviceId == device.id;

    final isConnected = isBleConnected || device.isConnected;
    final isWarning = _isWarning(device);
    final icon = isBleConnected ? LucideIcons.bluetooth : (isConnected ? LucideIcons.radio : LucideIcons.wifiOff);
    final statusText = isBleConnected ? 'Terhubung (Bluetooth)' : (isConnected ? _statusText(device) : 'Tidak Terhubung');
    final timeAgo = isBleConnected ? 'Realtime (BLE)' : _formatTimeAgo(device.lastSeenAt);

    return InkWell(
      onTap: () => context.push('/device/${device.id}', extra: {
        'isOnline': isConnected,
        'deviceCode': device.deviceCode,
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isWarning ? Colors.red.shade50 : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWarning ? Colors.red.shade200 : AppColors.border,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isWarning
                              ? Colors.red.shade100
                              : (isConnected ? Colors.indigo.shade50 : AppColors.muted),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          icon,
                          color: isWarning
                              ? AppColors.destructive
                              : (isBleConnected ? Colors.blue : (isConnected ? AppColors.primary : AppColors.mutedForeground)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            device.deviceCode,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (isConnected) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isBleConnected ? 'Bluetooth' : 'Internet',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: isBleConnected ? Colors.blue.shade800 : Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isWarning ? Colors.red.shade100 : AppColors.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: isWarning ? AppColors.destructive : AppColors.mutedForeground,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeAgo,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: isWarning ? AppColors.destructive : AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        LucideIcons.chevronRight,
                        color: AppColors.mutedForeground,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (isBleConnected) {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Putuskan BLE'),
                              content: Text('Putuskan koneksi Bluetooth dari ${device.deviceCode}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Putuskan', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await BleTelemetryService.instance.disconnect();
                          }
                        } else {
                          if (BleTelemetryService.instance.isConnected) {
                            final currentCode = BleTelemetryService.instance.connectedDeviceCode ?? 'perangkat lain';
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Ganti Koneksi BLE?'),
                                content: Text('Anda sedang terhubung ke BLE $currentCode. Putuskan dan hubungkan ke ${device.deviceCode}?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Lanjutkan', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;
                            await BleTelemetryService.instance.disconnect();
                          }
                          if (context.mounted) {
                            context.push('/device/${device.id}/ble?code=${device.deviceCode}&name=${Uri.encodeComponent(device.deviceName)}');
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isBleConnected ? Colors.red : AppColors.primary,
                        side: BorderSide(color: isBleConnected ? Colors.red.withOpacity(0.5) : AppColors.primary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(isBleConnected ? LucideIcons.bluetoothOff : LucideIcons.bluetooth, size: 16),
                      label: Text(
                        isBleConnected ? 'Putuskan BLE' : 'Hubungkan BLE',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isBleConnected) {
                          context.push('/device/${device.id}/wifi-config');
                        } else {
                          if (device.isConnected) {
                            context.push('/device/${device.id}/wifi-config');
                          } else {
                            context.push('/device/${device.id}/ble?returnTo=wifi-config&code=${device.deviceCode}&name=${Uri.encodeComponent(device.deviceName)}');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (isBleConnected || device.isConnected) ? AppColors.primary : AppColors.destructive,
                        foregroundColor: (isBleConnected || device.isConnected) ? AppColors.primaryForeground : AppColors.destructiveForeground,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(LucideIcons.wifi, size: 16),
                      label: Text(
                        (isBleConnected || device.isConnected) ? 'Konfigurasi Wi-Fi' : 'Offline, Setup!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}