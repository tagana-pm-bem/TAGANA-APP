import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../auth/data/user_repository.dart';
import '../auth/models/user_profile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // TODO: belum ada tabel preferensi notifikasi di database — toggle ini
  // masih murni UI state, belum persist. Perlu tabel (mis. user_preferences)
  // kalau mau disimpan beneran.
  bool _criticalAlertsEnabled = true;
  bool _deviceNotifsEnabled = false;

  UserProfile? _user;
  String _appVersion = '';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _user = UserRepository.currentUser;
    if (_user == null) {
      // Fallback jaga-jaga kalau currentUser belum ke-restore saat halaman dibuka.
      UserRepository.restoreSessionProfile().then((user) {
        if (!mounted) return;
        setState(() => _user = user);
      });
    }
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _appVersion = 'v${info.version}');
    } catch (_) {
      // Tidak kritis — biarkan kosong kalau gagal.
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu login kembali untuk mengakses aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Keluar', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await UserRepository.logout();
      if (!mounted) return;
      // TODO: sesuaikan dengan route welcome/login asli di app_router.dart
      context.go('/welcome');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal keluar. Coba lagi.')),
      );
    }
  }

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
                  onTap: () => context.push('/settings/profile'),
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.phone,
                  title: 'Nomor Telepon',
                  trailingText: _user?.phone,
                  onTap: () => context.push('/settings/phone'),
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.edit3,
                  title: 'Edit Profil',
                  showBorder: false,
                  onTap: () => context.push('/settings/edit-profile'),
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
                  onTap: () => context.push('/settings/help'),
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.info,
                  title: 'Tentang TAGANA',
                  onTap: () => context.push('/settings/about'),
                ),
                _buildSettingsItem(
                  textTheme,
                  icon: LucideIcons.smartphone,
                  title: 'Versi Aplikasi',
                  trailingText: _appVersion.isNotEmpty ? _appVersion : '-',
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
    final user = _user;
    final name = user?.name.isNotEmpty == true ? user!.name : 'Pengguna';
    final subtitle = (user?.email?.isNotEmpty == true)
        ? user!.email!
        : (user?.phone ?? '-');
    final initials = _initialsOf(name);

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
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    initials,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: () => context.push('/settings/edit-profile'),
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

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
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
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
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
            if (trailingText != null && trailingText.isNotEmpty)
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
      onTap: _isLoggingOut ? null : _handleLogout,
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
        child: _isLoggingOut
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
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