import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'connectivity_service.dart';

class ErrorHandlerService {
  ErrorHandlerService._();

  static final ErrorHandlerService _instance = ErrorHandlerService._();
  static ErrorHandlerService get instance => _instance;

  BuildContext? _lastContext;

  void setContext(BuildContext context) {
    _lastContext = context;
  }

  /// Handle generic error dan show alert
  Future<void> handleError(
    dynamic error, {
    String? title,
    String? customMessage,
    bool showDialog = false,
  }) async {
    final errorMsg = _parseErrorMessage(error);
    final displayTitle = title ?? 'Error';
    final displayMessage = customMessage ?? errorMsg;

    print('[ErrorHandler] $displayTitle: $displayMessage');

    if (_lastContext == null) {
      print('[ErrorHandler] No context available for showing alert');
      return;
    }

    if (showDialog) {
      await _showErrorDialog(displayTitle, displayMessage);
    } else {
      _showErrorSnackBar(displayMessage);
    }
  }

  /// Handle Supabase/database specific errors
  Future<void> handleDatabaseError(
    dynamic error, {
    String? operation = 'Database operation',
  }) async {
    final isOffline = !ConnectivityService.instance.isOnline;

    late String message;
    if (isOffline) {
      message =
          'Offline: Tidak dapat mengakses database. Pastikan HP terhubung ke internet.';
    } else if (error is PostgrestException) {
      message = 'Database error: ${error.message}';
    } else if (error is AuthException) {
      message = 'Authentication failed: ${error.message}';
    } else if (error is String && error.contains('Network')) {
      message = 'Network error: Periksa koneksi internet Anda.';
    } else {
      message = 'Database error: ${error.toString()}';
    }

    await handleError(
      error,
      title: '$operation Failed',
      customMessage: message,
      showDialog: false,
    );
  }

  /// Handle BLE specific errors
  Future<void> handleBleError(dynamic error) async {
    late String message;
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('disconnect')) {
      message = 'Bluetooth terputus. Coba hubungkan kembali perangkat.';
    } else if (errorStr.contains('timeout')) {
      message = 'Bluetooth timeout. Perangkat tidak merespons dalam waktu.';
    } else if (errorStr.contains('not found')) {
      message =
          'Perangkat Bluetooth tidak ditemukan. Pastikan perangkat menyala.';
    } else if (errorStr.contains('permission denied')) {
      message = 'Bluetooth permission denied. Cek izin aplikasi di Settings.';
    } else {
      message = 'Bluetooth error: Coba hubungkan kembali.';
    }

    await handleError(error, title: 'Bluetooth Error', customMessage: message);
  }

  /// Handle FCM specific errors
  Future<void> handleFcmError(dynamic error) async {
    late String message;
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('not available')) {
      message = 'FCM tidak tersedia. Notifikasi mungkin tidak akan diterima.';
    } else if (errorStr.contains('permission')) {
      message =
          'FCM permission denied. Izinkan notifikasi di Settings aplikasi.';
    } else {
      message = 'FCM error: Notifikasi mungkin tidak dapat dikirim.';
    }

    await handleError(
      error,
      title: 'Notification Error',
      customMessage: message,
    );
  }

  void _showErrorSnackBar(String message) {
    if (_lastContext == null) return;
    ScaffoldMessenger.of(_lastContext!).hideCurrentSnackBar();
    ScaffoldMessenger.of(_lastContext!).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.red.shade700,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(_lastContext!).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (_lastContext == null) return;
    return showDialog(
      context: _lastContext!,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, maxLines: 5, overflow: TextOverflow.ellipsis),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _parseErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return error.toString();
  }
}

// Extension untuk easier error handling di services
extension ErrorHandling on Exception {
  Future<void> handleAsError({String? title, String? message}) async {
    await ErrorHandlerService.instance.handleError(
      this,
      title: title,
      customMessage: message,
    );
  }
}
