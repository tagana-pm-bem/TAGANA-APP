import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

import '../services/ble_telemetry_service.dart';

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
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAhbGHh_GiUxKOnhs8Shlqj_Ml-e7D9w54Ee7CAtkMSfvl4Nu2Dhs7q0y8qaTwGGYmeGti8pFQZh5gUV2eFjQR0mQveRZwblPnlwO0M51EegFdEKY-O2UblCcvbVJrPqyWnQAbWUWECAhHCOq0pPZKUIdPmCaFnlXu7YtNIGY7oM3OC7xCWY60SS8jrJ-OrQbrg4PpgpB47wkOIv6cUTLlgRs-6LJfKwHhoU7bceejCNFVG-wmvIzao'),
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
              return Container(
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
                      'Terhubung ke Sensor',
                      style: textTheme.labelSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        IconButton(
          icon: const Icon(LucideIcons.bell),
          color: AppColors.primary,
          onPressed: () {},
        ),
        const SizedBox(width: AppSpacing.sm),
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
