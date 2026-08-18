import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_header.dart';

class EmailPage extends StatelessWidget {
  const EmailPage({super.key});

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
              Text('Email',
                  style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground)),
              const SizedBox(height: AppSpacing.lg),
              Text('yudha@example.com',
                  style: textTheme.bodyLarge
                      ?.copyWith(color: AppColors.foreground)),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: () {
                  // TODO: implement email edit action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text('Ubah Email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
