import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        icon: const Icon(LucideIcons.plus),
        label: const Text('Hubungkan Perangkat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }



  Widget _buildStatsGrid(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '12',
            label: 'Total',
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '10',
            label: 'Terhubung',
            valueColor: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '1',
            label: 'Tidak\nTerhubung',
            valueColor: AppColors.mutedForeground,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildStatCard(
            textTheme,
            value: '1',
            label: 'Peringatan',
            valueColor: AppColors.destructive,
            isWarning: true,
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
              _buildFilterChip('Semua', isSelected: true),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Terhubung'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Tidak Terhubung'),
              const SizedBox(width: AppSpacing.sm),
              _buildFilterChip('Peringatan'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return Container(
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
    );
  }

  Widget _buildDeviceList(BuildContext context, TextTheme textTheme) {
    return Column(
      children: [
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-001',
          code: 'TGN_0001',
          timeAgo: '2 menit lalu',
          icon: LucideIcons.radio,
          statusText: 'Normal',
          isConnected: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-002',
          code: 'TGN_0002',
          timeAgo: 'Baru saja',
          icon: LucideIcons.router,
          statusText: 'Baterai Rendah',
          isConnected: true,
          isWarning: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-003',
          code: 'TGN_0003',
          timeAgo: '5 jam lalu',
          icon: LucideIcons.wifiOff,
          statusText: 'Tidak Terhubung',
          isConnected: false,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildDeviceItem(
          context,
          textTheme,
          name: 'TAGANA-004',
          code: 'TGN_0004',
          timeAgo: '10 menit lalu',
          icon: LucideIcons.router,
          statusText: 'Normal',
          isConnected: true,
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
    required IconData icon,
    required String statusText,
    required bool isConnected,
    bool isWarning = false,
  }) {
    return Opacity(
      opacity: isConnected ? 1.0 : 0.6,
      child: InkWell(
        onTap: () => context.push('/device/$name'),
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
          child: Row(
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
                      borderRadius: BorderRadius.circular(20), // Fully rounded as per HTML
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
                        name,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        code,
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
        ),
      ),
    );
  }
}
