import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Center(
        child: Text(
          'Versi 1.0.0 (BETA)',
          style: TextStyle(
            color: AppColors.mutedForeground.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
