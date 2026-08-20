import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Definisi warna berdasarkan Tailwind config dari HTML
class _HtmlColors {
  static const surface = Color(0xFFF9F9F9);
  static const onSurface = Color(0xFF1A1C1C);
  static const onSurfaceVariant = Color(0xFF464554);
  static const primary = Color(0xFF4648D4);
  static const primaryContainer = Color(0xFF6063EE);
  static const surfaceContainerLow = Color(0xFFF3F3F3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFE2E2E2);
  static const outlineVariant = Color(0xFFC7C4D7);
  static const secondary = Color(0xFF5D5F5F);
  static const surfaceContainer = Color(0xFFEEEEEE);
  static const surfaceContainerHigh = Color(0xFFE8E8E8);
}

class WifiConfigPage extends StatefulWidget {
  const WifiConfigPage({required this.deviceId, super.key});

  final String deviceId;

  @override
  State<WifiConfigPage> createState() => _WifiConfigPageState();
}

class _WifiConfigPageState extends State<WifiConfigPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isConnecting = false;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleConnect() async {
    if (_ssidController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSID dan Password harus diisi')),
      );
      return;
    }

    // Navigasi langsung ke halaman proses menghubungkan
    if (mounted) {
      setState(() => _isConnecting = false);
      context.push('/device/${widget.deviceId}/wifi-connecting?ssid=${Uri.encodeComponent(_ssidController.text)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HtmlColors.surface,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceContext(),
                const SizedBox(height: 24.0),
                _buildSectionLabel('STATUS WI-FI SAAT INI'),
                const SizedBox(height: 8.0),
                _buildWifiStatusCard(),
                const SizedBox(height: 24.0),
                _buildSectionLabel('KONFIGURASI JARINGAN'),
                const SizedBox(height: 12.0),
                _buildConfigurationForm(),
                const SizedBox(height: 120.0), // Padding untuk banner bawah
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildEmergencyBanner(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _HtmlColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _HtmlColors.onSurfaceVariant),
        onPressed: () => context.pop(),
      ),
      title: const Column(
        children: [
          Text(
            'Konfigurasi Wi-Fi',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _HtmlColors.onSurface,
            ),
          ),
          Text(
            'Hubungkan perangkat TAGANA ke internet',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _HtmlColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildDeviceContext() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _HtmlColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8.0),
        border: const Border(left: BorderSide(color: _HtmlColors.primary, width: 4.0)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 42, 74, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: _HtmlColors.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(Icons.router, color: _HtmlColors.primary),
          ),
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DEVICE ID',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _HtmlColors.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Text(
                    widget.deviceId,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _HtmlColors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  const Text(
                    '(TGN_0001)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _HtmlColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: _HtmlColors.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildWifiStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _HtmlColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 42, 74, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _HtmlColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(Icons.wifi_off, color: _HtmlColors.onSurfaceVariant),
              ),
              const SizedBox(width: 16.0),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Belum Terhubung',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _HtmlColors.onSurface,
                    ),
                  ),
                  Text(
                    'Perangkat sedang offline',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: _HtmlColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.info_outline, color: _HtmlColors.outlineVariant),
        ],
      ),
    );
  }

  Widget _buildConfigurationForm() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _HtmlColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 42, 74, 0.05),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masukkan detail jaringan Wi-Fi dari provider Anda.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: _HtmlColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20.0),
          TextField(
            controller: _ssidController,
            decoration: InputDecoration(
              labelText: 'Nama Jaringan (SSID)',
              labelStyle: const TextStyle(color: _HtmlColors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _HtmlColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _HtmlColors.primary, width: 2.0),
              ),
              prefixIcon: const Icon(Icons.wifi, color: _HtmlColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: const TextStyle(color: _HtmlColors.onSurfaceVariant),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _HtmlColors.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(color: _HtmlColors.primary, width: 2.0),
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: _HtmlColors.onSurfaceVariant),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: _HtmlColors.onSurfaceVariant,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          ElevatedButton(
            onPressed: _isConnecting ? null : _handleConnect,
            style: ElevatedButton.styleFrom(
              backgroundColor: _HtmlColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              elevation: 0,
            ),
            child: _isConnecting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Hubungkan Perangkat',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: _HtmlColors.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(30, 42, 74, 0.05),
            blurRadius: 32,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4.0),
              child: Icon(Icons.info_outline, size: 20, color: _HtmlColors.secondary),
            ),
            const SizedBox(width: 8.0),
            const Expanded(
              child: Text(
                'Wi-Fi adalah koneksi utama. Jika tidak tersedia saat darurat, perangkat akan otomatis menggunakan BLE atau Hotspot.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _HtmlColors.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
