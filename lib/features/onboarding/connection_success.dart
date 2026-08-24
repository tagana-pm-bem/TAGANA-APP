import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tagana_app/core/theme/app_colors.dart';
import 'package:tagana_app/features/auth/data/user_repository.dart';

enum StatusTone { success, warning, neutral }

extension on StatusTone {
  Color get fg {
    switch (this) {
      case StatusTone.success:
        return AppColors.success;
      case StatusTone.warning:
        return AppColors.warning;
      case StatusTone.neutral:
        return AppColors.mutedForeground;
    }
  }

  Color get bg {
    switch (this) {
      case StatusTone.success:
        return AppColors.success.withOpacity(0.12);
      case StatusTone.warning:
        return AppColors.warning.withOpacity(0.15);
      case StatusTone.neutral:
        return AppColors.muted;
    }
  }
}

/// One row in the "Ringkasan Perangkat" card, e.g. Bluetooth / Baterai /
/// GPS / WiFi.
class DeviceSummaryItem {
  const DeviceSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.asPill = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final StatusTone tone;

  /// Some values (e.g. battery %) render as plain colored text instead of
  /// a pill badge, matching the mockup.
  final bool asPill;
}

/// Page
/// ---------------------------------------------------------------------
///
/// Route this page from `app_router.dart`, e.g.:
///
/// ```dart
/// GoRoute(
///   path: '/connection-success/:deviceId',
///   builder: (context, state) {
///     final info = state.extra as BluetoothDeviceInfo?;
///     return ConnectionSuccessPage(
///       deviceName: info?.name ?? 'TAGANA',
///       deviceId: state.pathParameters['deviceId'] ?? 'UNKNOWN',
///       onContinue: () => context.go('/dashboard'),
///     );
///   },
/// ),
/// ```
class ConnectionSuccessPage extends StatefulWidget {
  const ConnectionSuccessPage({
    super.key,
    required this.deviceName,
    required this.deviceId,
    this.isOnline = true,
    this.summaryItems = const [],
    this.helperText =
        'Konfigurasikan WiFi dari dashboard untuk mengirim data ke server secara otomatis.',
    this.onContinue,
    this.bleDevice,
  });

  final String deviceName;
  final String deviceId;
  final bool isOnline;
  final BluetoothDevice? bleDevice;

  /// Rows shown in the "Ringkasan Perangkat" card. If empty, a sensible
  final List<DeviceSummaryItem> summaryItems;

  final String helperText;

  /// `context.go('/dashboard')` from the router.
  final VoidCallback? onContinue;

  @override
  State<ConnectionSuccessPage> createState() => _ConnectionSuccessPageState();
}

class _ConnectionSuccessPageState extends State<ConnectionSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;
  late final Animation<double> _popScale;

  String _batteryStatus = 'Menunggu...';
  String _gpsStatus = 'Menunggu...';
  String _wifiStatus = 'Menunggu...';
  StreamSubscription? _bleSub;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _popScale = CurvedAnimation(parent: _popController, curve: Curves.elasticOut);
    _popController.forward();

    // Catat aktivitas BLE terhubung ke Supabase (fire-and-forget, tidak blok UI)
    _logBleConnected();
    _initBle();
  }

  Future<void> _initBle() async {
    final dev = widget.bleDevice;
    if (dev == null) return;
    try {
      // Wajib request MTU besar agar JSON panjang dari ESP32 tidak terpotong
      if (Platform.isAndroid) {
        await dev.requestMtu(256);
      }
      final services = await dev.discoverServices();
      for (final s in services) {
        if (s.uuid.str.toLowerCase() == '4fafc201-1fb5-459e-8fcc-c5c9c331914b') {
          for (final c in s.characteristics) {
            if (c.uuid.str.toLowerCase() == 'beb5483e-36e1-4688-b7f5-ea07361b26a9') {
              await c.setNotifyValue(true);
              _bleSub = c.onValueReceived.listen((val) {
                if (!mounted) return;
                try {
                  final jsonStr = String.fromCharCodes(val);
                  final data = jsonDecode(jsonStr);
                  setState(() {
                    _batteryStatus = data['battery']?.toString() ?? '-';
                    _gpsStatus = (data['gps_valid'] == true) ? 'Tersedia' : 'Mencari sinyal...';
                    final ssid = data['ssid']?.toString();
                    _wifiStatus = (ssid == null || ssid == 'Belum Ada WiFi' || ssid.startsWith('Offline')) ? 'Belum dikonfigurasi' : ssid;
                  });
                } catch (_) {}
              });
            }
          }
        }
      }
    } catch (_) {}
  }

  /// Mencatat event `ble_connected` ke tabel device_activities.
  /// Cari device berdasarkan deviceId (MAC address BLE) atau
  /// device_name yang mengandung nama perangkat.
  Future<void> _logBleConnected() async {
    try {
      final supabase = Supabase.instance.client;

      // Cari device berdasarkan device_name yang cocok dengan nama BLE
      // Nama BLE: "TAGANA_0001" → device_name: "Tas Siaga TGN_0001"
      // Kita gunakan filter contains pada device_name
      final deviceResult = await supabase
          .from('devices')
          .select('id, device_code')
          .eq('user_id', UserRepository.currentUser?.id ?? '')
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (deviceResult == null) return;

      await supabase.from('device_activities').insert({
        'device_id': deviceResult['id'] as String,
        'type': 'ble_connected',
        'title': 'BLE Terhubung',
        'description':
            'Perangkat ${deviceResult['device_code']} terhubung melalui Bluetooth',
        'metadata': {
          'ble_device_id': widget.deviceId,
          'ble_device_name': widget.deviceName,
        },
      });
    } catch (_) {
      // Tidak kritis — logging gagal tidak mengganggu UX
    }
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _popController.dispose();
    super.dispose();
  }

  List<DeviceSummaryItem> get _items {
    if (widget.summaryItems.isNotEmpty) return widget.summaryItems;
    return [
      const DeviceSummaryItem(
        icon: Icons.bluetooth,
        label: 'Bluetooth',
        value: 'Terhubung',
        tone: StatusTone.success,
      ),
      DeviceSummaryItem(
        icon: Icons.battery_std,
        label: 'Baterai',
        value: _batteryStatus,
        tone: _batteryStatus == 'Menunggu...' ? StatusTone.neutral : StatusTone.success,
        asPill: false,
      ),
      DeviceSummaryItem(
        icon: Icons.location_on_outlined,
        label: 'GPS',
        value: _gpsStatus,
        tone: _gpsStatus == 'Tersedia' ? StatusTone.success : StatusTone.warning,
      ),
      DeviceSummaryItem(
        icon: Icons.wifi,
        label: 'WiFi',
        value: _wifiStatus,
        tone: _wifiStatus == 'Belum dikonfigurasi' || _wifiStatus == 'Menunggu...' ? StatusTone.warning : StatusTone.success,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Perangkat Terhubung',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _popScale,
                      child: const _SuccessBadge(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Perangkat Berhasil\nTerhubung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.foreground,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'TAGANA siap memantau kondisi banjir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DeviceCard(
                      name: widget.deviceName,
                      deviceId: widget.deviceId,
                      isOnline: widget.isOnline,
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(items: _items),
                    const SizedBox(height: 16),
                    _HelperBanner(text: widget.helperText),
                  ],
                ),
              ),
            ),
            _ContinueButton(onPressed: widget.onContinue),
          ],
        ),
      ),
    );
  }
}

/// Success checkmark badge with a soft halo behind it
class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.10),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }
}

/// Navy device card (name / id / online badge)
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.name,
    required this.deviceId,
    required this.isOnline,
  });

  final String name;
  final String deviceId;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deviceId,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.mutedForeground.withOpacity(0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isOnline ? AppColors.success : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOnline ? AppColors.success : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Ringkasan Perangkat" summary card
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.items});

  final List<DeviceSummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Perangkat',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) ...[
            _SummaryRow(item: items[i]),
            if (i != items.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.item});

  final DeviceSummaryItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(item.icon, size: 18, color: AppColors.mutedForeground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.foreground,
            ),
          ),
        ),
        if (item.asPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.tone.bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: item.tone.fg,
              ),
            ),
          )
        else
          Text(
            item.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: item.tone.fg,
            ),
          ),
      ],
    );
  }
}

/// Info banner
class _HelperBanner extends StatelessWidget {
  const _HelperBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.foreground.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lanjutkan ke Dashboard',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 8),
              Icon(Icons.dashboard_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}