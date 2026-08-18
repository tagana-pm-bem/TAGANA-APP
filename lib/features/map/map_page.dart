import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String? _selectedDeviceId;

  void _onMarkerTapped(String deviceId) {
    setState(() {
      _selectedDeviceId = deviceId;
    });
  }

  void _closePreview() {
    setState(() {
      _selectedDeviceId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Map Background Placeholder
          _buildMapBackground(),

          // 2. Map Markers
          _buildMarkers(),

          // 3. Top Controls (Header, Search, Filters)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSearchBar(textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStatusFilters(textTheme),
                ],
              ),
            ),
          ),

          // 4. Map Controls (Right Side)
          Positioned(
            right: AppSpacing.md,
            bottom: _selectedDeviceId != null ? 220 : 120, // Adjust based on preview card visibility
            child: _buildMapControls(),
          ),

          // 5. Legend (Bottom Left)
          Positioned(
            left: AppSpacing.md,
            bottom: _selectedDeviceId != null ? 220 : 120,
            child: _buildLegend(textTheme),
          ),

          // 6. Device Preview Card
          if (_selectedDeviceId != null)
            Positioned(
              bottom: 80, // Above bottom nav
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: _buildDevicePreviewCard(context, textTheme),
            ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.6,
        child: Image.network(
          'https://lh3.googleusercontent.com/aida-public/AB6AXuALtC_NJYyKix7AO9PhaUwWGR0hzyapQH4p-y23ZNlvTuzAE5_Nsl7extSI_S-rtV7HqqSSyNl18H72BQgovfXyKKe0q9IfeM2uM8Se67kXt-4yAiS6JvLrs4yubWotEgYnYYu-knGqNSIcdNCoWke2nYFM6PiK12qpfvQwJT5EdTgrryv1OnBcy_MvsweUv34j6Ymbb18EMrnKSaBIvXbm_kkEntDg_Lg0rFi4m7qUwHDy3QAHFV8n',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.blueGrey.shade100);
          },
        ),
      ),
    );
  }

  Widget _buildMarkers() {
    return Stack(
      children: [
        // Marker TAGANA-001 (Normal)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.35,
          left: MediaQuery.of(context).size.width * 0.25,
          child: _buildMarker(
            id: 'TAGANA-001',
            color: Colors.green.shade500,
          ),
        ),
        // Marker TAGANA-002 (Normal)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.5,
          left: MediaQuery.of(context).size.width * 0.35,
          child: _buildMarker(
            id: 'TAGANA-002',
            color: Colors.green.shade500,
          ),
        ),
        // Marker TAGANA-003 (Peringatan)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.65,
          right: MediaQuery.of(context).size.width * 0.3,
          child: _buildMarker(
            id: 'TAGANA-003',
            color: Colors.yellow.shade600,
          ),
        ),
        // Marker TAGANA-004 (Tidak Terhubung)
        Positioned(
          top: MediaQuery.of(context).size.height * 0.25,
          right: MediaQuery.of(context).size.width * 0.25,
          child: _buildMarker(
            id: 'TAGANA-004',
            color: AppColors.mutedForeground,
            textColor: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildMarker({
    required String id,
    required Color color,
    Color textColor = AppColors.foreground,
  }) {
    final isSelected = _selectedDeviceId == id;
    return GestureDetector(
      onTap: () => _onMarkerTapped(id),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              id,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: textColor,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: isSelected ? 20 : 16,
            height: isSelected ? 20 : 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.card, width: 2),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peta TAGANA',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            'Pantau lokasi perangkat TAGANA',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.mutedForeground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari perangkat atau lokasi...',
                hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.mutedForeground),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilters(TextTheme textTheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(textTheme, 'Semua', isActive: true),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Normal'),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Peringatan'),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Kritis'),
          const SizedBox(width: AppSpacing.xs),
          _buildFilterChip(textTheme, 'Tidak Terhubung'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TextTheme textTheme, String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryContainer : AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: isActive ? null : Border.all(color: AppColors.border),
        boxShadow: [
          if (!isActive)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: isActive ? AppColors.primaryForeground : AppColors.foreground,
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(LucideIcons.crosshair),
            color: AppColors.foreground,
            onPressed: () {},
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              IconButton(
                icon: const Icon(LucideIcons.plus),
                color: AppColors.foreground,
                onPressed: () {},
              ),
              Container(height: 1, width: 40, color: AppColors.border),
              IconButton(
                icon: const Icon(LucideIcons.minus),
                color: AppColors.foreground,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem(textTheme, 'Normal', Colors.green.shade500),
          const SizedBox(height: 4),
          _buildLegendItem(textTheme, 'Peringatan', Colors.yellow.shade600),
          const SizedBox(height: 4),
          _buildLegendItem(textTheme, 'Kritis', Colors.red.shade600),
          const SizedBox(height: 4),
          _buildLegendItem(textTheme, 'Offline', AppColors.mutedForeground),
        ],
      ),
    );
  }

  Widget _buildLegendItem(TextTheme textTheme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(color: AppColors.foreground),
        ),
      ],
    );
  }

  Widget _buildDevicePreviewCard(BuildContext context, TextTheme textTheme) {
    // Generate dummy info based on the selected ID
    bool isWarning = _selectedDeviceId == 'TAGANA-003';
    bool isOffline = _selectedDeviceId == 'TAGANA-004';
    
    String status = 'Normal / Terhubung';
    Color statusColor = Colors.green.shade500;
    
    if (isWarning) {
      status = 'Peringatan Baterai';
      statusColor = Colors.yellow.shade700;
    } else if (isOffline) {
      status = 'Tidak Terhubung';
      statusColor = AppColors.mutedForeground;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDeviceId!,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.foreground,
                    ),
                  ),
                  Text(
                    'TGN_${_selectedDeviceId!.split('-').last}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(LucideIcons.x),
                color: AppColors.mutedForeground,
                onPressed: _closePreview,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembaruan Terakhir',
                      style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOffline ? '1 jam lalu' : '2 menit lalu',
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.foreground),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => context.push('/device/$_selectedDeviceId'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tampilkan Detail'),
          ),
        ],
      ),
    );
  }
}