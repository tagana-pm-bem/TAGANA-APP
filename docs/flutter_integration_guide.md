# Panduan Integrasi Flutter & Logika Jaringan TAGANA

Dokumen ini merangkum pembaruan logika konektivitas pada ESP32 (Tas Siaga TAGANA) dan panduan cara mengonsumsi data tersebut dari sisi Aplikasi *Mobile* (Flutter).

---

## 1. Keamanan & Logika Pemancar Bluetooth (BLE)
Untuk mencegah orang luar menyalakan alarm sembarangan dan untuk menghemat baterai, pemancar Bluetooth (BLE) kini memiliki logika cerdas yang terikat dengan status *Hotspot (Access Point)*:
- **Saat Terhubung Internet:** Bluetooth **MATI TOTAL** (Tidak bisa di-*scan*, aman dari peretas sekitar).
- **Saat Internet Putus (Lebih dari 10 detik):** ESP32 memancarkan *Hotspot* (`Tagana-AP`) dan **MENYALAKAN Bluetooth** secara otomatis. Mode darurat lokal aktif, tim *rescue* bisa mencari tas pakai radar/buzzer BLE.

## 2. Mekanisme "Pancing" Auto-Reconnect WiFi
Jika WiFi rumah mati lalu nyala lagi, atau *Hotspot* HP Anda dimatikan lalu dihidupkan, ESP32 tidak akan "bengong". 
Ketika ESP32 sedang dalam mode darurat (memancarkan `Tagana-AP`), ia akan secara **otomatis memaksa *reconnect*** ke memori WiFi terakhirnya **setiap 20 detik**. Begitu WiFi terdeteksi dan terhubung, *Hotspot* dan Bluetooth akan langsung mati kembali.

---

## 3. Integrasi Payload BLE ke Aplikasi Flutter

Ketika Aplikasi Flutter berhasil terhubung ke Bluetooth (misal bernama `TAGANA_0001`), ESP32 akan mengirimkan data *Telemetry* berformat JSON setiap `100ms` melalui **Characteristic TX**.

### A. Identifier Bluetooth
- **Service UUID:** `4fafc201-1fb5-459e-8fcc-c5c9c331914b`
- **TX Characteristic (ESP Kirim -> Flutter Terima):** `beb5483e-36e1-4688-b7f5-ea07361b26a9` (Gunakan untuk me-*listen/notify* data masuk).
- **RX Characteristic (Flutter Kirim -> ESP Terima):** `beb5483e-36e1-4688-b7f5-ea07361b26a8` (Gunakan untuk kirim perintah string `"BUZZER"` atau `"WIFI:SSID:PASS"`).

### B. Format Payload JSON Masuk (TX)
Karena ESP32 menyimpan memori WiFi terakhir di *chip*-nya, informasi ini langsung dikirim agar Flutter bisa membacanya meskipun sedang *offline*.

```json
{
  "ssid": "Offline (Terakhir: Hotspot_Joko)",
  "saved_wifi": "Hotspot_Joko",
  "device_code": "TGN_0001",
  "battery": "85% (2100)",
  "water": 450,
  "lat": -7.7956,
  "lng": 110.3695,
  "gps_valid": true,
  "buzzer_manual": false
}
```

### C. Cara *Parsing* JSON di Flutter (Dart)
Gunakan paket standar Dart `dart:convert` dan *package* seperti `flutter_blue_plus` untuk membaca aliran *byte*.

```dart
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Asumsikan 'characteristic' adalah TX Characteristic yang Anda dapatkan saat discoverServices()
await characteristic.setNotifyValue(true);
characteristic.lastValueStream.listen((value) {
    if (value.isNotEmpty) {
        // 1. Konversi dari List<int> (Byte Array) ke String UTF-8
        String rawJson = utf8.decode(value);
        
        try {
            // 2. Decode String ke Map/Dictionary
            Map<String, dynamic> data = jsonDecode(rawJson);
            
            // 3. Ambil data yang dibutuhkan
            String deviceCode = data['device_code'];
            String savedWifi = data['saved_wifi']; // <== Ini nama WiFi terakhir yang tersimpan di memori tas
            String batteryText = data['battery'];
            
            // Lakukan pembaruan state UI (setState / Bloc / Provider)
            print("Tas $deviceCode memori WiFi-nya adalah: $savedWifi");
            
        } catch (e) {
            print("Gagal parsing JSON: $e");
        }
    }
});
```

Dengan panduan di atas, Tim Flutter *Developer* Anda tinggal *copy-paste* blok kode tersebut untuk menampilkan data histori WiFi langsung di aplikasi Android/iOS.