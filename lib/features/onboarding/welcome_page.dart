import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tagana_app/core/theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeroSection(),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: _buildContentSheet(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background hero image
          Image.asset(
            'assets/images/flood_monitor_hero.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: AppColors.primary),
          ),
          // Gradient overlay (navy, sesuai desain)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.5),
                  AppColors.primary.withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Logo mark + judul
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryForeground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.waves, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'TAGANA',
                  style: TextStyle(
                    color: AppColors.primaryForeground,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Flood Monitor',
                  style: TextStyle(
                    color: AppColors.primaryForeground.withOpacity(0.7),
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'TAGANA Flood Monitor',
            style: TextStyle(
              color: AppColors.foreground,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pantau kondisi perangkat dan ketinggian air secara real-time.',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          const _FeatureRow(
            icon: Icons.waves,
            label: 'Pemantauan ketinggian air real-time',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.bluetooth,
            label: 'Koneksi langsung ke perangkat ESP32',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.notifications_none,
            label: 'Notifikasi peringatan banjir otomatis',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go('/register');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Mulai',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Diperlukan perangkat TAGANA untuk memulai',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.foreground, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
