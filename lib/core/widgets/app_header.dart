import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

import '../services/ble_telemetry_service.dart';
import '../../features/auth/data/user_repository.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.title});
  final String? title;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppSpacing.md,
      title: title != null
          ? Text(
              title!,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : Row(
              children: [
                Builder(
                  builder: (context) {
                    final user = UserRepository.currentUser;
                    final name = user?.name ?? 'User';
                    final avatarUrl = user?.avatarUrl;

                    final parts = name.trim().split(RegExp(r'\s+'));
                    String initials = 'U';
                    if (parts.isNotEmpty && parts[0].isNotEmpty) {
                      if (parts.length > 1 && parts[1].isNotEmpty) {
                        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
                      } else {
                        initials = parts[0][0].toUpperCase();
                      }
                    }

                    if (avatarUrl != null && avatarUrl.isNotEmpty) {
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }

                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(width: AppSpacing.sm),
                Image.asset(
                  'assets/images/tagana.jpg',
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ],
            ),
      actions: [
        Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: BleTelemetryService.instance.isConnectedNotifier,
            builder: (context, isConnected, child) {
              if (!isConnected) return const SizedBox.shrink();
              final deviceCode = BleTelemetryService.instance.connectedDeviceCode ?? 'Sensor';
              return GestureDetector(
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Putuskan BLE'),
                      content: Text('Apakah Anda yakin ingin memutuskan koneksi Bluetooth dari $deviceCode?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true), 
                          child: const Text('Putuskan', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await BleTelemetryService.instance.disconnect();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.bluetooth, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        deviceCode,
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.border,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1.0);
}
