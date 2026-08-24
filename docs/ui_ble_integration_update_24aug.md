# Dokumentasi Pembaruan Integrasi UI & BLE TAGANA
**Tanggal:** 24 Agustus 2026

Dokumen ini mencatat seluruh perbaikan *bug*, peningkatan *User Experience* (UX), dan sinkronisasi arsitektur antara aplikasi Flutter TAGANA dan *firmware* ESP32.

## 1. Perbaikan Arsitektur Komunikasi BLE (`BleTelemetryService`)
- **Penyesuaian UUID:** Memperbaiki UUID untuk karakteristik RX dan TX agar sama persis dengan *firmware* ESP32 (`beb5483e-36e1-4688-b7f5-ea07361b26a8` & `beb5483e-36e1-4688-b7f5-ea07361b26a9`).
- **Anti-Hang Command:** Fungsi `sendRawCommand` sekarang menggunakan `.timeout(2s)`. Hal ini mencegah aplikasi *freeze* saat menunggu respons dari ESP32 yang tiba-tiba melakukan *restart* (misal: setelah menerima konfigurasi Wi-Fi).
- **Pencegahan Crash Native:** Mengubah fungsi `_cleanupState()`. Pemutusan koneksi yang tiba-tiba dari ESP32 tidak lagi memicu aplikasi untuk melakukan fungsi `disconnect()` ganda yang menyebabkan *PlatformException* dan *crash* di modul Bluetooth Android/iOS.

## 2. Penyempurnaan Halaman Konfigurasi Wi-Fi (`wifi_config_page.dart`)
- **Dynamic Device Code:** Mengganti teks `(TGN_0001)` yang sebelumnya *hardcoded* menjadi dinamis mengikuti kode alat sebenarnya yang terhubung via BLE (menggunakan `BleTelemetryService.instance.connectedDeviceCode`).
- **Fitur Riwayat Wi-Fi Cerdas:** Mengintegrasikan `SharedPreferences` untuk menyimpan hingga 5 pasangan SSID dan *Password* terakhir yang pernah diinputkan. Ditampilkan sebagai *Action Chips* yang dapat ditekan untuk *auto-fill*, sangat memudahkan relawan di lapangan.
- **Fix Layout Overflow:** Menambahkan `resizeToAvoidBottomInset: false` pada `Scaffold` untuk menghindari peringatan layar *overflow* kuning saat *keyboard* ditarik turun berbarengan dengan navigasi pindah halaman.

## 3. Optimasi Halaman Proses Koneksi (`wifi_connecting_page.dart`)
- **Efisiensi Alur UX:** Menghapus fungsi pindai ulang Bluetooth (*scanning* pasca-konfigurasi) yang sebelumnya rumit dan rentan menimbulkan *bug*. Alur diganti dengan jeda statis 5 detik yang diukur secara presisi untuk mengimbangi kecepatan *reboot* dan koneksi cepat dari ESP32, lalu memuluskan animasi hingga berpindah ke layar berhasil.

## 4. Perbaikan Layar Sukses Koneksi (`wifi_connected_page.dart`)
- **Fix Fatal Layout Crash:** Memperbaiki insiden aplikasi tertutup paksa (*crash/freeze*) akibat *infinite width error*. Komponen `Row` berlapis di dalam kotak status kini telah dibatasi menggunakan `mainAxisSize: MainAxisSize.min` dan dibungkus `Flexible` untuk toleransi teks panjang.

## 5. Integrasi Data Real-Time di Mode Darurat (`emergency_page.dart`)
- **Realisasi Data:** Membuang seluruh data tiruan (*mock data*) statis pada bagian status.
- **Implementasi StreamBuilder:** Membungkus *card* status BLE dan ringkasan keadaan darurat dengan pendengar data `telemetryStream` langsung dari mesin BLE. Waktu, level baterai, status sensor banjir, dan status SSID Wi-Fi kini murni mencerminkan kondisi lapangan alat.

## 6. Penyesuaian Status Offline Dashboard (`dashboard_models.dart`)
- Menambahkan logika *timeout* selama 6 menit pada pengecekan data terakhir. Jika sensor berhenti mengirim data melewati batas waktu tersebut, maka status di aplikasi akan otomatis berubah menjadi "Offline", menghindari data kadaluwarsa (bermasalah di lapangan).

---

## Catatan Tambahan (Batasan Arsitektur Firmware Saat Ini)
- **Kontrol Jarak Jauh Via Internet:** Fitur menekan tombol Buzzer saat HP hanya mengandalkan jaringan Wi-Fi lokal/internet belum didukung sepenuhnya oleh ESP32. Hal ini karena ESP32 saat ini diprogram murni untuk "Mendorong" (*Push*) data ke Supabase (via HTTP POST), namun tidak "Menarik" (*Pull/Listen*) perintah dari Supabase. Solusi masa depan: Integrasi MQTT atau pembacaan JSON respons Supabase Edge Function di ESP32.
