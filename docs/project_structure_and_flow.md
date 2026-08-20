# Dokumentasi Struktur dan Alur Proyek Tagana App

Dokumen ini menjelaskan struktur folder `lib/` dan alur navigasi dari aplikasi Tagana App berdasarkan konfigurasi routing (`app_router.dart`).

## 1. Struktur Direktori Proyek

Proyek ini dibangun menggunakan kerangka kerja Flutter dan diorganisasikan ke dalam pendekatan berbasis fitur (Feature-First Architecture) yang memisahkan logika ke dalam modul-modul yang berbeda.

```text
lib/
├── app.dart                   # Entry point aplikasi yang membungkus MaterialApp/CupertinoApp
├── main.dart                  # Fungsi main() yang menjalankan aplikasi
├── theme_preview.dart         # Halaman untuk mempratinjau komponen tema
├── core/                      # Modul inti yang digunakan di seluruh fitur aplikasi
│   ├── navigation/            # Konfigurasi perutean (go_router) dan handler navigasi
│   ├── supabase/              # Klien dan konfigurasi untuk koneksi ke backend Supabase
│   ├── theme/                 # Sistem desain: warna, jarak, tipografi, dan tema global
│   └── widgets/               # Komponen UI global/reusable (misal: header)
└── features/                  # Modul berbasis fitur dari aplikasi
    ├── auth/                  # Repositori dan model terkait autentikasi pengguna
    ├── dashboard/             # Halaman utama (beranda) aplikasi
    ├── device/                # Fitur manajemen perangkat keras (BLE, WiFi, Hotspot, Darurat)
    ├── history/               # Riwayat aktivitas atau log
    ├── map/                   # Fitur pemetaan dan lokasi
    ├── onboarding/            # Alur orientasi (splash, register, dan pemasangan perangkat)
    └── settings/              # Konfigurasi aplikasi, profil, dan bantuan pengguna
```

## 2. Alur Navigasi Aplikasi

Navigasi di dalam aplikasi menggunakan paket `go_router`. Berikut adalah alur lengkap perjalanan pengguna dari mulai masuk aplikasi hingga fitur-fitur di dalamnya.

### A. Alur Awal (Onboarding & Autentikasi)
1. **Splash Screen (`/splash`)**: Tampilan awal saat aplikasi dimuat.
2. **Welcome Page (`/welcome`)**: Halaman selamat datang, tempat pengguna bisa memilih untuk masuk atau mendaftar.
3. **Register (`/register`)**: Halaman pendaftaran pengguna baru.

### B. Alur Pemasangan Perangkat (Device Pairing Flow)
Jika pengguna baru dan harus mendaftarkan perangkat, alur berikut akan dijalankan:
1. **Masukkan Kode Perangkat (`/enter-device`)**: Pengguna memasukkan kode identifikasi perangkat Tagana.
2. **Verifikasi Perangkat (`/verifying-device/:deviceCode`)**: Memvalidasi kode perangkat yang dimasukkan.
3. **Koneksi Bluetooth (`/bluetooth/:deviceCode`)**: Memindai dan menyambungkan ke perangkat melalui BLE (Bluetooth Low Energy).
4. **Koneksi Berhasil (`/connection-success/:deviceId`)**: Konfirmasi perangkat berhasil terhubung, lalu diteruskan ke Dashboard.

### C. Alur Utama (Shell/Bottom Navigation Bar)
Aplikasi utama menggunakan antarmuka berlapis (Shell Route) dengan bilah navigasi bawah.
1. **Dashboard (`/dashboard`)**: Halaman ringkasan status alat dan notifikasi cepat.
2. **Perangkat (`/devices`)**: Daftar perangkat yang ditautkan ke akun.
3. **Peta (`/map`)**: Lokasi terkini perangkat atau titik pemantauan.
4. **Riwayat (`/history`)**: Log dari aktivitas atau peristiwa penting yang direkam perangkat.
5. **Pengaturan (`/settings`)**: Menu konfigurasi akun dan sistem.

### D. Alur Detail Perangkat
Ketika pengguna memilih salah satu perangkat dari menu `/devices`:
- **Detail Perangkat (`/device/:id`)**: Informasi lengkap status perangkat (online/offline, baterai, dll).
- **Tes Koneksi (`/device/:id/test-connection`)**: Memeriksa konektivitas jaringan perangkat.
- **Panggilan Darurat (`/device/:id/emergency`)**: Menu tindakan cepat untuk keadaan darurat.
- **Konfigurasi Hotspot (`/device/:id/hotspot`)**: Mengatur koneksi perangkat via Hotspot.
- **Konfigurasi WiFi (`/device/:id/wifi-config`)**: Menghubungkan perangkat ke jaringan WiFi.
- **Koneksi BLE (`/device/:id/ble`)**: Mode koneksi langsung melalui Bluetooth.

### E. Alur Detail Pengaturan
Berasal dari menu utama pengaturan, membuka halaman secara langsung tanpa Bottom Navigation Bar:
- **Profil (`/settings/profile`)**: Menampilkan profil pengguna saat ini.
- **Edit Profil (`/settings/edit-profile`)**: Mengubah nama, foto, atau detail lainnya.
- **Telepon (`/settings/phone`)**: Mengatur nomor kontak seluler.
- **Bantuan (`/settings/help`)**: Layanan dukungan pelanggan atau FAQ.
- **Tentang (`/settings/about`)**: Informasi versi aplikasi dan legalitas.
