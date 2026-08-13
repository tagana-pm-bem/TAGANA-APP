import 'package:flutter/material.dart';

class AppBackHandler extends StatefulWidget {
  const AppBackHandler({
    required this.child,
    required this.canPop,
    required this.onPop,
    required this.onExit,
    super.key,
  });

  final Widget child;
  final bool Function() canPop;
  final VoidCallback onPop;
  final VoidCallback onExit;

  @override
  State<AppBackHandler> createState() => _AppBackHandlerState();
}

class _AppBackHandlerState extends State<AppBackHandler> {
  DateTime? _lastBackPress;

  void _handleBack() {
    if (widget.canPop()) {
      widget.onPop();
      return;
    }

    final now = DateTime.now();

    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tekan kembali lagi untuk keluar'),
            duration: Duration(seconds: 2),
          ),
        );

      return;
    }

    widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        _handleBack();
      },
      child: widget.child,
    );
  }
}