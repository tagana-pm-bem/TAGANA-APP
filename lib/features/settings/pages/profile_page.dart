import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const String userName = 'Yudha';
    const String userEmail = 'yudha@example.com';
    const String avatarUrl =
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA3Kja-5loOn0yDsu4GJ_va683woaMvhMwz_WkBVgbgYZu_VIxqDsgmCBq2Vl3aYn7NY4O2TfclqE2xloEi5eMOxpMnoAgqkUqPabJA-ynTisg8EpiKAivdLV2gMruY266b0NcxhHSB2JO_5mTwDKywkCXheWc8eSfdj5ffcku4V0kRLBroO30ESGYhGkc5Pt-MzSNctTpKwmzsh6ledJ00OOixr-90xJFDL19RDAsLRi53PrR2dt6J';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Profil'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Nama', style: textTheme.labelMedium?.copyWith(color: AppColors.mutedForeground)),
              Text(userName, style: textTheme.titleLarge?.copyWith(color: AppColors.foreground)),
              const SizedBox(height: AppSpacing.md),
              Text('Email', style: textTheme.labelMedium?.copyWith(color: AppColors.mutedForeground)),
              Text(userEmail, style: textTheme.bodyLarge?.copyWith(color: AppColors.foreground)),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => context.push('/settings/edit-profile'),
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('Edit Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
