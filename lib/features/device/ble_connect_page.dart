import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class BleConnectPage extends StatelessWidget {
  const BleConnectPage({
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScanningSection(textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildEmergencyDevicesSection(textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildOtherDevicesSection(textTheme),
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
            'Hubungkan BLE',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            'Cari perangkat TAGANA di sekitar Anda',
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
        ),
      ),
    );
  }

  Widget _buildScanningSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulse effect placeholders
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(LucideIcons.bluetoothSearching, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Mencari perangkat TAGANA di sekitar Anda...',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyDevicesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.destructive, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Perangkat Darurat',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.destructive,
                ),
              ),
            ],
          ),
        ),
        _buildDeviceItem(
          textTheme,
          name: deviceId, // Use the targeted device ID
          id: 'TGN_0001',
          tagLabel: 'Emergency',
          tagColor: AppColors.destructiveForeground,
          tagBgColor: AppColors.destructive,
          signalText: 'Sinyal: Baik',
          signalIcon: LucideIcons.signalHigh,
          signalColor: AppColors.primary,
          isEmergency: true,
        ),
      ],
    );
  }

  Widget _buildOtherDevicesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(LucideIcons.monitorSmartphone, color: AppColors.mutedForeground, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Perangkat Lain',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        _buildDeviceItem(
          textTheme,
          name: 'TAGANA-002',
          id: 'TGN_0002',
          tagLabel: 'Normal',
          tagColor: AppColors.mutedForeground,
          tagBgColor: AppColors.muted,
          signalText: 'Sinyal: Sedang',
          signalIcon: LucideIcons.signalMedium,
          signalColor: AppColors.mutedForeground,
          isEmergency: false,
        ),
      ],
    );
  }

  Widget _buildDeviceItem(
    TextTheme textTheme, {
    required String name,
    required String id,
    required String tagLabel,
    required Color tagColor,
    required Color tagBgColor,
    required String signalText,
    required IconData signalIcon,
    required Color signalColor,
    required bool isEmergency,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: isEmergency ? const Border(left: BorderSide(color: AppColors.destructive, width: 4)) : null,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
              Text(
                'ID: $id',
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
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
          isEmergency
              ? ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hubungkan'),
                )
              : OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.muted,
                    foregroundColor: AppColors.foreground,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Hubungkan'),
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
              side: BorderSide.none,
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
