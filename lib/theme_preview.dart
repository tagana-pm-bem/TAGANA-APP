import 'package:flutter/material.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_spacing.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TAGANA Theme Preview'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TAGANA',
              style: textTheme.displayLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Monitoring & Response Application',
              style: textTheme.bodyLarge?.copyWith(
                color: AppColors.mutedForeground,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Typography',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              'Headline Large',
              style: textTheme.headlineLarge,
            ),
            Text(
              'Title Large',
              style: textTheme.titleLarge,
            ),
            Text(
              'Body Large — This is an example of body text.',
              style: textTheme.bodyLarge,
            ),
            Text(
              'Body Medium — Supporting information and metadata.',
              style: textTheme.bodyMedium,
            ),
            Text(
              'Body Small — Caption and smaller information.',
              style: textTheme.bodySmall,
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Buttons',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Primary'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Secondary'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ghost'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Input',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            const TextField(
              decoration: InputDecoration(
                labelText: 'Device name',
                hintText: 'Enter device name',
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Card',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sensors_outlined,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32 Field Device',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Device is currently connected.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              'Semantic Colors',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),

            _StatusTile(
  icon: Icons.check_circle_outline,
  label: 'Success',
  color: AppColors.success,
),
const SizedBox(height: AppSpacing.sm),
_StatusTile(
  icon: Icons.warning_amber_outlined,
  label: 'Warning',
  color: AppColors.warning,
),
const SizedBox(height: AppSpacing.sm),
_StatusTile(
  icon: Icons.error_outline,
  label: 'Destructive',
  color: AppColors.destructive,
),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}