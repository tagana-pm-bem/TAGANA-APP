import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleTelemetryService {
  BleTelemetryService._();
  static final BleTelemetryService instance = BleTelemetryService._();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  String? _connectedDeviceCode;

  // Single Source of Truth untuk status koneksi BLE
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  // Broadcast stream agar semua halaman bisa mendengarkan data sensor
  final StreamController<Map<String, dynamic>> _telemetryController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get telemetryStream => _telemetryController.stream;

  bool get isConnected => _device != null && isConnectedNotifier.value;
  String? get connectedDeviceCode => _connectedDeviceCode;

  /// Connect to the device by scanning for its specific BLE name (e.g. TAGANA_0002)
  Future<void> connect(String deviceCode) async {
    try {
      // Jika sudah terhubung dengan device yang sama, hiraukan
      final targetName = "TAGANA_${deviceCode.substring(4)}";
      if (_device != null && _device!.platformName == targetName && isConnectedNotifier.value) {
        return;
      }

      // Clean up any existing connection first
      await disconnect();
      print('[BLE] Mencari perangkat dengan nama: $targetName');

      // Check if already connected to this app
      for (var d in FlutterBluePlus.connectedDevices) {
        if (d.platformName == targetName) {
          _device = d;
          break;
        }
      }

      // Check if already connected/paired via OS Settings
      if (_device == null) {
        try {
          final systemDevices = await FlutterBluePlus.systemDevices(
            [Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b")]
          );
          for (var d in systemDevices) {
            if (d.platformName == targetName || d.platformName.isEmpty) {
              _device = d;
              break;
            }
          }
        } catch (_) {}
      }

      // If not connected, scan for it using Service UUID
      if (_device == null) {
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }

        bool deviceFound = false;
        
        final scanSub = FlutterBluePlus.onScanResults.listen((results) {
          for (var r in results) {
            // Karena kita scan pakai withServices, SEMUA hasil pasti alat Tagana.
            // Kita terima jika namanya cocok, atau namanya disembunyikan OS (kosong).
            if (r.device.platformName == targetName || 
                r.advertisementData.advName == targetName ||
                r.device.platformName.isEmpty) {
              deviceFound = true;
              _device = r.device;
              FlutterBluePlus.stopScan();
              break;
            }
          }
        });

        // Scan berdasarkan Service UUID
        await FlutterBluePlus.startScan(
          withServices: [Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b")],
          timeout: const Duration(seconds: 5), // Percepat timeout
        );
        
        await FlutterBluePlus.isScanning.where((val) => val == false).first;
        scanSub.cancel();

        if (!deviceFound || _device == null) {
          throw Exception("Perangkat $targetName tidak ditemukan. Pastikan alat menyala dan memancarkan Bluetooth.");
        }
      }

      print('[BLE] Menghubungkan ke ${_device!.platformName}...');
      await _device!.connect(timeout: const Duration(seconds: 10), autoConnect: false);
      
      if (Platform.isAndroid) {
        try {
          await _device!.requestMtu(256);
        } catch (_) {}
      }

      // Listen for disconnection
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('[BLE] Terputus dari perangkat.');
          // Gunakan Future.microtask untuk menghindari crash akibat modifikasi state di dalam callback
          Future.microtask(() => _cleanupState(isDisconnectedEvent: true));
        } else if (state == BluetoothConnectionState.connected) {
          _connectedDeviceCode = deviceCode;
          isConnectedNotifier.value = true;
        }
      });

      // Discover services
      print('[BLE] Mencari layanan...');
      final services = await _device!.discoverServices();
      BluetoothService? targetService;
      
      for (var s in services) {
        if (s.uuid.str.toLowerCase() == '4fafc201-1fb5-459e-8fcc-c5c9c331914b') {
          targetService = s;
          break;
        }
      }

      if (targetService == null) {
        throw Exception("Layanan telemetri tidak ditemukan pada perangkat.");
      }

      for (var c in targetService.characteristics) {
        if (c.uuid.str.toLowerCase() == 'beb5483e-36e1-4688-b7f5-ea07361b26a9') {
          _txCharacteristic = c;
        } else if (c.uuid.str.toLowerCase() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
          _rxCharacteristic = c;
        }
      }

      if (_txCharacteristic == null) {
        throw Exception("Karakteristik TX tidak ditemukan.");
      }
      if (_rxCharacteristic == null) {
        print('[BLE] Peringatan: Karakteristik RX tidak ditemukan, fitur kirim perintah mungkin tidak bekerja.');
      }

      print('[BLE] Mengaktifkan Notifikasi Realtime...');
      await _txCharacteristic!.setNotifyValue(true);
      isConnectedNotifier.value = true;
      
      _notifySubscription = _txCharacteristic!.lastValueStream.listen((value) {
        if (value.isNotEmpty) {
          try {
            final jsonStr = utf8.decode(value);
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            _telemetryController.add(data);
          } catch (e) {
            print('[BLE] Error decoding JSON: $e');
          }
        }
      });

      print('[BLE] Berhasil terhubung dan mendengarkan data.');
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Send a JSON command to the ESP32 via BLE
  Future<void> sendCommand(Map<String, dynamic> payload) async {
    final jsonStr = jsonEncode(payload);
    await sendRawCommand(jsonStr);
  }

  /// Send a raw string command to the ESP32 via BLE
  Future<void> sendRawCommand(String command) async {
    if (_rxCharacteristic == null) {
      throw Exception('Karakteristik RX belum siap atau perangkat tidak mendukung penerimaan perintah.');
    }
    final bytes = utf8.encode(command);
    
    try {
      // Kita tetap menggunakan withoutResponse: false (sesuai kapabilitas default ESP32), 
      // tapi kita batasi waktunya agar tidak hang kalau ESP32 keburu restart (misal saat ganti Wi-Fi).
      await _rxCharacteristic!.write(bytes, withoutResponse: false).timeout(const Duration(seconds: 2));
      print('[BLE] Command terkirim: $command');
    } catch (e) {
      print('[BLE] Info: Write timeout atau error (mungkin ESP32 sedang restart): $e');
      // Jika errornya karena timeout, kita anggap sukses terkirim ke ESP32.
    }
  }

  Future<void> disconnect() async {
    _cleanupState(isDisconnectedEvent: false);
  }

  void _cleanupState({bool isDisconnectedEvent = false}) {
    _notifySubscription?.cancel();
    _notifySubscription = null;
    
    // Jangan panggil setNotifyValue(false) atau disconnect() jika device sudah terputus 
    // karena akan memicu crash di sisi Native (PlatformException)
    if (!isDisconnectedEvent) {
      if (_txCharacteristic != null) {
        try {
          _txCharacteristic!.setNotifyValue(false);
        } catch (_) {}
      }
      
      if (_device != null) {
        try {
          _device!.disconnect();
        } catch (_) {}
      }
    }
    
    _txCharacteristic = null;
    _rxCharacteristic = null;
    _device = null;

    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    _connectedDeviceCode = null;
    isConnectedNotifier.value = false;
  }
}
