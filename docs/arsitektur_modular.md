# Dokumentasi Arsitektur Modular TAGANA

Kode sumber TAGANA telah direfaktor menjadi arsitektur modular di dalam folder `src/`. Tidak ada perubahan logika pada sistem (tetap 100% sama dengan versi file tunggal), melainkan hanya pemisahan kode (*Separation of Concerns*) agar mudah dibaca, dikembangkan, dan sesuai standar *PlatformIO*.

Berikut adalah struktur dan fungsi dari masing-masing file:

## 1. `src/config/config.h`
- **Fungsi Utama:** Menyimpan semua konfigurasi global dan *shared variables*.
- **Detail:** Berisi definisi *pinout* hardware (sensor air, baterai, buzzer, GPS), ambang batas (*threshold*) banjir, konstanta kalibrasi baterai, kredensial Hasura (URL & Secret), serta variabel RTOS (seperti `waterLevelRaw`, `isFlood`, `gpsValid`) yang diakses lintas task.

## 2. `src/utils/utils.h`
- **Fungsi Utama:** Utilitas fungsi *hardware* ringan.
- **Detail:** Saat ini memuat fungsi `beep()` dan `droneBeep()`. Digunakan untuk memberikan umpan balik (feedback) suara ke pengguna, seperti tanda koneksi Wi-Fi berhasil atau mode *hotspot* nyala.

## 3. `src/ui/html_ui.h`
- **Fungsi Utama:** Menyimpan antarmuka Web Dashboard (Captive Portal).
- **Detail:** Mengisolasi *string raw literal* yang berisi HTML, CSS (*styling*, animasi), dan JavaScript. Kode ini bertugas me-*render* tampilan *Tactical Telemetry* saat pengguna mengakses `http://tagana.local` atau IP mode *offline*.

## 4. `src/network/network_api.h`
- **Fungsi Utama:** Menangani HTTP Client (Koneksi Uplink).
- **Detail:** Berisi fungsi `sendToHasura(bool floodStatus)` yang bertugas membangun *payload* JSON (memasukkan ID tas, level air, status darurat, dan koordinat GPS) lalu mengirimkannya ke REST API server Hasura via protokol HTTPS.

## 5. `src/ble/ble_setup.h`
- **Fungsi Utama:** Mengatur konektivitas *Bluetooth Low Energy* (BLE).
- **Detail:** Menampung inisialisasi UUID (Service & Characteristic), manajemen BLE Server, serta logika *Callback* (fungsi `onWrite`). Di sini perintah dari APK Android (seperti `"BUZZER"` atau `"WIFI:SSID:PASS"`) ditangkap dan dieksekusi oleh mikrokontroler.

## 6. `src/web/web_server.h`
- **Fungsi Utama:** Menangani *routing* Web Server Lokal (Port 80).
- **Detail:** Berisi fungsi `setupLocalServer()` yang memetakan jalur URL. Misalnya *endpoint* `/data` untuk memberikan respons JSON status sensor terbaru ke web UI, atau `/setWifi` untuk menyimpan kredensial *hotspot* dari pengguna.

## 7. `src/tasks/tasks.h`
- **Fungsi Utama:** Mengendalikan Multitasking (FreeRTOS Tasks).
- **Detail:**
  - `TaskSensorAlarm` (Core 1): Berjalan tiap 50ms. Membaca sensor analog, melembutkan fluktuasi baterai (rumus EMA), membaca NMEA GPS, dan memicu buzzer alarm saat darurat banjir.
  - `TaskNetwork` (Core 0): Berjalan tiap 100ms. Melayani klien web server, mengirim data ke Hasura, memancarkan notifikasi BLE (data telemetry) ke APK Android, dan mengaktifkan mode Fallback AP saat koneksi putus.

## 8. `src/main.cpp`
- **Fungsi Utama:** *Entry Point* (Titik masuk program utama).
- **Detail:** Hanya memuat `setup()` dan `loop()`. Berfungsi murni untuk mengaktifkan seluruh *library* dan modul `.h` di atas. *Loop* bawaan bahkan dihapus (`vTaskDelete`) agar CPU fokus menjalankan *tasks* FreeRTOS secara efisien.