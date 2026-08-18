import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Profil', style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuA3Kja-5loOn0yDsu4GJ_va683woaMvhMwz_WkBVgbgYZu_VIxqDsgmCBq2Vl3aYn7NY4O2TfclqE2xloEi5eMOxpMnoAgqkUqPabJA-ynTisg8EpiKAivdLV2gMruY266b0NcxhHSB2JO_5mTwDKywkCXheWc8eSfdj5ffcku4V0kRLBroO30ESGYhGkc5Pt-MzSNctTpKwmzsh6ledJ00OOixr-90xJFDL19RDAsLRi53PrR2dt6J')
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Yudha', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('yudha@example.com'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
