import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/device_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../dashboard/models/dashboard_models.dart';

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
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      DeviceService.unsubscribeDeviceStatus(channel);
    }
    _searchController.dispose();
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
            ? const Center(child: CircularProgressIndicator())
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
    final isConnected = device.isConnected;
    final isWarning = _isWarning(device);
    final icon = isConnected ? LucideIcons.radio : LucideIcons.wifiOff;
    final statusText = _statusText(device);
    final timeAgo = _formatTimeAgo(device.lastSeenAt);

    return InkWell(
      onTap: () => context.push('/device/${device.id}', extra: isConnected),
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
                              : (isConnected ? AppColors.primary : AppColors.mutedForeground),
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
                                    'Terhubung',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                      color: Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
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
              if (!isConnected) ...[
                const SizedBox(height: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: () => context.push('/device/${device.deviceName}/wifi-config'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.destructive,
                    foregroundColor: AppColors.destructiveForeground,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(LucideIcons.wifi, size: 16),
                  label: const Text('Hubungkan ke Internet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ],
          ),
      ),
    );
  }
}