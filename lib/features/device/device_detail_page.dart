import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class DeviceDetailPage extends StatelessWidget {
  const DeviceDetailPage({
    required this.deviceId,
    this.isOnline = true,
    super.key,
  });

  final String deviceId;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapSection(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildMonitoringSection(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildDeviceInfo(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentActivity(textTheme),
            const SizedBox(height: AppSpacing.lg),
            _buildActions(context, textTheme),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: AppColors.primary,
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Detail Perangkat',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            deviceId,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.moreVertical),
          color: AppColors.mutedForeground,
          onPressed: () {},
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: AppColors.border, height: 1.0),
      ),
    );
  }

  Widget _buildMapSection(TextTheme textTheme) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuC77G_NKapS1CcpDm-SMfE9zmVvNJkUGXXNhOCGFIVXgEtfMrY44e3RTbLBfMYxDSF1aJxey8IdbbayWtASjfJJe9x_WpDmV1rnoYEnLx5dnbjV_E-rh_jL9UjZTZvXkiWekNGsVrVrLa5q3JvhbONiGJyEYrqb3uaZE5v7D-vdSXyF4mViZLWUUMKQRWNNIBaiE_70hl8Iy80iHApEBdkn4xMvyCb1Ovzz7kiTpOTtIPBHqKAiSM1j',
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.8),
                  colorBlendMode: BlendMode.dstIn,
                ),
                const Center(
                  child: Icon(LucideIcons.mapPin, color: AppColors.primary, size: 40),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceId,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    Text(
                      'ID: TGN_0001',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.success : AppColors.destructive,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isOnline ? const Color(0x8010B981) : const Color(0x80EF4444),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'Terhubung' : 'Offline',
                    style: textTheme.labelSmall?.copyWith(
                      color: isOnline ? AppColors.success : AppColors.destructive,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMonitoringSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Monitoring Aktif',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.droplets,
              label: 'Water Lvl',
              value: '1.2m',
              status: 'Aman',
              statusColor: AppColors.success,
              iconColor: AppColors.primary,
              iconBgColor: AppColors.primary.withOpacity(0.1),
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.batteryFull,
              label: 'Baterai',
              value: '98%',
              status: 'Optimal',
              statusColor: AppColors.mutedForeground,
              iconColor: AppColors.mutedForeground,
              iconBgColor: AppColors.muted,
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.signal,
              label: 'Sinyal',
              value: '-65',
              unit: 'dBm',
              status: 'Kuat',
              statusColor: AppColors.mutedForeground,
              iconColor: Colors.indigo,
              iconBgColor: Colors.indigo.shade50,
            ),
            _buildMonitorCard(
              textTheme,
              icon: LucideIcons.compass,
              label: 'Koordinat',
              value: 'Lat: -6.5891',
              status: 'Long: 106.8438',
              statusColor: AppColors.foreground,
              iconColor: AppColors.destructive,
              iconBgColor: AppColors.destructive.withOpacity(0.1),
              isCoordinate: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonitorCard(
    TextTheme textTheme, {
    required IconData icon,
    required String label,
    required String value,
    String? unit,
    required String status,
    required Color statusColor,
    required Color iconColor,
    required Color iconBgColor,
    bool isCoordinate = false,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          if (isCoordinate) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
                ),
                Text(
                  status,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
                ),
              ],
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                    children: [
                      TextSpan(text: value),
                      if (unit != null)
                        TextSpan(
                          text: unit,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
                ),
                Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(color: statusColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Informasi Perangkat',
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
              _buildInfoRow(textTheme, 'Serial Number', 'SN-99283-XQ'),
              const Divider(height: 1),
              _buildInfoRow(textTheme, 'Versi Perangkat Keras', 'v2.4.1 (Pro)'),
              const Divider(height: 1),
              _buildInfoRow(textTheme, 'Tanggal Instalasi', '12 Okt 2023'),
              const Divider(height: 1),
              _buildInfoRow(textTheme, 'Lokasi', 'Bendungan Katulampa', isLink: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(TextTheme textTheme, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
          ),
          if (isLink)
            Row(
              children: [
                Text(
                  value,
                  style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(width: 4),
                const Icon(LucideIcons.externalLink, size: 14, color: AppColors.primary),
              ],
            )
          else
            Text(
              value,
              style: textTheme.labelMedium?.copyWith(color: AppColors.foreground),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(TextTheme textTheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Aktivitas',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.foreground,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        _buildActivityItem(
          textTheme,
          icon: LucideIcons.refreshCw,
          title: 'Sinkronisasi Data Berhasil',
          description: 'Data sensor terakhir dikirim ke server pusat.',
          time: 'Hari ini, 14:32',
          isPrimary: true,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildActivityItem(
          textTheme,
          icon: LucideIcons.settings,
          title: 'Pembaruan Firmware v2.4.1',
          description: 'Pembaruan sistem keamanan minor diterapkan secara remote.',
          time: 'Kemarin, 09:15',
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String description,
    required String time,
    bool isPrimary = false,
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.primary.withOpacity(0.1) : AppColors.muted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isPrimary ? AppColors.primary : AppColors.mutedForeground,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isOnline) ..._buildOfflineBanner(context, textTheme),
        _buildEmergencyBtn(context),
        const SizedBox(height: AppSpacing.sm),
        _buildTestConnectionBtn(context),
        const SizedBox(height: AppSpacing.sm),
        _buildCalibrateBtn(),
      ],
    );
  }

  List<Widget> _buildOfflineBanner(BuildContext context, TextTheme textTheme) {
    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.destructive.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.wifiOff, color: AppColors.destructive, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perangkat Offline',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.destructive,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Perangkat belum terhubung ke internet.',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.destructive.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      ElevatedButton.icon(
        onPressed: () => context.push('/device/$deviceId/wifi-config'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.destructive,
          foregroundColor: AppColors.destructiveForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(LucideIcons.wifi, size: 18),
        label: const Text('Hubungkan ke Internet', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      const SizedBox(height: AppSpacing.sm),
    ];
  }

  Widget _buildEmergencyBtn(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/device/$deviceId/emergency'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.destructive,
        foregroundColor: AppColors.destructiveForeground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.alertTriangle, size: 18),
      label: const Text('Mode Darurat', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTestConnectionBtn(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.push('/device/$deviceId/test-connection'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.radio, size: 18),
      label: const Text('Uji Koneksi', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCalibrateBtn() {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo.shade50, // tertiary fixed like
        foregroundColor: Colors.indigo.shade900,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.sliders, size: 18),
      label: const Text('Kalibrasi', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}