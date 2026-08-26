import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_service.dart'; // Import service untuk mencatat log aktivitas

class BleTelemetryService {
  BleTelemetryService._();
  static final BleTelemetryService instance = BleTelemetryService._();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  
  String? _connectedDeviceCode;
  String? _connectedDeviceId; // Menyimpan UUID device untuk log ketika terputus

  // Single Source of Truth untuk status koneksi BLE
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier<bool>(false);

  // Broadcast stream agar semua halaman bisa mendengarkan data sensor
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get telemetryStream =>
      _telemetryController.stream;

  bool get isConnected => _device != null && isConnectedNotifier.value;
  String? get connectedDeviceCode => _connectedDeviceCode;
  
  BluetoothDevice? connectedDevice;

  Future<void> connectToDevice(BluetoothDevice device, {String? deviceId}) async {
    try {
      _device = device;
      // Lakukan koneksi BLE dengan timeout
      await _device!.connect(timeout: const Duration(seconds: 15));
      connectedDevice = device;
      _connectedDeviceId = deviceId; // Simpan UUID

      // Update status koneksi
      isConnectedNotifier.value = true;

      // Pencatatan aktivitas ke Supabase
      if (_connectedDeviceId != null) {
        DeviceService.logActivity(
          deviceId: _connectedDeviceId!,
          type: 'ble_connected',
          title: 'Koneksi BLE Aktif',
          description: 'Aplikasi berhasil terhubung ke perangkat secara langsung via Bluetooth.',
        );
      }

      if (Platform.isAndroid) {
        try {
          await _device!.requestMtu(256);
        } catch (_) {}
      }

      // Listen for disconnection
      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('[BLE] Terputus dari perangkat.');
          Future.microtask(() => _cleanupState(isDisconnectedEvent: true));
        } else if (state == BluetoothConnectionState.connected) {
          isConnectedNotifier.value = true;
        }
      });

      // Temukan services & characteristics
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
        print('[BLE] Peringatan: Karakteristik RX tidak ditemukan.');
      }

      print('[BLE] Mengaktifkan Notifikasi Realtime...');
      await _txCharacteristic!.setNotifyValue(true);

      _notifySubscription = _txCharacteristic!.onValueReceived.listen((value) {
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

      print('[BLE] Berhasil terhubung dan mendengarkan data via connectToDevice.');
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Connect to the device by scanning for its specific BLE name
  Future<void> connect(String deviceCode, {String? deviceId}) async {
    try {
      final targetName = "TAGANA_${deviceCode.substring(4)}";
      if (_device != null &&
          _device!.platformName == targetName &&
          isConnectedNotifier.value) {
        return;
      }

      await disconnect();
      print('[BLE] Mencari perangkat dengan nama: $targetName');

      for (var d in FlutterBluePlus.connectedDevices) {
        if (d.platformName == targetName) {
          _device = d;
          break;
        }
      }

      if (_device == null) {
        try {
          final systemDevices = await FlutterBluePlus.systemDevices([
            Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b"),
          ]);
          for (var d in systemDevices) {
            if (d.platformName == targetName || d.platformName.isEmpty) {
              _device = d;
              break;
            }
          }
        } catch (_) {}
      }

      if (_device == null) {
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }

        bool deviceFound = false;

        final scanSub = FlutterBluePlus.onScanResults.listen((results) {
          for (var r in results) {
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

        await FlutterBluePlus.startScan(
          withServices: [Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b")],
          timeout: const Duration(seconds: 5),
        );

        await FlutterBluePlus.isScanning.where((val) => val == false).first;
        scanSub.cancel();

        if (!deviceFound || _device == null) {
          throw Exception(
            "Perangkat $targetName tidak ditemukan. Pastikan alat menyala dan memancarkan Bluetooth.",
          );
        }
      }

      print('[BLE] Menghubungkan ke ${_device!.platformName}...');
      await _device!.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );

      if (Platform.isAndroid) {
        try {
          await _device!.requestMtu(256);
        } catch (_) {}
      }

      _connectionSubscription = _device!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          print('[BLE] Terputus dari perangkat.');
          Future.microtask(() => _cleanupState(isDisconnectedEvent: true));
        } else if (state == BluetoothConnectionState.connected) {
          _connectedDeviceCode = deviceCode;
          isConnectedNotifier.value = true;
        }
      });

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
        if (c.uuid.str.toLowerCase() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
          _txCharacteristic = c;
        } else if (c.uuid.str.toLowerCase() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
          _rxCharacteristic = c;
        }
      }

      if (_txCharacteristic == null) {
        throw Exception("Karakteristik TX tidak ditemukan.");
      }
      if (_rxCharacteristic == null) {
        print('[BLE] Peringatan: Karakteristik RX tidak ditemukan.');
      }

      print('[BLE] Mengaktifkan Notifikasi Realtime...');
      await _txCharacteristic!.setNotifyValue(true);
      isConnectedNotifier.value = true;
      
      _connectedDeviceCode = deviceCode;
      _connectedDeviceId = deviceId; // Simpan UUID

      // Pencatatan aktivitas ke Supabase
      if (_connectedDeviceId != null) {
        DeviceService.logActivity(
          deviceId: _connectedDeviceId!,
          type: 'ble_connected',
          title: 'Koneksi BLE Aktif',
          description: 'Berhasil terhubung ke perangkat $deviceCode via Bluetooth.',
        );
      }

      _notifySubscription = _txCharacteristic!.onValueReceived.listen((value) {
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

  Future<void> sendCommand(Map<String, dynamic> payload) async {
    final jsonStr = jsonEncode(payload);
    await sendRawCommand(jsonStr);
  }

  Future<void> sendRawCommand(String command) async {
    if (_rxCharacteristic == null) {
      throw Exception('Karakteristik RX belum siap atau perangkat tidak mendukung penerimaan perintah.');
    }
    final bytes = utf8.encode(command);

    try {
      await _rxCharacteristic!
          .write(bytes, withoutResponse: false)
          .timeout(const Duration(seconds: 2));
      print('[BLE] Command terkirim: $command');
    } catch (e) {
      print('[BLE] Info: Write timeout atau error (mungkin ESP32 sedang restart): $e');
    }
  }

  Future<void> disconnect() async {
    _cleanupState(isDisconnectedEvent: false);
  }

  void _cleanupState({bool isDisconnectedEvent = false}) {
    _notifySubscription?.cancel();
    _notifySubscription = null;

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
    
    // Log terputusnya BLE
    if (isDisconnectedEvent && _connectedDeviceId != null) {
      DeviceService.logActivity(
        deviceId: _connectedDeviceId!,
        type: 'ble_disconnected',
        title: 'Koneksi BLE Terputus',
        description: 'Koneksi Bluetooth ke perangkat telah terputus.',
      );
    }

    _txCharacteristic = null;
    _rxCharacteristic = null;
    _device = null;

    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    _connectedDeviceCode = null;
    _connectedDeviceId = null;
    isConnectedNotifier.value = false;
  }
}