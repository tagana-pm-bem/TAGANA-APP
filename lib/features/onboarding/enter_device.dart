import 'package:flutter/material.dart';
import 'package:tagana_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_version_footer.dart';

enum _DeviceCodeStatus { empty, valid, invalid }

class EnterDevicePage extends StatefulWidget {
  const EnterDevicePage({super.key});

  @override
  State<EnterDevicePage> createState() => _VerifyingDevicePageState();
}

class _VerifyingDevicePageState extends State<EnterDevicePage> {
  final _codeController = TextEditingController();

  _DeviceCodeStatus get _status {
    final code = _codeController.text.trim();
    if (code.isEmpty) return _DeviceCodeStatus.empty;
    return RegExp(r'^\d{4}$').hasMatch(code)
        ? _DeviceCodeStatus.valid
        : _DeviceCodeStatus.invalid;
  }

  bool get _canSubmit => _status == _DeviceCodeStatus.valid;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _onConnect() {
    if (!_canSubmit) return;
    final deviceCode = 'TGN_${_codeController.text.trim()}';
    // Navigasi ke halaman verifikasi perangkat dengan kode yang dimasukkan.
    // Proses pairing ke Supabase dilakukan di verifying_device.dart.
    context.go('/verifying-device/$deviceCode');
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(),
                    const SizedBox(height: 32),
                    _buildCodeField(),
                    const SizedBox(height: 24),
                    _buildInfoBox(),
                    const SizedBox(height: 32),
                    _buildConnectButton(),
                  ],
                ),
              ),
            ),
            const AppVersionFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: AppColors.foreground,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 36),
              child: Text(
                'Hubungkan Perangkat',
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

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.memory, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Masukkan Kode Perangkat',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Masukkan kode perangkat TAGANA untuk mulai menghubungkan perangkat.',
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

  Widget _buildCodeField() {
    final status = _status;
    late final Color borderColor;
    late final double borderWidth;
    late final Color fillColor;
    switch (status) {
      case _DeviceCodeStatus.valid:
        borderColor = AppColors.primary;
        borderWidth = 2;
        fillColor = AppColors.input;
        break;
      case _DeviceCodeStatus.invalid:
        borderColor = AppColors.destructive;
        borderWidth = 2;
        fillColor = AppColors.input;
        break;
      case _DeviceCodeStatus.empty:
        borderColor = AppColors.border;
        borderWidth = 1;
        fillColor = AppColors.input;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kode Perangkat',
          style: TextStyle(
            color: AppColors.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor, width: borderWidth),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.tag, size: 18, color: AppColors.mutedForeground),
              const SizedBox(width: 12),
              Text(
                'TGN_',
                style: TextStyle(
                  color: AppColors.foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: AppColors.foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '0001',
                    hintStyle: TextStyle(color: AppColors.mutedForeground),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (status == _DeviceCodeStatus.valid)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (status == _DeviceCodeStatus.valid)
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                'Format kode valid',
                style: TextStyle(color: AppColors.success, fontSize: 11),
              ),
            ],
          )
        else if (status == _DeviceCodeStatus.invalid)
          Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: AppColors.destructive),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kode perangkat tidak valid.',
                  style: TextStyle(
                    color: AppColors.destructive,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Format Kode Perangkat',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cukup ketikkan 4 digit angka dari kode perangkat Anda (Contoh: 0001, 0025, 0142).',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
                Text(
                  'Kode perangkat dapat ditemukan pada label perangkat TAGANA.',
                  style: TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSubmit ? _onConnect : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryForeground,
          disabledBackgroundColor: AppColors.muted,
          disabledForegroundColor: AppColors.mutedForeground,
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
              'Hubungkan Perangkat',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
          ],
        ),
      ),
    );
  }
}
