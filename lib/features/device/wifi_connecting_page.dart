import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import '../../core/services/ble_telemetry_service.dart';

class _HtmlColors {
  static const background = Color(0xFFF9F9F9);
  static const onBackground = Color(0xFF1A1C1C);
  static const primary = Color(0xFF4648D4);
  static const primaryFixedDim = Color(0xFFC0C1FF);
  static const tertiaryFixedDim = Color(0xFFBAC5EE); // #bac5ee
  static const onSurfaceVariant = Color(0xFF464554);
  static const surface = Color(0xFFF9F9F9);
  static const surfaceVariant = Color(0xFFE2E2E2);
  static const onSurface = Color(0xFF1A1C1C);
  static const outlineVariant = Color(0xFFC7C4D7);
}

class WifiConnectingPage extends StatefulWidget {
  const WifiConnectingPage({required this.deviceId, required this.ssid, required this.password, super.key});
  
  final String deviceId;
  final String ssid;
  final String password;

  @override
  State<WifiConnectingPage> createState() => _WifiConnectingPageState();
}

class _WifiConnectingPageState extends State<WifiConnectingPage> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWifiConfig();
    });
  }

  Future<void> _sendWifiConfig() async {
    try {
      final deviceCode = BleTelemetryService.instance.connectedDeviceCode;
      if (!BleTelemetryService.instance.isConnected || deviceCode == null) {
        throw Exception("Bluetooth belum terhubung! Harap hubungkan BLE terlebih dahulu.");
      }

      // 1. Kirim format WIFI:ssid:password
      final payload = "WIFI:${widget.ssid}:${widget.password}";
      await BleTelemetryService.instance.sendRawCommand(payload);
      
      // 2. Beri waktu ESP32 untuk restart dan memproses koneksi Wi-Fi
      // ESP32 sangat cepat terkoneksi, jadi kita set delay simulasi UI yang pas (misal 5 detik)
      // agar animasi berputar terlihat natural sebelum pindah halaman.
      await Future.delayed(const Duration(seconds: 5));

      if (mounted) {
        context.pushReplacement('/device/${widget.deviceId}/wifi-connected?ssid=${Uri.encodeComponent(widget.ssid)}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengirim konfigurasi: $e'),
          backgroundColor: Colors.red,
        ));
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HtmlColors.background,
      body: Stack(
        children: [
          // Background abstract elements
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _HtmlColors.primaryFixedDim.withOpacity(0.2),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFBAC5EE).withOpacity(0.2),
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.deviceId,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _HtmlColors.onBackground,
                        letterSpacing: -0.01,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Menghubungkan perangkat',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            color: _HtmlColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildAnimatedDots(),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    // Connection visualizer
                    _buildVisualizer(),
                    
                    const SizedBox(height: 40),
                    
                    // Progress Steps
                    _buildProgressSteps(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return Row(
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final val = math.sin((_pulseController.value * math.pi * 2) - delay);
            final opacity = (val + 1) / 2 * 0.5 + 0.5; // 0.5 to 1.0
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _HtmlColors.primary.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildVisualizer() {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple 1
          FadeTransition(
            opacity: Tween<double>(begin: 0.8, end: 0.0).animate(_pulseController),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.5).animate(_pulseController),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _HtmlColors.primaryFixedDim.withOpacity(0.4), width: 1),
                ),
              ),
            ),
          ),
          // Hub
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _HtmlColors.surface,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(30, 42, 74, 0.12),
                  blurRadius: 32,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinController.value * 2 * math.pi,
                    child: const Icon(
                      Icons.sync,
                      color: _HtmlColors.primary,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: _HtmlColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 42, 74, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 11,
            top: 16,
            bottom: 16,
            child: Container(
              width: 2,
              color: _HtmlColors.surfaceVariant,
            ),
          ),
          Column(
            children: [
              _buildStepItem(
                text: 'Mengirim konfigurasi Wi-Fi',
                isActive: false,
                isCompleted: true,
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                text: 'Menghubungkan ke jaringan',
                isActive: true,
                isCompleted: false,
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                text: 'Memverifikasi koneksi',
                isActive: false,
                isCompleted: false,
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                text: 'Mengaktifkan sinkronisasi',
                isActive: false,
                isCompleted: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required String text, required bool isActive, required bool isCompleted}) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isCompleted ? _HtmlColors.primary : _HtmlColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted
                  ? _HtmlColors.primary
                  : (isActive ? _HtmlColors.primary : _HtmlColors.outlineVariant),
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : (isActive
                    ? AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _pulseController.value,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: _HtmlColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      )
                    : null),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
            color: isActive
                ? _HtmlColors.primary
                : (isCompleted ? _HtmlColors.onSurface : _HtmlColors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
