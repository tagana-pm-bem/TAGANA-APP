import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class HotspotPage extends StatelessWidget {
  const HotspotPage({
    required this.deviceId,
    super.key,
  });

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHotspotList(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoNote(textTheme),
                ],
              ),
            ),
          ),
          _buildBottomAction(textTheme),
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
        color: AppColors.mutedForeground,
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hotspot TAGANA',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Hubungkan ke jaringan lokal perangkat',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.border,
          height: 1.0,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
    );
  }

  Widget _buildStatusCard(TextTheme textTheme) {
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
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.wifi, color: Colors.green.shade700),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedForeground,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Wi-Fi Aktif',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotList(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Hotspot Tersedia',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        _buildHotspotItem(
          textTheme,
          name: '${deviceId}_AP',
          tagLabel: 'Emergency',
          tagColor: AppColors.destructive,
          tagBgColor: Colors.red.shade100,
          signalText: 'Sinyal Baik',
          signalIcon: LucideIcons.signalHigh,
          signalColor: Colors.green.shade600,
          iconColor: AppColors.primary,
          isPrimaryAction: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildHotspotItem(
          textTheme,
          name: 'TAGANA-003_AP',
          tagLabel: 'Peringatan',
          tagColor: Colors.orange.shade800,
          tagBgColor: Colors.orange.shade100,
          signalText: 'Sinyal Sedang',
          signalIcon: LucideIcons.signalMedium,
          signalColor: Colors.orange.shade600,
          iconColor: AppColors.mutedForeground,
          isPrimaryAction: false,
        ),
      ],
    );
  }

  Widget _buildHotspotItem(
    TextTheme textTheme, {
    required String name,
    required String tagLabel,
    required Color tagColor,
    required Color tagBgColor,
    required String signalText,
    required IconData signalIcon,
    required Color signalColor,
    required Color iconColor,
    required bool isPrimaryAction,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 400;
          
          Widget infoContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(LucideIcons.router, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tagLabel,
                            style: textTheme.labelSmall?.copyWith(color: tagColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(signalIcon, size: 14, color: signalColor),
                        const SizedBox(width: 4),
                        Text(
                          signalText,
                          style: textTheme.labelSmall?.copyWith(color: signalColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          Widget actionContent = isPrimaryAction
              ? ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hubungkan'),
                )
              : OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.muted,
                    foregroundColor: AppColors.foreground,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hubungkan'),
                );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoContent,
                const SizedBox(height: AppSpacing.md),
                actionContent,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoContent),
                const SizedBox(width: AppSpacing.md),
                actionContent,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildInfoNote(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: Colors.indigo), // tertiary
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                children: [
                  const TextSpan(text: 'Gunakan Hotspot untuk mengakses Web Lokal TAGANA di '),
                  TextSpan(
                    text: 'tagana.local',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.muted,
              foregroundColor: AppColors.foreground,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(LucideIcons.refreshCw, size: 16),
            label: const Text('Scan Lagi'),
          ),
        ),
      ),
    );
  }
}
