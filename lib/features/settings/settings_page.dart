import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _criticalAlertsEnabled = true;
  bool _deviceNotifsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengaturan',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Kelola akun dan preferensi TAGANA',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),

            // User Profile Card
            _buildProfileCard(textTheme),
            const SizedBox(height: AppSpacing.lg),

            // Akun Section
            _buildSettingsSection(
              textTheme,
              title: 'Akun',
              items: [
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.user,
                  title: 'Profil',
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.phone,
                  title: 'Nomor Telepon',
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.edit3,
                  title: 'Edit Profil',
                  showBorder: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Notifikasi Section
            _buildSettingsSection(
              textTheme,
              title: 'Notifikasi',
              items: [
                _buildToggleItem(
                  textTheme,
                  icon: LucideIcons.alertTriangle,
                  title: 'Peringatan Kritis',
                  value: _criticalAlertsEnabled,
                  onChanged: (val) {
                    setState(() {
                      _criticalAlertsEnabled = val;
                    });
                  },
                ),
                _buildToggleItem(
                  textTheme,
                  icon: LucideIcons.radio,
                  title: 'Notifikasi Perangkat',
                  value: _deviceNotifsEnabled,
                  showBorder: false,
                  onChanged: (val) {
                    setState(() {
                      _deviceNotifsEnabled = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Bantuan & Tentang Section
            _buildSettingsSection(
              textTheme,
              title: 'Bantuan & Tentang',
              items: [
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.helpCircle,
                  title: 'Pusat Bantuan',
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.info,
                  title: 'Tentang TAGANA',
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.smartphone,
                  title: 'Versi Aplikasi',
                  trailingText: 'v1.0.0',
                  showBorder: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Logout Action
            _buildLogoutButton(textTheme),
            const SizedBox(height: 100), // Padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuA3Kja-5loOn0yDsu4GJ_va683woaMvhMwz_WkBVgbgYZu_VIxqDsgmCBq2Vl3aYn7NY4O2TfclqE2xloEi5eMOxpMnoAgqkUqPabJA-ynTisg8EpiKAivdLV2gMruY266b0NcxhHSB2JO_5mTwDKywkCXheWc8eSfdj5ffcku4V0kRLBroO30ESGYhGkc5Pt-MzSNctTpKwmzsh6ledJ00OOixr-90xJFDL19RDAsLRi53PrR2dt6J'),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yudha',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  Text(
                    '08xxxxxxxxxx',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Edit Profil'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    TextTheme textTheme, {
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.mutedForeground,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsItem(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    String? trailingText,
    bool showBorder = true,
  }) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.mutedForeground, size: 20),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
              )
            else
              const Icon(LucideIcons.chevronRight, color: AppColors.mutedForeground, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.border))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.mutedForeground, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(TextTheme textTheme) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'Keluar',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.destructive,
          ),
        ),
      ),
    );
  }
}