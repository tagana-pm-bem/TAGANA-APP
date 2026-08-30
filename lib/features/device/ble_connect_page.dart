import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/ble_telemetry_service.dart';

class BleConnectPage extends StatefulWidget {
  const BleConnectPage({
    required this.deviceId,
    this.deviceCode,
    this.returnTo,
    super.key,
  });

  final String deviceId;
  final String? deviceCode;
  final String? returnTo;

  @override
  State<BleConnectPage> createState() => _BleConnectPageState();
}

class _BleConnectPageState extends State<BleConnectPage> {
  bool _isScanning = false;
  List<ScanResult> _scanResults = [];
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  Future<void> _initBle() async {
    // 1. Pantau status adapter Bluetooth HP (Aktif/Mati)
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (mounted) setState(() => _adapterState = state);
    });

    // 2. Pantau hasil scan perangkat di sekitar
    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (mounted) {
        setState(() {
          // Filter hanya perangkat yang namanya berawalan "TAGANA"
          _scanResults = results.where((r) {
            final name = r.device.platformName.isNotEmpty 
                ? r.device.platformName 
                : r.advertisementData.advName;
            return name.toUpperCase().startsWith('TAGANA');
          }).toList();
        });
      }
    });

    // 3. Minta izin & mulai scan
    await _checkPermissionsAndScan();
  }

  Future<void> _checkPermissionsAndScan() async {
    // Meminta izin runtime Bluetooth (Android & iOS)
    final scanStatus = await Permission.bluetoothScan.request();
    final connectStatus = await Permission.bluetoothConnect.request();
    final locationStatus = await Permission.location.request();

    if (scanStatus.isGranted && connectStatus.isGranted) {
      _startScan();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin Bluetooth & Lokasi diperlukan untuk memindai perangkat.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanResults.clear();
    });

    try {
      // Pastikan Bluetooth menyala
      if (_adapterState != BluetoothAdapterState.on) {
        if (Theme.of(context).platform == TargetPlatform.android) {
          await FlutterBluePlus.turnOn();
        }
      }

      // Mulai scan selama 15 detik
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      print('Error saat scanning BLE: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _connectingDeviceId = device.remoteId.toString());

    try {
      // Hentikan proses scan sebelum mulai koneksi
      await FlutterBluePlus.stopScan();

      // Hubungkan menggunakan service BLE yang sudah ada di aplikasi
      await BleTelemetryService.instance.connectToDevice(
        device,
        deviceId: widget.deviceId,
        deviceCode: widget.deviceCode,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil terhubung ke perangkat TAGANA!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.returnTo == 'emergency') {
          context.pop();
        } else {
          context.pushReplacement('/device/${widget.deviceId}/wifi-config');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _connectingDeviceId = null);
      }
    }
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _adapterStateSubscription.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildScanningSection(textTheme),
                  const SizedBox(height: AppSpacing.lg),
                  _buildDiscoveredDevicesSection(textTheme),
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
            'Hubungkan BLE',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.foreground,
            ),
          ),
          Text(
            'Target ID: ${widget.deviceId}',
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
        ),
      ),
    );
  }

  Widget _buildScanningSection(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  _isScanning ? LucideIcons.bluetoothSearching : LucideIcons.bluetooth,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _isScanning 
                ? 'Mencari perangkat TAGANA di sekitar Anda...' 
                : (_scanResults.isEmpty 
                    ? 'Tidak ada perangkat TAGANA ditemukan. Pastikan alat menyala dalam mode darurat.' 
                    : 'Ditemukan ${_scanResults.length} perangkat TAGANA.'),
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          if (_isScanning) ...[
            const SizedBox(height: AppSpacing.md),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscoveredDevicesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(LucideIcons.radio, color: AppColors.primary, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Perangkat TAGANA Tersedia (${_scanResults.length})',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (_scanResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            alignment: Alignment.center,
            child: Text(
              'Tekan tombol "Scan Lagi" di bawah jika perangkat belum muncul.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _scanResults.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final result = _scanResults[index];
              final deviceName = result.device.platformName.isNotEmpty 
                  ? result.device.platformName 
                  : (result.advertisementData.advName.isNotEmpty 
                      ? result.advertisementData.advName 
                      : 'TAGANA Device');
              final isConnecting = _connectingDeviceId == result.device.remoteId.toString();

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                deviceName,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.foreground,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'BLE Ready',
                                  style: textTheme.labelSmall?.copyWith(color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MAC / ID: ${result.device.remoteId}',
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.mutedForeground,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.signal, size: 13, color: AppColors.mutedForeground),
                              const SizedBox(width: 4),
                              Text(
                                'RSSI: ${result.rssi} dBm',
                                style: textTheme.labelSmall?.copyWith(color: AppColors.mutedForeground),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: isConnecting ? null : () => _connectToDevice(result.device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.primaryForeground,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: isConnecting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Hubungkan'),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomAction(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isScanning ? null : _startScan,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.muted,
              foregroundColor: AppColors.foreground,
              side: BorderSide.none,
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
            label: Text(_isScanning ? 'Memindai Perangkat...' : 'Scan Lagi'),
          ),
        ),
      ),
    );
  }
}