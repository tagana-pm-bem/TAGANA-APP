import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  bool _isRefreshing = false;

  // Dummy available networks
  final List<_WifiNetwork> _networks = const [
    _WifiNetwork(ssid: 'TAGANA Office', signal: _SignalStrength.good, isOpen: false),
    _WifiNetwork(ssid: 'Universitas Network', signal: _SignalStrength.medium, isOpen: false),
    _WifiNetwork(ssid: 'Guest Network', signal: _SignalStrength.weak, isOpen: true),
  ];

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device context card
                _buildDeviceContext(textTheme),
                const SizedBox(height: AppSpacing.lg),

                // Wi-Fi status section
                _buildSectionLabel(textTheme, 'Status Wi-Fi Saat Ini'),
                const SizedBox(height: AppSpacing.sm),
                _buildWifiStatusCard(textTheme),
                const SizedBox(height: AppSpacing.lg),

                // Available networks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel(textTheme, 'Jaringan Wi-Fi Tersedia'),
                    GestureDetector(
                      onTap: _handleRefresh,
                      child: Row(
                        children: [
                          _isRefreshing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                )
                              : const Icon(LucideIcons.refreshCw, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Refresh', style: textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Network list
                ...List.generate(_networks.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < _networks.length - 1 ? AppSpacing.sm : 0),
                    child: _buildNetworkItem(context, textTheme, _networks[i]),
                  );
                }),

                const SizedBox(height: AppSpacing.lg),

                // Manual entry
                _buildManualEntryButton(context, textTheme),
              ],
            ),
          ),

          // Fixed bottom info banner
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildInfoBanner(textTheme),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: AppColors.foreground,
        onPressed: () => context.pop(),
      ),
      title: Column(
        children: [
          Text(
            'Konfigurasi Wi-Fi',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground),
          ),
          Text(
            'Hubungkan perangkat TAGANA ke jaringan Wi-Fi',
            style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
          ),
        ],
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildDeviceContext(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.router, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DEVICE ID', style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground, letterSpacing: 0.8)),
              Row(
                children: [
                  Text(
                    widget.deviceId,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.foreground),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(TGN_0001)',
                    style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(TextTheme textTheme, String label) {
    return Text(
      label.toUpperCase(),
      style: textTheme.labelSmall?.copyWith(
        color: AppColors.mutedForeground,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildWifiStatusCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.wifiOff, size: 22, color: AppColors.mutedForeground),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Belum Terhubung', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.foreground)),
                Text('Perangkat sedang offline', style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const Icon(LucideIcons.info, size: 18, color: AppColors.mutedForeground),
        ],
      ),
    );
  }

  Widget _buildNetworkItem(BuildContext context, TextTheme textTheme, _WifiNetwork network) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showPasswordDialog(context, textTheme, network),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _WifiSignalIcon(strength: network.signal),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(network.ssid, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: AppColors.foreground)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          network.isOpen ? LucideIcons.unlock : LucideIcons.lock,
                          size: 12,
                          color: network.isOpen ? AppColors.success : AppColors.mutedForeground,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          network.isOpen
                              ? 'Terbuka • ${network.signal.label}'
                              : network.signal.label,
                          style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton(
                onPressed: () => _showPasswordDialog(context, textTheme, network),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: AppColors.border),
                ),
                child: Text('Pilih', style: textTheme.labelSmall?.copyWith(color: AppColors.foreground, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntryButton(BuildContext context, TextTheme textTheme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showManualDialog(context, textTheme),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.border),
        ),
        icon: const Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
        label: Text(
          'Tambahkan jaringan secara manual',
          style: textTheme.labelMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, -10)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(LucideIcons.info, size: 16, color: AppColors.mutedForeground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Wi-Fi adalah koneksi utama. Jika tidak tersedia saat darurat, perangkat akan otomatis menggunakan BLE atau Hotspot.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordDialog(BuildContext context, TextTheme textTheme, _WifiNetwork network) {
    final ctrl = TextEditingController();
    bool obscure = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hubungkan ke "${network.ssid}"', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          content: network.isOpen
              ? Text('Jaringan ini terbuka. Lanjutkan koneksi?', style: textTheme.bodyMedium)
              : TextField(
                  controller: ctrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                      onPressed: () => setS(() => obscure = !obscure),
                    ),
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showConnectingSnackbar(context, network.ssid);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hubungkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualDialog(BuildContext context, TextTheme textTheme) {
    final ssidCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    bool obscure = true;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Tambah Jaringan Manual', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ssidCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Jaringan (SSID)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? LucideIcons.eyeOff : LucideIcons.eye, size: 18),
                    onPressed: () => setS(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (ssidCtrl.text.isNotEmpty) _showConnectingSnackbar(context, ssidCtrl.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.primaryForeground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hubungkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectingSnackbar(BuildContext context, String ssid) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menghubungkan ke "$ssid"...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Data models ───────────────────────────────────────────────────────────────

enum _SignalStrength {
  good('Signal Good'),
  medium('Signal Medium'),
  weak('Signal Weak');

  const _SignalStrength(this.label);
  final String label;
}

class _WifiNetwork {
  const _WifiNetwork({required this.ssid, required this.signal, required this.isOpen});
  final String ssid;
  final _SignalStrength signal;
  final bool isOpen;
}

class _WifiSignalIcon extends StatelessWidget {
  const _WifiSignalIcon({required this.strength});
  final _SignalStrength strength;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (strength) {
      case _SignalStrength.good:
        color = AppColors.foreground;
        icon = LucideIcons.wifi;
      case _SignalStrength.medium:
        color = AppColors.mutedForeground;
        icon = LucideIcons.wifi;
      case _SignalStrength.weak:
        color = AppColors.mutedForeground.withValues(alpha: 0.6);
        icon = LucideIcons.wifi;
    }
    return Icon(icon, color: color, size: 22);
  }
}
