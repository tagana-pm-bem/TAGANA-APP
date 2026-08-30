import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/dashboard_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';
import '../auth/data/user_repository.dart';
import 'models/dashboard_models.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardData _data = DashboardData.empty;
  bool _isLoading = true;
  String? _errorMessage;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _channel = DashboardService.subscribeToDeviceStatus(onChange: _load);
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      DashboardService.unsubscribe(channel);
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await DashboardService.fetchDashboardData();
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
        _errorMessage = 'Gagal memuat data dashboard. Tarik untuk coba lagi.';
      });
    }
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
                    _buildGreeting(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(textTheme),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _buildStatsGrid(textTheme, _data),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(textTheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildAlerts(textTheme, _data.alerts),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDeviceList(context, textTheme, _data.devices),
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

  Widget _buildGreeting(TextTheme textTheme) {
    final name = UserRepository.currentUser?.name ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 11 ? 'Selamat pagi' : hour < 15 ? 'Selamat siang' : hour < 18 ? 'Selamat sore' : 'Selamat malam';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isNotEmpty ? '$greeting, $name' : greeting,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ringkasan operasional hari ini.',
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(TextTheme textTheme, DashboardData data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          textTheme,
          icon: LucideIcons.radio,
          label: 'AKTIF',
          value: '${data.totalDevices}',
          subtitle: 'Perangkat Aktif',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.wifi,
          label: 'STABIL',
          value: '${data.connectedDevices}',
          subtitle: 'Terhubung',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.alertTriangle,
          label: data.activeAlertsCount > 0 ? 'PERHATIAN' : 'AMAN',
          value: '${data.activeAlertsCount}',
          subtitle: 'Peringatan',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.activity,
          label: 'SISTEM',
          value: data.systemCondition,
          subtitle: 'Kondisi',
          valueSize: 20,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
    double? valueSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
              Icon(icon, size: 20, color: AppColors.mutedForeground),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: valueSize,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            textTheme,
            icon: LucideIcons.plusCircle,
            label: 'Hubungkan',
            isPrimary: true,
            onTap: () => context.push('/enter-device'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            textTheme,
            icon: LucideIcons.map,
            label: 'Lihat Peta',
            onTap: () => context.go('/map'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            textTheme,
            icon: LucideIcons.history,
            label: 'Riwayat',
            onTap: () => context.go('/history'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: isPrimary ? null : Border.all(color: AppColors.border),
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
            Icon(
              icon,
              color: isPrimary ? AppColors.primaryForeground : AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isPrimary ? AppColors.primaryForeground : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(TextTheme textTheme, List<AlertSummary> alerts) {
    final latest = alerts.isNotEmpty ? alerts.first : null;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERINGATAN TERBARU',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.mutedForeground,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/history'),
              child: Text('Lihat Semua', style: textTheme.labelMedium),
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        if (latest == null)
          _buildNoAlertCard(textTheme)
        else
          _buildAlertCard(textTheme, latest),
      ],
    );
  }

  Widget _buildNoAlertCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: Colors.blue.shade500, width: 4),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.info, color: Colors.blue.shade500, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sistem Normal — belum ada peringatan.',
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(TextTheme textTheme, AlertSummary alert) {
    final color = switch (alert.severity) {
      'critical' => AppColors.destructive,
      'warning' => AppColors.warning,
      _ => Colors.blue.shade500,
    };
    final icon = switch (alert.severity) {
      'critical' => LucideIcons.alertOctagon,
      'warning' => LucideIcons.alertTriangle,
      _ => LucideIcons.info,
    };
    final timeLabel = _formatTimeAgo(alert.triggeredAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.message,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(LucideIcons.radio, size: 14, color: AppColors.mutedForeground),
                    const SizedBox(width: 4),
                    Text(
                      alert.deviceName ?? alert.deviceCode ?? '-',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
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

  Widget _buildDeviceList(
    BuildContext context,
    TextTheme textTheme,
    List<DeviceWithStatus> devices,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PERANGKAT TAGANA',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.mutedForeground,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () => context.go('/devices'),
              icon: const Icon(LucideIcons.filter, size: 20),
              color: AppColors.mutedForeground,
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        if (devices.isEmpty)
          _buildEmptyDeviceState(textTheme, context)
        else
          ...devices.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildDeviceItem(context, textTheme, d),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyDeviceState(TextTheme textTheme, BuildContext context) {
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
            'Belum ada perangkat terhubung',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => context.push('/enter-device'),
            child: const Text('Hubungkan Perangkat'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    TextTheme textTheme,
    DeviceWithStatus device,
  ) {
    final batteryLevel = (device.batteryLevel ?? 0).round();

    IconData batteryIcon;
    Color batteryColor;
    if (batteryLevel > 80) {
      batteryIcon = LucideIcons.batteryFull;
      batteryColor = AppColors.success;
    } else if (batteryLevel > 30) {
      batteryIcon = LucideIcons.batteryMedium;
      batteryColor = AppColors.warning;
    } else {
      batteryIcon = LucideIcons.batteryLow;
      batteryColor = AppColors.destructive;
    }

    final isConnected = device.isConnected;
    final statusLabel = switch (device.status) {
      'critical' => 'Kritis',
      'warning' => 'Peringatan',
      'online' => 'Terhubung',
      _ => 'Offline',
    };
    final statusColor = switch (device.status) {
      'critical' => AppColors.destructive,
      'warning' => AppColors.warning,
      'online' => Colors.green.shade800,
      _ => AppColors.mutedForeground,
    };
    final statusBg = switch (device.status) {
      'critical' => AppColors.destructive.withOpacity(0.12),
      'warning' => AppColors.warning.withOpacity(0.15),
      'online' => Colors.green.shade100,
      _ => AppColors.muted,
    };

    final timeAgo = device.lastSeenAt != null
        ? _formatTimeAgo(device.lastSeenAt!)
        : 'Belum pernah terhubung';

    return InkWell(
      onTap: () => context.push('/device/${device.id}', extra: isConnected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.muted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.radio, color: AppColors.mutedForeground),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                device.deviceCode,
                                style: textTheme.labelSmall?.copyWith(
                                  color: AppColors.mutedForeground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(batteryIcon, size: 12, color: batteryColor),
                            const SizedBox(width: 2),
                            Text(
                              '$batteryLevel%',
                              style: textTheme.labelSmall?.copyWith(
                                color: batteryColor,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}