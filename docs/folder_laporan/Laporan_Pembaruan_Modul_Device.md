# Laporan Pembaruan Modul Device & Services (Tagana App)

**Tanggal:** 24 Agustus 2026  
**Fokus Pembaruan:** Optimalisasi Telemetri, Hybrid Connectivity (BLE & Supabase), Auto-Refresh, dan Pembersihan Kode.

Dokumen ini merangkum seluruh perubahan teknis dan fungsional yang dilakukan pada direktori `lib/features/device` dan `lib/core/services`. Pembaruan ini bertujuan untuk memastikan aplikasi Tagana memiliki performa yang responsif, stabil saat offline maupun online, serta memiliki *codebase* yang bersih dan mudah di-*maintain*.

---

## 1. Perubahan pada `lib/core/services` (Lapisan Data & Konektivitas)

Lapisan *services* telah dirombak untuk mendukung arsitektur *hybrid* (Supabase untuk online, BLE untuk offline) serta memperbaiki isu sinkronisasi data *realtime*.

*   **Migrasi Backend & Optimasi Realtime (`device_service.dart`)**
    *   **Migrasi ke Supabase:** Pemindahan logika data dari Hasura ke Supabase. Modul ini sekarang menggunakan *Edge Functions* untuk proses verifikasi dan *pairing* perangkat (`pair-device`).
    *   **Perbaikan Filter UUID:** Menghapus logika filtering UUID ketat di level klien (Supabase Realtime) karena sering menyebabkan *case-sensitivity error*. Pendekatan diganti dengan me-*reload* status perangkat secara langsung, yang jauh lebih tangguh (robust) mengingat jumlah perangkat per *user* yang relatif kecil.
    *   **Penanganan Reconnect:** Penambahan logika penanganan error HTTP 409 untuk memastikan jika *user* melakukan *pairing* ulang pada alat miliknya sendiri, proses dianggap sukses tanpa memunculkan *error*.

*   **Integrasi Bluetooth Telemetry (`ble_telemetry_service.dart`)**
    *   **Implementasi Protokol Offline:** Menambahkan *service* khusus menggunakan `flutter_blue_plus` untuk membaca data sensor (Water Level, Baterai, Koordinat GPS, dan Status Banjir) langsung dari ESP32 tanpa melalui internet.
    *   **Global Stream Broadcaster:** Menerapkan arsitektur *Singleton* dengan `isConnectedNotifier` dan `telemetryStream` agar seluruh UI aplikasi dapat mendengarkan perubahan status dan data *Bluetooth* secara *realtime*.

---

## 2. Perubahan pada `lib/features/device` (Lapisan UI & Presentasi)

Fokus utama pada lapisan ini adalah otomatisasi pembaruan data sensor (agar *user* tidak perlu melakukan intervensi manual) dan perapian kode *(refactoring)*.

*   **Implementasi Silent Auto-Refresh (`device_detail_page.dart`)**
    *   **Masalah Sebelumnya:** Pembaruan data *realtime* Supabase tidak selalu secara otomatis memperbarui antarmuka pengguna, mengharuskan *user* melakukan *pull-to-refresh* (tarik layar) berulang kali untuk melihat *Water Level* terbaru.
    *   **Solusi:** Mengimplementasikan **Silent Polling (Timer 2 detik)**.
    *   **Mekanisme:** Sebuah `Timer.periodic` ditambahkan pada `initState`. Timer ini berjalan setiap 2 detik di *background* untuk memanggil fungsi `_load()` secara transparan. Timer ini otomatis dinonaktifkan (`cancel()`) saat *page* ditutup (`dispose`), dan **hanya berjalan jika perangkat sedang tidak terkoneksi via BLE** (untuk mencegah bentrok data). Pengguna kini mendapatkan pengalaman pemantauan yang benar-benar mulus tanpa menyadari adanya proses penarikan data di belakang layar.

*   **Logika Data Hybrid (`device_detail_page.dart`)**
    *   UI sekarang secara cerdas merender data dari dua sumber:
        *   Jika terhubung via BLE: Data diambil langsung dari *stream* lokal (mengonversi nilai *raw* sensor 0-1900 menjadi 0-4 cm sesuai kalibrasi ESP32).
        *   Jika terhubung via Internet: Data diambil menggunakan Auto-Refresh Supabase.
    *   Indikator status secara visual beradaptasi menjadi `Terhubung (BLE)` jika koneksi *offline* aktif.

*   **Pembersihan Kode / Penghapusan *Bloatware Comments***
    *   Banyak *file* UI sebelumnya dipenuhi dengan komentar penanda layout yang tidak berguna (contoh: `// Background abstract elements`, `// Header`, `// Bottom Button`, `// Langganan ke stream Global BLE`).
    *   Komentar-komentar *boilerplate* tersebut **telah dihapus secara menyeluruh** dari:
        *   `wifi_connecting_page.dart`
        *   `wifi_connected_page.dart`
        *   `test_connection_page.dart`
        *   `wifi_config_page.dart`
        *   `device_detail_page.dart`
    *   *Codebase* UI kini jauh lebih ringkas. Komentar yang dipertahankan hanyalah dokumentasi teknis terkait *business logic* esensial, seperti alasan teknis batas interval, kalibrasi *water level* ESP32, dan penanganan HTTP stateless.

---

## Kesimpulan Dampak

1.  **UX / User Experience:** Pemantauan indikator vital (*Water level*, Baterai) kini mutlak responsif secara otomatis tanpa tindakan manual apa pun dari *user*, baik saat ada sinyal internet maupun melalui BLE.
2.  **Stabilitas Kode:** Menghindari masalah sinkronisasi Supabase dengan pendekatan *fail-safe polling*.
3.  **Kerapian *(Maintainability)*:** Berkurangnya baris komentar yang mengotori *codebase* mempercepat proses *code-review* di masa mendatang.
