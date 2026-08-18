import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppSpacing.md,
      title: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAhbGHh_GiUxKOnhs8Shlqj_Ml-e7D9w54Ee7CAtkMSfvl4Nu2Dhs7q0y8qaTwGGYmeGti8pFQZh5gUV2eFjQR0mQveRZwblPnlwO0M51EegFdEKY-O2UblCcvbVJrPqyWnQAbWUWECAhHCOq0pPZKUIdPmCaFnlXu7YtNIGY7oM3OC7xCWY60SS8jrJ-OrQbrg4PpgpB47wkOIv6cUTLlgRs-6LJfKwHhoU7bceejCNFVG-wmvIzao'),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'TAGANA',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
      actions: [
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
