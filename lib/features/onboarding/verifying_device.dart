import 'package:flutter/material.dart';
import 'package:tagana_app/core/theme/app_colors.dart';
import '../../core/widgets/app_version_footer.dart';

class DeviceInfo {
  const DeviceInfo({
    required this.name,
    required this.code,
    required this.type,
    required this.firmware,
    required this.region,
    this.status = 'Aktif',
  });

  final String name;
  final String code;
  final String type;
  final String firmware;
  final String region;
  final String status;
}

/// Hasil proses verifikasi perangkat: sukses (dengan [DeviceInfo]) atau gagal
/// (dengan pesan error opsional).
class DeviceVerificationResult {
  const DeviceVerificationResult.success(this.device)
    : success = true,
      errorMessage = null;

  const DeviceVerificationResult.failure([this.errorMessage])
    : success = false,
      device = null;

  final bool success;
  final DeviceInfo? device;
  final String? errorMessage;
}

enum _VerifyStatus { checking, success, error }

class DeviceVerificationPage extends StatefulWidget {
  const DeviceVerificationPage({
    super.key,
    required this.deviceCode,
    this.verifyDevice,
    this.onContinue,
    this.onRetry,
    this.onContactSupport,
  });

  /// Kode perangkat (mis. TGN_0001) yang dikirim dari halaman input kode.
  final String deviceCode;

  /// Fungsi verifikasi asli — sambungkan ke BLE discovery / backend di sini.
  /// Kalau tidak diisi, dipakai mock delay 2 detik untuk keperluan preview.
  final Future<DeviceVerificationResult> Function(String code)? verifyDevice;

  /// Dipanggil saat tombol "Lanjutkan" ditekan pada state sukses.
  final VoidCallback? onContinue;

  /// Dipanggil saat tombol "Coba Lagi" ditekan pada state error.
  /// Default: menjalankan ulang verifikasi dengan kode yang sama.
  final VoidCallback? onRetry;

  /// Dipanggil saat tautan "Hubungi Dukungan" ditekan.
  final VoidCallback? onContactSupport;

  @override
  State<DeviceVerificationPage> createState() => _DeviceVerificationPageState();
}

class _DeviceVerificationPageState extends State<DeviceVerificationPage> {
  _VerifyStatus _status = _VerifyStatus.checking;
  DeviceInfo? _device;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runVerification();
  }

  Future<void> _runVerification() async {
    setState(() => _status = _VerifyStatus.checking);
    
    // Tambahkan delay minimal agar status loading (spinner) terlihat oleh user, 
    // sehingga tombol "Coba Lagi" terasa berfungsi.
    await Future.delayed(const Duration(milliseconds: 500));
    
    final verify = widget.verifyDevice ?? _mockVerify;
    final result = await verify(widget.deviceCode);
    if (!mounted) return;
    setState(() {
      _status = result.success ? _VerifyStatus.success : _VerifyStatus.error;
      _device = result.device;
      _errorMessage = result.errorMessage;
    });
  }

  // TODO: ganti dengan verifikasi asli (BLE discovery + cek registrasi ke
  // backend Supabase/Hasura). Ini cuma mock supaya halaman bisa di-preview.
  Future<DeviceVerificationResult> _mockVerify(String code) async {
    await Future.delayed(const Duration(seconds: 2));
    return DeviceVerificationResult.success(
      DeviceInfo(
        name: 'TAGANA-001',
        code: code,
        type: 'ESP32-TAGANA v2',
        firmware: 'v2.4.1',
        region: 'Jawa Barat',
      ),
    );
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!.call();
    } else {
      _runVerification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: switch (_status) {
                  _VerifyStatus.checking => _buildCheckingBody(),
                  _VerifyStatus.success => _buildSuccessBody(),
                  _VerifyStatus.error => _buildErrorBody(),
                },
              ),
            ),
            const AppVersionFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final showBack = _status == _VerifyStatus.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showBack)
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: AppColors.foreground,
                ),
              ),
            )
          else
            const SizedBox(width: 36, height: 36),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Text(
                'Verifikasi Perangkat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Checking
  // ---------------------------------------------------------------------

  Widget _buildCheckingBody() {
    return Column(
      children: [
        const SizedBox(height: 48),
        SizedBox(
          width: 96,
          height: 96,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Memeriksa Perangkat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Mohon tunggu, sedang memeriksa kode dan koneksi ke perangkat TAGANA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Success
  // ---------------------------------------------------------------------

  Widget _buildSuccessBody() {
    final device = _device;
    return Column(
      children: [
        _buildStatusOrb(
          background: AppColors.success,
          icon: Icons.check,
          iconColor: AppColors.successForeground,
        ),
        const SizedBox(height: 16),
        _buildStatusBadge(
          background: AppColors.success,
          textColor: AppColors.successForeground,
          icon: Icons.check_circle,
          label: 'Perangkat ditemukan',
        ),
        const SizedBox(height: 16),
        Text(
          'Memeriksa Perangkat',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Perangkat TAGANA berhasil diverifikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        if (device != null) ...[
          _buildDeviceInfoCard(device),
          const SizedBox(height: 20),
          _buildChecklist(const [
            'Kode perangkat valid',
            'Perangkat terdaftar di server',
            'Firmware kompatibel',
          ]),
          const SizedBox(height: 28),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjutkan',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.bluetooth, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard(DeviceInfo device) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.memory, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: TextStyle(
                        color: AppColors.foreground,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      device.code,
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  device.status,
                  style: TextStyle(
                    color: AppColors.successForeground,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.memory_outlined, 'Tipe Perangkat', device.type),
          const SizedBox(height: 8),
          _buildInfoRow(
            Icons.system_update_outlined,
            'Firmware',
            device.firmware,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.location_on_outlined, 'Wilayah', device.region),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedForeground),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: AppColors.mutedForeground, fontSize: 12),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(color: AppColors.foreground, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------

  Widget _buildErrorBody() {
    return Column(
      children: [
        _buildStatusOrb(
          background: AppColors.destructive,
          icon: Icons.error_outline,
          iconColor: AppColors.destructiveForeground,
        ),
        const SizedBox(height: 16),
        _buildStatusBadge(
          background: AppColors.destructive,
          textColor: AppColors.destructiveForeground,
          icon: Icons.warning_amber_rounded,
          label: 'Perangkat tidak ditemukan',
        ),
        const SizedBox(height: 16),
        Text(
          'Verifikasi Gagal',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _errorMessage ??
                'Kode perangkat tidak terdaftar. Periksa kembali kode pada label perangkat TAGANA.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.destructive,
            border: Border.all(
              color: AppColors.destructiveForeground,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Icon(Icons.tag, size: 18, color: AppColors.destructiveForeground),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.deviceCode,
                  style: TextStyle(
                    color: AppColors.destructiveForeground,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.error_outline,
                size: 18,
                color: AppColors.destructiveForeground,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yang perlu diperiksa:',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _buildNumberedItem(1, 'Pastikan kode dimulai dengan "TGN_"'),
              _buildNumberedItem(
                2,
                'Periksa label pada badan perangkat TAGANA',
              ),
              _buildNumberedItem(
                3,
                'Hubungi administrator jika masalah berlanjut',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Coba Lagi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.refresh, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: widget.onContactSupport,
          child: Text(
            'Hubungi Dukungan',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberedItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared
  // ---------------------------------------------------------------------

  Widget _buildStatusOrb({
    required Color background,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, size: 44, color: iconColor),
    );
  }

  Widget _buildStatusBadge({
    required Color background,
    required Color textColor,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
