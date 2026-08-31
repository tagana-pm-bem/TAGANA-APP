import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tagana_app/core/theme/app_colors.dart';
import 'package:tagana_app/core/widgets/app_version_footer.dart';

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
            child: _buildContentSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/icons/logo.jpg',
          width: 160,
          height: 160,
          errorBuilder: (context, error, stackTrace) =>
              const FlutterLogo(size: 120),
        ),
      ),
    );
  }

  Widget _buildContentSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          SizedBox(
            width: double.infinity,
            child: Text(
              'Diperlukan perangkat TAGANA untuk memulai',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 11),
            ),
          ),
          const AppVersionFooter(),
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
