import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _accepted = false;

  Future<void> _onContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_accepted_privacy', true);
    if (!mounted) return;
    // Lanjut ke rute selanjutnya, default ke login
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Icon(Icons.privacy_tip, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Kebijakan Privasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.foreground,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Harap baca dan setujui kebijakan privasi sebelum menggunakan aplikasi TAGANA.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedForeground,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: Text(
                  '1. Pengumpulan Data\n'
                  'Aplikasi TAGANA mengumpulkan data telemetri sensor (ketinggian air, status baterai) '
                  'serta lokasi perangkat untuk tujuan mitigasi bencana.\n\n'
                  '2. Penggunaan Data\n'
                  'Data yang dikumpulkan hanya digunakan untuk memantau status alat secara real-time '
                  'dan memberikan notifikasi peringatan dini kepada pengguna terkait.\n\n'
                  '3. Keamanan\n'
                  'Kami menjaga keamanan data Anda dengan menggunakan infrastruktur server yang aman '
                  '(Supabase). Data Anda tidak akan dibagikan kepada pihak ketiga tanpa izin.\n\n'
                  '4. Persetujuan\n'
                  'Dengan menggunakan aplikasi ini, Anda menyetujui pengumpulan dan penggunaan informasi '
                  'seperti yang dijelaskan dalam kebijakan ini.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.foreground,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (val) {
                          setState(() {
                            _accepted = val ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _accepted = !_accepted;
                            });
                          },
                          child: Text(
                            'Saya setuju dengan Kebijakan Privasi di atas',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.foreground,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _accepted ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        disabledBackgroundColor: AppColors.muted,
                        disabledForegroundColor: AppColors.mutedForeground,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
