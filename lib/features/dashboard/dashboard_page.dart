import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildStatsGrid(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildQuickActions(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildAlerts(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildDeviceList(context, textTheme),
          ],
        ),
      ),
    );
  }



  Widget _buildGreeting(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat pagi, Yudha',
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

  Widget _buildStatsGrid(TextTheme textTheme) {
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
          value: '12',
          subtitle: 'Perangkat Aktif',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.wifi,
          label: 'STABIL',
          value: '10',
          subtitle: 'Terhubung',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.alertTriangle,
          label: 'AMAN',
          value: '0',
          subtitle: 'Peringatan',
        ),
        _buildStatCard(
          textTheme,
          icon: LucideIcons.activity,
          label: 'SISTEM',
          value: 'Stabil',
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
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            textTheme,
            icon: LucideIcons.map,
            label: 'Lihat Peta',
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            textTheme,
            icon: LucideIcons.history,
            label: 'Riwayat',
            onTap: () {},
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

  Widget _buildAlerts(TextTheme textTheme) {
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
              onPressed: () {},
              child: Text('Lihat Semua', style: textTheme.labelMedium),
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sistem Normal',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '08:00',
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
                        Icon(LucideIcons.mapPin,
                            size: 14, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text('Pusat',
                            style: textTheme.labelSmall
                                ?.copyWith(color: AppColors.mutedForeground)),
                        const SizedBox(width: AppSpacing.md),
                        Icon(LucideIcons.checkCircle2,
                            size: 14, color: AppColors.mutedForeground),
                        const SizedBox(width: 4),
                        Text('Aktif',
                            style: textTheme.labelSmall
                                ?.copyWith(color: AppColors.mutedForeground)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(BuildContext context, TextTheme textTheme) {
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
              onPressed: () {},
              icon: const Icon(LucideIcons.filter, size: 20),
              color: AppColors.mutedForeground,
            ),
          ],
        ),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.sm),
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-001',
          code: 'TGN_0001',
          timeAgo: '2 min ago',
          batteryLevel: 98,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-002',
          code: 'TGN_0002',
          timeAgo: '5 min ago',
          batteryLevel: 45,
        ),
      ],
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    TextTheme textTheme, {
    required String name,
    required String code,
    required String timeAgo,
    required int batteryLevel,
  }) {
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

    return InkWell(
      onTap: () => context.push('/device/$name'),
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
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(LucideIcons.radio,
                      color: AppColors.mutedForeground),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          code,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.mutedForeground,
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
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Normal',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Terhubung',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
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
}