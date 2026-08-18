import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: SafeArea(
        child: Column(
          children: [
            // Screen Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aktivitas dan kejadian perangkat',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            
            // Filters
            _buildFilters(textTheme),
            const SizedBox(height: AppSpacing.md),
            
            // Timeline
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _buildTimelineGroup(
                    textTheme,
                    title: 'HARI INI',
                    items: [
                      _buildEventItem(
                        textTheme,
                        title: 'Peringatan Terdeteksi',
                        time: '08:42',
                        subtitle: 'TAGANA-001 · Pusat',
                        description: 'Kondisi perangkat berubah menjadi peringatan. Parameter getaran melebihi ambang batas normal.',
                        icon: LucideIcons.alertTriangle,
                        iconColor: Colors.orange.shade800,
                        iconBgColor: Colors.orange.shade50,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildEventItem(
                        textTheme,
                        title: 'Perangkat Terhubung',
                        time: '07:15',
                        subtitle: 'TAGANA-002 · Utara',
                        description: 'Perangkat berhasil terkoneksi kembali ke jaringan sistem pusat setelah pemeliharaan.',
                        icon: LucideIcons.checkCircle2,
                        iconColor: Colors.green.shade800,
                        iconBgColor: Colors.green.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTimelineGroup(
                    textTheme,
                    title: 'KEMARIN',
                    items: [
                      _buildEventItem(
                        textTheme,
                        title: 'Koneksi Terputus',
                        time: '23:05',
                        subtitle: 'TAGANA-004 · Selatan',
                        description: 'Perangkat kehilangan daya dan koneksi jaringan. Memerlukan pemeriksaan fisik segera.',
                        icon: LucideIcons.alertOctagon,
                        iconColor: AppColors.destructive,
                        iconBgColor: Colors.red.shade50,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildEventItem(
                        textTheme,
                        title: 'Pembaruan Sistem',
                        time: '14:30',
                        subtitle: 'Sistem Pusat',
                        description: 'Pembaruan firmware versi 2.1.4 berhasil diterapkan ke seluruh perangkat yang aktif.',
                        icon: LucideIcons.info,
                        iconColor: Colors.indigo.shade700,
                        iconBgColor: Colors.indigo.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // padding for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildFilterChip(textTheme, 'Hari ini', isActive: true, isPeriod: true),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, '7 Hari', isPeriod: true),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, '30 Hari', isPeriod: true),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, 'Custom', icon: LucideIcons.calendar, isPeriod: true),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Category Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildFilterChip(textTheme, 'Semua', isActive: true),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, 'Peringatan'),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, 'Kritis'),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, 'Perangkat'),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(textTheme, 'Sistem'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    TextTheme textTheme,
    String label, {
    bool isActive = false,
    bool isPeriod = false,
    IconData? icon,
  }) {
    Color bgColor;
    Color textColor;
    Border? border;

    if (isPeriod) {
      if (isActive) {
        bgColor = AppColors.primaryContainer;
        textColor = AppColors.primary;
      } else {
        bgColor = AppColors.muted;
        textColor = AppColors.foreground;
      }
    } else {
      if (isActive) {
        bgColor = AppColors.secondary;
        textColor = AppColors.foreground;
      } else {
        bgColor = AppColors.card;
        textColor = AppColors.foreground;
        border = Border.all(color: AppColors.border);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isPeriod ? 24 : 8),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: textColor),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: textColor),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineGroup(
    TextTheme textTheme, {
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: AppSpacing.sm),
          child: Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildEventItem(
    TextTheme textTheme, {
    required String title,
    required String time,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      time,
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(color: Colors.indigo.shade300), // tertiary approximation
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Icon(LucideIcons.chevronRight, color: AppColors.mutedForeground, size: 20),
          ),
        ],
      ),
    );
  }
}