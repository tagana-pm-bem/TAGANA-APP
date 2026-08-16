# Setup: real Bluetooth scan/connect

Halaman `bluetooth_connection_page.dart` sekarang pakai **flutter_blue_plus**
buat scan & connect beneran ke perangkat fisik (nama device diawali
`TAGANA`). Belum ada panggilan ke backend — murni native BLE dulu.

## 1. Tambah dependency

```yaml
# pubspec.yaml
dependencies:
  flutter_blue_plus: ^1.35.5
  permission_handler: ^11.3.1
```

```bash
flutter pub get
```

## 2. Android — `android/app/src/main/AndroidManifest.xml`

Tambahkan di dalam `<manifest>`, sebelum tag `<application>`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"
    android:maxSdkVersion="30" />

<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

`minSdkVersion` di `android/app/build.gradle` minimal **21** (idealnya 23+).

> Catatan: `neverForLocation` dipakai karena kita tidak butuh lokasi fisik
> device, hanya scan by name. Kalau nanti butuh RSSI-based
> distance/lokasi, hapus flag ini dan pastikan minta izin lokasi juga
> (sudah ada di kode lewat `permission_handler`).

## 3. iOS — `ios/Runner/Info.plist`

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Aplikasi memerlukan akses Bluetooth untuk terhubung ke perangkat TAGANA.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>Aplikasi memerlukan akses Bluetooth untuk terhubung ke perangkat TAGANA.</string>
```

iOS tidak mengizinkan Bluetooth dinyalakan lewat kode — kalau mati, user
diarahkan ke Pengaturan (sudah dihandle di `_turnOnBluetoothIfPossible`).

## 4. Pakai halamannya

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BluetoothConnectionPage(
      deviceNamePrefix: 'TAGANA',
      onConnected: (device) {
        // device.device -> BluetoothDevice asli dari flutter_blue_plus
        // Nanti di sini tinggal ditaruh logic ke BE (kirim device id,
        // baca characteristic, dsb) begitu sudah siap.
      },
    ),
  ),
);
```

## Apa yang sudah nyala vs belum

**Sudah jalan (native, tanpa BE):**
- Minta izin runtime (Android 12+: `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT`,
  Android lama: lokasi).
- Deteksi kalau adapter Bluetooth di HP mati → tampil kartu "Aktifkan
  Bluetooth" (tombol `FlutterBluePlus.turnOn()` di Android; di iOS arahkan
  ke Settings).
- Scan real selama 15 detik, filter nama device yang diawali
  `TAGANA`, muncul sebagai list card (bisa lebih dari satu kalau ada
  beberapa perangkat).
- Tap card / tombol "Hubungkan" → `device.connect()` beneran, dengar
  `connectionState` stream buat update UI (connecting → connected).
- Kalau scan habis waktu tanpa hasil, atau koneksi gagal/putus → state
  "Gagal Terhubung" dengan tombol "Coba Lagi".

**Belum (menyusul saat integrasi BE):**
- Baca/tulis characteristic (misal ambil data sensor TAGANA).
- Simpan hasil pairing ke server / local storage.
- Auto-reconnect kalau app dibuka ulang.