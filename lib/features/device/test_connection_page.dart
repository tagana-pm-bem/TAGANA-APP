import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class TestConnectionPage extends StatelessWidget {
  const TestConnectionPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          color: AppColors.primary,
          onPressed: () => context.pop(),
        ),
        title: Text('Uji Koneksi', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.border, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Text('Uji Koneksi', style: textTheme.headlineLarge?.copyWith(color: AppColors.foreground, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            Text('Periksa koneksi perangkat TAGANA', style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground)),
            const SizedBox(height: AppSpacing.lg),
            // Device Status Section (replicated from HTML)
            _deviceStatusSection(textTheme),
            const SizedBox(height: AppSpacing.lg),
            // Result State Section (Success placeholder)
            _resultStateSection(context, textTheme),
            const SizedBox(height: AppSpacing.lg),
            // Connection Test Process
            _connectionProcessSection(textTheme),
          ],
        ),
      ),
    );
  }

  Widget _deviceStatusSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TAGANA-001', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground)),
                  Text('ID: TGN_0001', style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground)),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x8010B981), blurRadius: 4)]),
                  ),
                  const SizedBox(width: 8),
                  Text('Terhubung', style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('Terakhir diperbarui: Beberapa detik lalu', style: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultStateSection(BuildContext context, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Text('Koneksi Normal', style: textTheme.headlineMedium?.copyWith(color: AppColors.foreground)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Perangkat dapat berkomunikasi dengan aplikasi dengan baik.', style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground)),
          const SizedBox(height: AppSpacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 2.5,
            children: [
              _statusTile(textTheme, label: 'Bluetooth LE', value: 'Normal'),
              _statusTile(textTheme, label: 'Wi‑Fi', value: 'Normal'),
              _statusTile(textTheme, label: 'Sinkronisasi', value: 'Normal'),
              _statusTile(textTheme, label: 'Data', value: 'Diterima'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryForeground, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Selesai'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Uji Lagi'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusTile(TextTheme textTheme, {required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground)),
          Text(value, style: textTheme.labelSmall?.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _connectionProcessSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pemeriksaan Koneksi', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground)),
          const SizedBox(height: AppSpacing.sm),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.primaryForeground, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), disabledBackgroundColor: AppColors.primary.withOpacity(0.5), disabledForegroundColor: AppColors.primaryForeground),
            child: const Text('Mulai Uji Koneksi'),
          ),
          const SizedBox(height: AppSpacing.md),
          // Steps list
          _stepItem(textTheme, number: 1, title: 'Memeriksa perangkat', done: true),
          _stepItem(textTheme, number: 2, title: 'Memeriksa Bluetooth LE', done: true),
          _stepItem(textTheme, number: 3, title: 'Memeriksa Wi‑Fi', active: true),
          _stepItem(textTheme, number: 4, title: 'Memeriksa komunikasi data', pending: true),
        ],
      ),
    );
  }

  Widget _stepItem(TextTheme textTheme, {required int number, required String title, bool done = false, bool active = false, bool pending = false}) {
    Color circleColor;
    Widget inner;
    if (done) {
      circleColor = AppColors.success;
      inner = const Icon(LucideIcons.check, color: AppColors.onPrimary, size: 16);
    } else if (active) {
      circleColor = AppColors.primary;
      inner = const Icon(LucideIcons.loader, color: AppColors.onPrimary, size: 16);
    } else {
      circleColor = AppColors.card;
      inner = Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.outlineVariant, shape: BoxShape.circle));
    }
    Color textColor = done ? AppColors.success : (active ? AppColors.primary : AppColors.mutedForeground);
    String status = done ? 'Selesai' : (active ? 'Memeriksa...' : 'Menunggu');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: circleColor, shape: BoxShape.circle, border: Border.all(color: AppColors.border)),
            child: Center(child: inner),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.bodyMedium?.copyWith(color: textColor)),
              Text(status, style: textTheme.labelSmall?.copyWith(color: textColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
