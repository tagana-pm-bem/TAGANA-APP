import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/services/ble_telemetry_service.dart';
import '../../core/services/device_service.dart';
import '../../features/device/models/device_detail_data.dart';

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
  bool _isLoadingDevice = true;
  DeviceDetailData? _deviceData;
  
  List<Map<String, String>> _wifiHistory = [];

  @override
  void initState() {
    super.initState();
    _loadWifiHistory();
    _fetchDeviceStatusFromCloud();
  }

  Future<void> _fetchDeviceStatusFromCloud() async {
    try {
      final data = await DeviceService.fetchDeviceDetail(widget.deviceId);
      if (mounted) {
        setState(() {
          _deviceData = data;
          _isLoadingDevice = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDevice = false;
        });
      }
    }
  }

  Future<void> _loadWifiHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = prefs.getStringList('wifi_history') ?? [];
      setState(() {
        _wifiHistory = historyList.map((item) {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          return {
            'ssid': decoded['ssid']?.toString() ?? '',
            'password': decoded['password']?.toString() ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Gagal memuat riwayat wifi: $e');
    }
  }

  Future<void> _saveWifiToHistory(String ssid, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _wifiHistory.removeWhere((item) => item['ssid'] == ssid);
      _wifiHistory.insert(0, {'ssid': ssid, 'password': password});
      if (_wifiHistory.length > 5) {
        _wifiHistory = _wifiHistory.sublist(0, 5);
      }
      final historyList = _wifiHistory.map((item) => jsonEncode(item)).toList();
      await prefs.setStringList('wifi_history', historyList);
    } catch (e) {
      print('Gagal menyimpan riwayat wifi: $e');
    }
  }

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

    if (!BleTelemetryService.instance.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth belum terhubung. Harap hubungkan Bluetooth terlebih dahulu untuk mengirim konfigurasi ke perangkat.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      // 1. KIRIM STRING KONFIGURASI KE ESP32 VIA BLE
      final wifiCommand = 'WIFI:${_ssidController.text}:${_passwordController.text}';
      await BleTelemetryService.instance.sendRawCommand(wifiCommand);

      // 2. CATAT LOG KE SUPABASE
      await DeviceService.logActivity(
        deviceId: widget.deviceId,
        type: 'wifi_configured',
        title: 'Konfigurasi Wi-Fi Dikirim',
        description: 'Jaringan baru (${_ssidController.text}) telah dikirim ke perangkat via Bluetooth.',
      );

      // 3. Simpan ke riwayat lokal SharedPreferences
      await _saveWifiToHistory(_ssidController.text, _passwordController.text);

      if (mounted) {
        setState(() => _isConnecting = false);
        // Lanjut ke halaman loading/connecting berikutnya
        context.push(
          '/device/${widget.deviceId}/wifi-connecting?ssid=${Uri.encodeComponent(_ssidController.text)}&password=${Uri.encodeComponent(_passwordController.text)}'
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim konfigurasi Wi-Fi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 Future<void> _handleDisconnectInternet() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Putuskan Koneksi Internet?'),
        content: const Text(
          'Perangkat akan memutuskan sambungan ke Wi-Fi saat ini, lalu mengaktifkan mode Hotspot lokal (Tagana-AP) dan Bluetooth secara mandiri untuk akses darurat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Putuskan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final bleService = BleTelemetryService.instance;
      
      if (!bleService.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bluetooth belum terhubung. Harap hubungkan BLE terlebih dahulu.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 1. Kirim string perintah DISCONNECT_WIFI via BLE ke ESP32
      await bleService.sendRawCommand('DISCONNECT_WIFI');

      // 2. CATAT LOG KE SUPABASE
      await DeviceService.logActivity(
        deviceId: widget.deviceId,
        type: 'network_reset',
        title: 'Internet Diputus (Mode Darurat)',
        description: 'Koneksi Wi-Fi diputus. Perangkat beralih ke Mode Hotspot.',
      );

      if (mounted) {
        setState(() {
          _deviceData = null; // Reset data sementara agar kartu membaca ulang state offline
          _isLoadingDevice = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Internet diputus. Perangkat beralih ke Mode Darurat (Offline).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim perintah: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                _buildSectionLabel('STATUS KONEKSI INTERNET (CLOUD)'),
                const SizedBox(height: 8.0),
                _buildInternetStatusCard(),
                const SizedBox(height: 24.0),
                _buildSectionLabel('KONTROL TAKTIS & JARINGAN'),
                const SizedBox(height: 12.0),
                _buildConfigurationForm(),
                const SizedBox(height: 120.0),
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
            'Kelola koneksi internet perangkat TAGANA',
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
          Expanded(
            child: Column(
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
                Text(
                  widget.deviceId,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _HtmlColors.onSurface,
                  ),
                ),
              ],
            ),
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

  Widget _buildInternetStatusCard() {
    if (_isLoadingDevice) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: _HtmlColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final isOnline = _deviceData?.device.isConnected ?? false;

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
                  color: isOnline ? Colors.green.shade50 : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  isOnline ? Icons.wifi : Icons.wifi_off,
                  color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? 'Terhubung ke Internet (Online)' : 'Perangkat Offline',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isOnline ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    isOnline 
                        ? 'Data telemetri berjalan normal via Cloud' 
                        : 'Belum ada sinyal internet dari perangkat',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: _HtmlColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Icon(
            isOnline ? Icons.check_circle : Icons.info_outline,
            color: isOnline ? Colors.green.shade500 : Colors.orange.shade400,
          ),
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
            'Masukkan detail jaringan Wi-Fi baru untuk perangkat Anda.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: _HtmlColors.onSurfaceVariant,
            ),
          ),
          if (_wifiHistory.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            const Text(
              'Riwayat Wi-Fi (Tap untuk mengisi otomatis):',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _HtmlColors.primary,
              ),
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _wifiHistory.map((wifi) {
                return ActionChip(
                  label: Text(
                    wifi['ssid'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  avatar: const Icon(Icons.history, size: 16, color: _HtmlColors.primary),
                  backgroundColor: _HtmlColors.primaryContainer.withOpacity(0.1),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    setState(() {
                      _ssidController.text = wifi['ssid'] ?? '';
                      _passwordController.text = wifi['password'] ?? '';
                    });
                  },
                );
              }).toList(),
            ),
          ],
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
                    'Kirim Konfigurasi ke Perangkat',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 12.0),
          // Tombol Putuskan Internet / Masuk Mode Darurat
          OutlinedButton.icon(
            onPressed: _handleDisconnectInternet,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade300),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
            icon: const Icon(Icons.wifi_off, size: 18),
            label: const Text(
              'Putuskan Internet (Mode Darurat)',
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
                'Wi-Fi adalah jalur komunikasi utama. Saat mengirim konfigurasi jaringan baru atau memutuskan koneksi, pastikan perangkat berada dalam jangkauan Bluetooth.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
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