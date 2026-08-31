# Laporan Update Fitur & Perbaikan Konektivitas Aplikasi
**Tanggal:** 30 Agustus 2026
**Lokasi Pembaruan:** `lib/features/device/`

## Ringkasan Eksekutif
Dokumentasi ini merangkum perbaikan dan peningkatan logika yang telah dilakukan pada modul *Emergency Mode* dan *Konektivitas Bluetooth (BLE)*. Tujuan utama dari pembaruan ini adalah untuk memastikan alur navigasi dari *Emergency Page* tidak terputus, serta menyajikan indikator status (BLE dan Wi-Fi) yang benar-benar akurat sesuai dengan kondisi asli perangkat (*real-time*).

---

## 1. Perbaikan Navigasi & User Experience (UX) pada `ble_connect_page.dart`
**Alur Logika Lama (Kuno & Kaku):**
Sebelumnya, alur aplikasi bersifat *linear* paksa. Setiap kali pengguna menekan tombol "Hubungkan BLE", terlepas dari halaman mana mereka berasal, aplikasi selalu mengunci mereka dan memindahkan rute secara otomatis (`pushReplacement`) ke halaman `WifiConfigPage`. Hal ini sangat tidak efisien dan membingungkan pengguna jika mereka hanya ingin mengaktifkan sirine (Buzzer) atau melihat status darurat, karena mereka justru "terjebak" di layar konfigurasi Wi-Fi.

**Alur Logika Baru (Fleksibel & Mempermudah User):**
Aplikasi kini lebih cerdas (*context-aware*) dalam menangani navigasi:
- Menginjeksi **query parameter `returnTo`** pada `GoRoute` untuk mendeteksi dari mana pengguna memicu koneksi BLE.
- Saat tombol **"Hubungkan BLE"** ditekan dari `EmergencyPage`, aplikasi menyematkan status `returnTo=emergency`.
- Setelah Bluetooth berhasil dipasangkan (Pairing), sistem akan mengevaluasi parameter tersebut:
  ```dart
  if (widget.returnTo == 'emergency') {
    // Alur UX Baru: 
    // Pengguna dikembalikan langsung ke layar Emergency.
    // Memungkinkan interaksi instan dengan Buzzer dan pemantauan sensor offline tanpa paksaan masuk ke mode konfigurasi.
    context.pop(); 
  } else {
    // Alur Standar: Lanjut ke setup Wi-Fi jika memang dari proses Onboarding.
    context.pushReplacement('/device/${widget.deviceId}/wifi-config');
  }
  ```
Peningkatan UX ini secara drastis menghemat waktu navigasi saat terjadi keadaan darurat bencana.

---

## 2. Refaktorisasi UI `emergency_page.dart`
Perombakan UI agar merespons state konektivitas secara dinamis (tidak lagi statis "Aktif").

**Perubahan pada Kartu Bluetooth Low Energy:**
- Membungkus kartu BLE menggunakan `ValueListenableBuilder` untuk mendengarkan perubahan pada `BleTelemetryService.instance.isConnectedNotifier`.
- Mengubah warna *badge* (hijau jika terhubung, merah jika terputus) secara dinamis.
- Mengunci *(disable)* tombol **"Hubungkan BLE"** saat perangkat terdeteksi sudah terhubung dengan ponsel (tombol memudar dan fungsi `onPressed` dinonaktifkan).
- Hanya tombol **"Bunyikan Buzzer"** yang akan terus dibiarkan dapat diintervensi oleh pengguna.

---

## 3. Akurasi Indikator "Koneksi Wi-Fi" (Pendekatan Hybrid)
**Masalah Sebelumnya:**
Status Wi-Fi dan Internet perangkat secara salah disandarkan murni pada ketersediaan data Bluetooth. Jika koneksi Bluetooth pengguna terputus secara fisik, status Wi-Fi di layar aplikasi ikut berubah menjadi "Terputus", padahal alat (ESP32) masih terhubung ke Internet/Router melalui kelistrikan independen.

**Solusi yang Diimplementasikan:**
Melakukan penggabungan logika lokal (Bluetooth) dan logika *Cloud* (Supabase Realtime) dengan urutan prioritas:
1. **Berlangganan Data Cloud (`DeviceService.subscribeToDeviceDetail`):** 
   `EmergencyPage` sekarang mendengarkan data sinkronisasi Supabase di latar belakang agar selalu mendapatkan *state* perangkat terbaru, sama seperti halnya halaman `Dashboard` dan `DevicePage`.
2. **Kondisi Khusus (Prioritas Lokal):**
   Menerapkan logika cerdas pada metode `build`:
   ```dart
   bool isInternetConnected;
   if (BleTelemetryService.instance.isConnected && data != null) {
     // Jika ponsel terkoneksi Bluetooth ke ESP: baca ketersediaan 'ssid' via telemetry.
     // Hal ini menjamin deteksi instan (tanpa tunggu timeout server 6 menit)
     final wifiSSID = data['ssid']?.toString();
     isInternetConnected = wifiSSID != null && wifiSSID.isNotEmpty && wifiSSID != 'Unknown';
   } else {
     // Jika Bluetooth terputus/jauh: andalkan data dari Cloud (Supabase).
     isInternetConnected = _deviceData?.device.isConnected ?? false;
   }
   ```
3. Mengaplikasikan `isInternetConnected` ke bagian **Analisis Penyebab (Penyebab Status)** dan **Data Emergency (Data Ringkasan)** agar pengguna hanya melihat status Internet/Wi-Fi yang absolut.

---

## Kesimpulan
Seluruh celah disinkronisasi data antara BLE, Server Supabase, dan Antarmuka Pengguna telah diamankan. Alur bagi pengguna teknisi sekarang jauh lebih transparan di lapangan, karena aplikasi mampu memilih metode observasi (Bluetooth/Cloud) terbaik tanpa intervensi manual.
