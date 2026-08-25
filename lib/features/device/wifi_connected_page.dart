import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _HtmlColors {
  static const surface = Color(0xFFF9F9F9);
  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF464554);
  static const primary = Color(0xFF4648D4);
  static const primaryFixed = Color(0xFFE1E0FF);
  static const tertiaryFixed = Color(0xFFDAE2FF);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceVariant = Color(0xFFE2E2E2);
  static const outline = Color(0xFF767586);
}

class WifiConnectedPage extends StatefulWidget {
  const WifiConnectedPage({required this.deviceId, required this.ssid, super.key});

  final String deviceId;
  final String ssid;

  @override
  State<WifiConnectedPage> createState() => _WifiConnectedPageState();
}

class _WifiConnectedPageState extends State<WifiConnectedPage> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HtmlColors.surface,
      body: Stack(
        children: [

          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _HtmlColors.primaryFixed.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _HtmlColors.tertiaryFixed.withOpacity(0.3),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final scale = 1.0 + (_pulseController.value * 0.05);
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 96,
                                  height: 96,
                                  decoration: const BoxDecoration(
                                    color: _HtmlColors.primaryFixed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.fromRGBO(30, 42, 74, 0.12),
                                        blurRadius: 32,
                                        offset: Offset(0, 10),
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: _HtmlColors.primary,
                                    size: 48,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'Wi-Fi Berhasil Terhubung',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _HtmlColors.onSurface,
                              letterSpacing: -0.01,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Perangkat Anda sekarang terhubung dan siap digunakan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: _HtmlColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 40),


                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: _HtmlColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(30, 42, 74, 0.05),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              children: [

                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: _HtmlColors.surfaceContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.router, color: _HtmlColors.onSurfaceVariant),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.deviceId,
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _HtmlColors.onSurface,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const Text(
                                          'Modul Sensor',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _HtmlColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1, color: _HtmlColors.surfaceVariant),
                                const SizedBox(height: 16),
                                

                                _buildDetailItem(
                                  icon: Icons.wifi,
                                  label: 'Jaringan',
                                  valueWidget: Text(
                                    widget.ssid.isNotEmpty ? widget.ssid : 'TAGANA Office',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _HtmlColors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailItem(
                                  icon: Icons.signal_cellular_alt,
                                  label: 'Signal',
                                  valueWidget: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _HtmlColors.primaryFixed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(color: _HtmlColors.primary, shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Baik',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: _HtmlColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDetailItem(
                                  icon: Icons.sync,
                                  label: 'Sinkronisasi',
                                  valueWidget: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.cloud_done, size: 16, color: _HtmlColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Aktif',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _HtmlColors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _HtmlColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required Widget valueWidget}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: _HtmlColors.outline),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: _HtmlColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Flexible(
          child: DefaultTextStyle(
            style: const TextStyle(
              overflow: TextOverflow.ellipsis,
            ),
            child: valueWidget,
          ),
        ),
      ],
    );
  }
}
