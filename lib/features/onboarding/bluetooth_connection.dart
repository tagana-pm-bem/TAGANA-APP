import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tagana_app/core/theme/app_colors.dart';

enum ConnectionStep { adapterOff, searching, found, connecting, connected, failed }

class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.name,
    required this.deviceId,
    required this.rssi,
    required this.device,
  });

  /// Wraps a real scan result coming from `flutter_blue_plus`.
  factory BluetoothDeviceInfo.fromScanResult(ScanResult result) {
    final advName = result.advertisementData.advName;
    return BluetoothDeviceInfo(
      name: advName.isNotEmpty ? advName : result.device.platformName,
      deviceId: result.device.remoteId.str,
      rssi: result.rssi,
      device: result.device,
    );
  }

  final String name;
  final String deviceId;
  final int rssi; // dBm, e.g. -72

  /// The underlying BLE device handle used to actually connect.
  final BluetoothDevice device;

  String get rssiLabel => '$rssi dBm';

  @override
  bool operator ==(Object other) =>
      other is BluetoothDeviceInfo && other.deviceId == deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({
    super.key,
    this.deviceNamePrefix = 'TAGANA',
    this.onConnected,
  });

  /// Devices whose name starts with this prefix are treated as valid
  /// TAGANA devices and shown in the "found" list.
  final String deviceNamePrefix;

  /// Called once the (simulated) connection succeeds.
  final ValueChanged<BluetoothDeviceInfo>? onConnected;

  @override
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage>
    with SingleTickerProviderStateMixin {
  ConnectionStep _step = ConnectionStep.searching;
  BluetoothDeviceInfo? _selectedDevice;
  String? _errorMessage;

  final List<BluetoothDeviceInfo> _foundDevices = [];

  late final AnimationController _pulseController;

  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<List<ScanResult>>? _scanResultsSub;
  StreamSubscription<bool>? _isScanningSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;


  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _init();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _adapterSub?.cancel();
    _scanResultsSub?.cancel();
    _isScanningSub?.cancel();
    _connectionSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // -- Real BLE flow (flutter_blue_plus) ----------------------------------

  Future<void> _init() async {
    // Ask for the runtime permissions BLE scanning/connecting needs.
    final granted = await _ensurePermissions();
    if (!granted) {
      setState(() {
        _step = ConnectionStep.failed;
        _errorMessage =
            'Izin Bluetooth & Lokasi diperlukan untuk mencari perangkat.';
      });
      return;
    }

    // React whenever the phone's Bluetooth adapter itself is turned on/off.
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothAdapterState.on) {
        if (_step == ConnectionStep.adapterOff) _startScan();
      } else {
        setState(() {
          _step = ConnectionStep.adapterOff;
          _foundDevices.clear();
        });
      }
    });

    final currentState = await FlutterBluePlus.adapterState.first;
    if (currentState == BluetoothAdapterState.on) {
      _startScan();
    } else {
      setState(() => _step = ConnectionStep.adapterOff);
    }
  }

  /// On Android 12+, BLE scanning/connecting needs BLUETOOTH_SCAN /
  /// BLUETOOTH_CONNECT. Older Android also needs location. iOS only needs
  /// the Info.plist usage-description strings (no runtime prompt here).
  Future<bool> _ensurePermissions() async {
    if (kIsWeb) return true;

    if (!Platform.isAndroid) return true; // iOS uses Info.plist entries

    // Request permissions individually so the runtime prompt is shown.
    final scan = await Permission.bluetoothScan.request();
    final connect = await Permission.bluetoothConnect.request();
    final location = await Permission.locationWhenInUse.request();

    final granted = (scan.isGranted || scan.isLimited) &&
        (connect.isGranted || connect.isLimited) &&
        (location.isGranted || location.isLimited);

    if (!granted) {
      // If denied or permanently denied, prompt user to open settings.
      if (!mounted) return false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Izin diperlukan'),
          content: const Text(
              'Aplikasi memerlukan izin Bluetooth dan lokasi untuk mencari perangkat. Harap aktifkan izin di pengaturan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.of(ctx).pop();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
    }

    return granted;
  }

  Future<void> _turnOnBluetoothIfPossible() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        // User declined the system prompt — nothing more we can do here.
      }
    } else {
      // iOS doesn't allow programmatically enabling Bluetooth.
      setState(() {
        _errorMessage = 'Aktifkan Bluetooth lewat Pengaturan perangkat Anda.';
      });
    }
  }

  void _startScan() {
    setState(() {
      _step = ConnectionStep.searching;
      _errorMessage = null;
      _foundDevices.clear();
      _selectedDevice = null;
    });

    _scanResultsSub?.cancel();
    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;

      final matches = results
          .where((r) {
            final name = r.advertisementData.advName.isNotEmpty
                ? r.advertisementData.advName
                : r.device.platformName;
            return name.startsWith(widget.deviceNamePrefix);
          })
          .map(BluetoothDeviceInfo.fromScanResult)
          .toList();

      if (matches.isEmpty) return;

      setState(() {
        for (final m in matches) {
          final idx = _foundDevices.indexWhere((d) => d.deviceId == m.deviceId);
          if (idx == -1) {
            _foundDevices.add(m);
          } else {
            _foundDevices[idx] = m; // refresh RSSI
          }
        }
        if (_step == ConnectionStep.searching) _step = ConnectionStep.found;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _step = ConnectionStep.failed;
        _errorMessage = 'Gagal memindai perangkat.';
      });
    });

    _isScanningSub?.cancel();
    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() {});

      final scanTimedOutEmpty =
          !scanning && _step == ConnectionStep.searching && _foundDevices.isEmpty;
      if (scanTimedOutEmpty) {
        setState(() {
          _step = ConnectionStep.failed;
          _errorMessage =
              'Perangkat ${widget.deviceNamePrefix} tidak ditemukan. Coba lagi.';
        });
      }
    });

    FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      androidUsesFineLocation: true,
    ).catchError((_) {
      if (!mounted) return;
      setState(() {
        _step = ConnectionStep.failed;
        _errorMessage = 'Tidak dapat memulai pemindaian.';
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDeviceInfo info) async {
    FlutterBluePlus.stopScan();

    setState(() {
      _selectedDevice = info;
      _step = ConnectionStep.connecting;
      _errorMessage = null;
    });

    _connectionSub?.cancel();
    _connectionSub = info.device.connectionState.listen((state) {
      if (!mounted) return;
      if (state == BluetoothConnectionState.connected) {
        setState(() => _step = ConnectionStep.connected);
        widget.onConnected?.call(info);
      } else if (state == BluetoothConnectionState.disconnected &&
          _step == ConnectionStep.connecting) {
        setState(() {
          _step = ConnectionStep.failed;
          _errorMessage = 'Koneksi terputus, coba lagi.';
        });
      }
    });

    try {
      await info.device.connect(
        autoConnect: false,
        timeout: const Duration(seconds: 12),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _step = ConnectionStep.failed;
        _errorMessage = 'Gagal menghubungkan ke perangkat.';
      });
    }
  }

  void _cancel() {
    FlutterBluePlus.stopScan();
    _selectedDevice?.device.disconnect();
    Navigator.of(context).maybePop();
  }

  void _retry() {
    if (_step == ConnectionStep.failed && _selectedDevice != null) {
      _connectToDevice(_selectedDevice!);
    } else {
      _startScan();
    }
  }

  // -- UI -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _PulsingBluetoothIcon(
                      controller: _pulseController,
                      isActive: _step == ConnectionStep.searching ||
                          _step == ConnectionStep.found ||
                          _step == ConnectionStep.connecting,
                    ),
                    const SizedBox(height: 20),
                    _StatusChip(step: _step),
                    const SizedBox(height: 16),
                    Text(
                      _titleForStep(_step),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ??
                          'Pastikan Bluetooth aktif dan perangkat ${widget.deviceNamePrefix} berada di dekat Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: _errorMessage != null
                            ? AppColors.destructive
                            : AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_step == ConnectionStep.adapterOff)
                      _AdapterOffCard(onTurnOn: _turnOnBluetoothIfPossible)
                    else if (_foundDevices.isEmpty && _step == ConnectionStep.searching)
                      const _SearchingPlaceholder()
                    else
                      ..._foundDevices.map(
                        (d) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DeviceCard(
                            device: d,
                            isSelected: _selectedDevice?.deviceId == d.deviceId,
                            step: _step,
                            onTap: _step == ConnectionStep.found
                                ? () => _connectToDevice(d)
                                : null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _StepList(step: _step),
                    const SizedBox(height: 20),
                    const _InfoBanner(),
                  ],
                ),
              ),
            ),
            _BottomActions(
              step: _step,
              device: _selectedDevice ?? _foundDevices.firstOrNullSafe(),
              onConnect: () {
                final device = _selectedDevice ?? _foundDevices.firstOrNullSafe();
                if (device != null) _connectToDevice(device);
              },
              onCancel: _cancel,
              onDone: () => Navigator.of(context).maybePop(true),
              onRetry: _retry,
            ),
          ],
        ),
      ),
    );
  }

  String _titleForStep(ConnectionStep step) {
    switch (step) {
      case ConnectionStep.adapterOff:
        return 'Bluetooth Tidak Aktif';
      case ConnectionStep.searching:
        return 'Mencari Perangkat Bluetooth';
      case ConnectionStep.found:
        return 'Perangkat Ditemukan';
      case ConnectionStep.connecting:
        return 'Menghubungkan Bluetooth';
      case ConnectionStep.connected:
        return 'Bluetooth Terhubung';
      case ConnectionStep.failed:
        return 'Gagal Terhubung';
    }
  }
}

extension _FirstOrNull<T> on List<T> {
  T? firstOrNullSafe() => isEmpty ? null : first;
}

/// ---------------------------------------------------------------------
/// Header
/// ---------------------------------------------------------------------
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          ),
          const SizedBox(width: 4),
          const Text(
            'Hubungkan melalui Bluetooth',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Pulsing bluetooth icon
/// ---------------------------------------------------------------------
class _PulsingBluetoothIcon extends StatelessWidget {
  const _PulsingBluetoothIcon({
    required this.controller,
    required this.isActive,
  });

  final AnimationController controller;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final t = controller.value; // 0..1
          return Stack(
            alignment: Alignment.center,
            children: [
              if (isActive) ...[
                _ring(baseSize: 160, t: t, delay: 0.0),
                _ring(baseSize: 160, t: t, delay: 0.33),
                _ring(baseSize: 160, t: t, delay: 0.66),
              ] else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withOpacity(0.12),
                  ),
                ),
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppColors.navy : AppColors.success,
                  boxShadow: [
                    BoxShadow(
                      color: (isActive ? AppColors.navy : AppColors.success)
                          .withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isActive ? Icons.bluetooth : Icons.bluetooth_connected,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring({required double baseSize, required double t, required double delay}) {
    // Three staggered rings expanding outward and fading.
    final localT = (t + delay) % 1.0;
    final size = 84 + (baseSize - 84) * localT;
    final opacity = (1.0 - localT).clamp(0.0, 1.0) * 0.5;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.navy.withOpacity(opacity),
          width: 1.5,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Status chip ("Mencari perangkat...")
/// ---------------------------------------------------------------------
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.step});

  final ConnectionStep step;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final IconData icon;
    late final Color fg;
    late final Color bg;

    switch (step) {
      case ConnectionStep.adapterOff:
        label = 'Bluetooth mati';
        icon = Icons.bluetooth_disabled;
        fg = AppColors.destructive;
        bg = AppColors.destructive.withOpacity(0.1);
        break;
      case ConnectionStep.searching:
        label = 'Mencari perangkat...';
        icon = Icons.search;
        fg = AppColors.primary;
        bg = AppColors.navyLight;
        break;
      case ConnectionStep.found:
        label = 'Perangkat ditemukan';
        icon = Icons.check_circle_outline;
        fg = AppColors.success;
        bg = AppColors.success.withOpacity(0.1);
        break;
      case ConnectionStep.connecting:
        label = 'Menghubungkan...';
        icon = Icons.bluetooth_searching;
        fg = AppColors.primary;
        bg = AppColors.navyLight;
        break;
      case ConnectionStep.connected:
        label = 'Terhubung';
        icon = Icons.check_circle;
        fg = AppColors.success;
        bg = AppColors.success.withOpacity(0.1);
        break;
      case ConnectionStep.failed:
        label = 'Gagal terhubung';
        icon = Icons.error_outline;
        fg = AppColors.destructive;
        bg = AppColors.destructive.withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder card shown while nothing has been found yet.
class _SearchingPlaceholder extends StatelessWidget {
  const _SearchingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Memindai perangkat di sekitar...',
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}

/// Shown when the phone's Bluetooth radio itself is switched off.
class _AdapterOffCard extends StatelessWidget {
  const _AdapterOffCard({required this.onTurnOn});

  final VoidCallback onTurnOn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.bluetooth_disabled, color: AppColors.destructive, size: 28),
          const SizedBox(height: 10),
          const Text(
            'Bluetooth di perangkat Anda sedang mati.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTurnOn,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Aktifkan Bluetooth'),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Device card (list item for a discovered device)
/// ---------------------------------------------------------------------
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.isSelected,
    required this.step,
    required this.onTap,
  });

  final BluetoothDeviceInfo device;
  final bool isSelected;
  final ConnectionStep step;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final highlighted = isSelected &&
        (step == ConnectionStep.connecting || step == ConnectionStep.connected);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlighted ? AppColors.navy : AppColors.border,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings, color: AppColors.foreground, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    device.deviceId,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    step == ConnectionStep.connected ? 'Terhubung' : 'Ditemukan',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  device.rssiLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Step list (Mencari perangkat / Perangkat ditemukan / Menghubungkan /
/// ---------------------------------------------------------------------
class _StepList extends StatelessWidget {
  const _StepList({required this.step});

  final ConnectionStep step;

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Mencari perangkat',
      'Perangkat ditemukan',
      'Menghubungkan...',
      'Bluetooth terhubung',
    ];

    // Map current ConnectionStep -> index of the "active" step (0-based).
    final activeIndex = switch (step) {
      ConnectionStep.adapterOff => 0,
      ConnectionStep.searching => 0,
      ConnectionStep.found => 1,
      ConnectionStep.connecting => 2,
      ConnectionStep.connected => 3,
      ConnectionStep.failed => 2,
    };

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = i < activeIndex || (step == ConnectionStep.connected);
        final isActive = i == activeIndex && step != ConnectionStep.connected;
        final isLast = i == steps.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _StepDot(isDone: isDone, isActive: isActive),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone ? AppColors.success : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 2),
                child: Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isDone || isActive
                        ? AppColors.foreground
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.isDone, required this.isActive});

  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: AppColors.navy,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.muted,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Info banner
/// ---------------------------------------------------------------------
class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

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
              'Jika perangkat tidak ditemukan, tekan tombol Reset pada perangkat TAGANA selama 3 detik.',
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

/// ---------------------------------------------------------------------
/// Bottom action buttons
/// ---------------------------------------------------------------------
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.step,
    required this.device,
    required this.onConnect,
    required this.onCancel,
    required this.onDone,
    required this.onRetry,
  });

  final ConnectionStep step;
  final BluetoothDeviceInfo? device;
  final VoidCallback onConnect;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final canConnect = step == ConnectionStep.found && device != null;
    final isBusy = step == ConnectionStep.connecting;
    final isConnected = step == ConnectionStep.connected;
    final isFailed = step == ConnectionStep.failed;
    final isAdapterOff = step == ConnectionStep.adapterOff;

    VoidCallback? onPressed;
    String label;
    IconData icon;
    Color bgColor;

    if (isConnected) {
      onPressed = onDone;
      label = 'Selesai';
      icon = Icons.check;
      bgColor = AppColors.success;
    } else if (isFailed) {
      onPressed = onRetry;
      label = 'Coba Lagi';
      icon = Icons.refresh;
      bgColor = AppColors.navy;
    } else if (isAdapterOff) {
      onPressed = null;
      label = 'Hubungkan';
      icon = Icons.bluetooth;
      bgColor = AppColors.navy;
    } else {
      onPressed = canConnect ? onConnect : null;
      label = 'Hubungkan';
      icon = Icons.bluetooth;
      bgColor = AppColors.navy;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor,
                disabledBackgroundColor: AppColors.navy.withOpacity(0.4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(icon, size: 18),
                      ],
                    ),
            ),
          ),
          if (!isConnected) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onCancel,
              child: const Text(
                'Batalkan',
                style: TextStyle(
                  color: AppColors.destructive,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}