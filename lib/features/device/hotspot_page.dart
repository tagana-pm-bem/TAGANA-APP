import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const String _kTaganaSSID = 'Tagana-AP';

class HotspotPage extends StatefulWidget {
  const HotspotPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<HotspotPage> createState() => _HotspotPageState();
}

class _HotspotPageState extends State<HotspotPage> {
  String? _currentSsid;
  bool _isLoadingAction = false;
  bool _isScanning = false;
  Timer? _pollingTimer;

  bool get _isConnectedToTagana => _currentSsid == _kTaganaSSID;

  @override
  void initState() {
    super.initState();
    _refreshWifiStatus();
    // Poll SSID setiap 3 detik
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshWifiStatus(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshWifiStatus({bool showLoading = false}) async {
    if (showLoading && mounted) setState(() => _isScanning = true);
    try {
      final ssid = await WiFiForIoTPlugin.getSSID();
      if (mounted) {
        setState(() {
          // Android membungkus SSID dengan tanda kutip, iOS tidak
          _currentSsid = ssid?.replaceAll('"', '');
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _disconnectWifi() async {
    if (Platform.isIOS) {
      _showIosGuideDialog();
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Putuskan Wi-Fi?'),
        content: Text(
          'Koneksi ke "$_currentSsid" akan diputus agar kamu bisa terhubung ke jaringan $_kTaganaSSID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Putuskan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoadingAction = true);
    try {
      await WiFiForIoTPlugin.disconnect();
      await Future.delayed(const Duration(milliseconds: 800));
      await _refreshWifiStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Wi-Fi diputus. Sekarang sambungkan ke "Tagana-AP" di pengaturan Wi-Fi HP kamu.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memutus Wi-Fi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  void _showIosGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cara Terhubung ke Tagana-AP'),
        content: const Text(
          'Di iOS, buka Settings → Wi-Fi, lalu pilih "Tagana-AP" untuk '
          'terhubung ke hotspot perangkat TAGANA.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _openLocalWeb() {
    context.push('/device/${widget.deviceId}/local-web');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, textTheme),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCurrentWifiCard(textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildHotspotSection(context, textTheme),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInfoNote(textTheme),
                  if (_isConnectedToTagana) ...[
                    const SizedBox(height: AppSpacing.md),
                    _buildOpenWebButton(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomAction(textTheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, TextTheme textTheme) {
    return AppBar(
      backgroundColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft),
        color: AppColors.mutedForeground,
        onPressed: () => context.pop(),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hotspot TAGANA',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Mode Darurat – Akses Web Lokal',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: AppColors.border,
          height: 1.0,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
    );
  }

  // ── Kartu status WiFi saat ini ──
  Widget _buildCurrentWifiCard(TextTheme textTheme) {
    final isConnected = _currentSsid != null && _currentSsid!.isNotEmpty;
    final statusColor =
        _isConnectedToTagana ? Colors.green.shade700 : Colors.orange.shade700;
    final bgColor =
        _isConnectedToTagana ? Colors.green.shade50 : Colors.orange.shade50;
    final icon = _isConnectedToTagana ? LucideIcons.wifi : LucideIcons.wifi;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnectedToTagana
              ? Colors.green.shade200
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wi-Fi Aktif',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedForeground,
                    letterSpacing: 1.1,
                  ),
                ),
                if (_isScanning)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Text(
                    isConnected ? (_currentSsid ?? '—') : 'Tidak terhubung',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                if (_isConnectedToTagana)
                  Text(
                    '✓ Siap akses web lokal',
                    style: textTheme.labelSmall
                        ?.copyWith(color: Colors.green.shade600),
                  ),
              ],
            ),
          ),
          // Tombol putuskan WiFi (jika terhubung ke WiFi lain)
          if (isConnected && !_isConnectedToTagana)
            _isLoadingAction
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: _disconnectWifi,
                    icon: const Icon(LucideIcons.wifiOff, size: 14),
                    label: const Text('Putuskan'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }

  // ── Daftar hotspot ──
  Widget _buildHotspotSection(BuildContext context, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Hotspot Perangkat',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
          ),
        ),
        _buildHotspotItem(textTheme),
      ],
    );
  }

  Widget _buildHotspotItem(TextTheme textTheme) {
    final isConnected = _isConnectedToTagana;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final isSmall = constraints.maxWidth < 400;

          final infoContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  LucideIcons.router,
                  color: isConnected ? Colors.green.shade700 : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _kTaganaSSID,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.foreground,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Emergency',
                            style: textTheme.labelSmall
                                ?.copyWith(color: AppColors.destructive),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isConnected
                              ? LucideIcons.checkCircle
                              : LucideIcons.alertCircle,
                          size: 13,
                          color: isConnected
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'Terhubung' : 'Belum terhubung',
                          style: textTheme.labelSmall?.copyWith(
                            color: isConnected
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButton = isConnected
              ? ElevatedButton.icon(
                  onPressed: _openLocalWeb,
                  icon: const Icon(LucideIcons.globe, size: 14),
                  label: const Text('Buka Web Lokal'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: _showConnectGuide,
                  icon: const Icon(LucideIcons.wifi, size: 14),
                  label: const Text('Cara Konek'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoContent,
                const SizedBox(height: AppSpacing.md),
                actionButton,
              ],
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: infoContent),
                const SizedBox(width: AppSpacing.md),
                actionButton,
              ],
            );
          }
        },
      ),
    );
  }

  void _showConnectGuide() {
    final isIos = Platform.isIOS;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cara Terhubung ke Tagana-AP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ikuti langkah berikut:'),
            const SizedBox(height: 12),
            _guideStep('1', isIos
                ? 'Buka Settings → Wi-Fi'
                : 'Buka Pengaturan → Wi-Fi / Jaringan'),
            _guideStep('2', 'Cari dan pilih jaringan "Tagana-AP"'),
            _guideStep('3', 'Tidak ada password (jaringan terbuka)'),
            _guideStep('4', 'Kembali ke app ini, lalu tap "Buka Web Lokal"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _guideStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Tombol buka WebView (muncul hanya saat konek ke Tagana-AP) ──
  Widget _buildOpenWebButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openLocalWeb,
        icon: const Icon(LucideIcons.monitorSmartphone, size: 18),
        label: const Text('Buka Telemetri Web Lokal (192.168.4.1)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildInfoNote(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: Colors.indigo, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.mutedForeground),
                children: [
                  const TextSpan(
                    text:
                        'Mode ini aktif saat tidak ada internet dan BLE tidak tersedia. '
                        'Hubungkan HP ke hotspot ',
                  ),
                  TextSpan(
                    text: 'Tagana-AP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ' (tanpa password), lalu buka web lokal untuk melihat data telemetri secara real-time.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isScanning
                ? null
                : () => _refreshWifiStatus(showLoading: true),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.muted,
              foregroundColor: AppColors.foreground,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.refreshCw, size: 16),
            label: Text(_isScanning ? 'Memeriksa...' : 'Cek Status Wi-Fi'),
          ),
        ),
      ),
    );
  }
}
