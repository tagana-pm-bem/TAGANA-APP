# Dokumentasi Pembaruan Aplikasi TAGANA
**Tanggal:** 1 September 2026
**Fokus Utama:** Optimasi Performa Navigasi, Penyempurnaan UI/UX (Estetika Premium), & Sinkronisasi Onboarding.

---

## 1. Pembaruan Navigasi Inti & Manajemen Memori
Salah satu pembaruan terbesar pada rilis kali ini adalah perubahan fundamental pada cara aplikasi menangani perpindahan antar halaman utama (Dashboard, Perangkat, Riwayat, Peta).

- **Migrasi ke `StatefulShellRoute`:** Sebelumnya aplikasi menggunakan `ShellRoute` biasa yang menyebabkan halaman di-render ulang (re-render) setiap kali pengguna berpindah tab. Kami telah mengubah arsitektur router (`app_router.dart`) menjadi `StatefulShellRoute`. Ini memungkinkan aplikasi menggunakan sistem `IndexedStack` (menyimpan *state* memori secara *offstage*). 
- **Dampak Performa:** Perpindahan antar tab kini terasa instan, posisi *scroll* pengguna tetap terjaga, memori RAM menjadi jauh lebih efisien karena tidak ada *rebuild* widget besar secara berulang, dan konsumsi baterai akan lebih hemat karena tidak memicu proses *fetching* data berlebihan setiap pindah tab.
- **Transisi Animasi Premium (`AnimatedBranchContainer`):** Menambahkan efek *slide-and-fade* yang terarah. Saat menekan tab di sebelah kanan, halaman akan bergeser lembut dari kanan, begitu juga sebaliknya. Hal ini memberikan kesadaran ruang (*spatial awareness*) layaknya aplikasi kelas atas.

## 2. Implementasi Skeleton Loading (Modern UI)
Proses pemuatan data (*fetching*) kini tidak lagi menggunakan indikator putar standar (`CircularProgressIndicator`) yang terkesan kaku.

- **Komponen `SkeletonLoader` Baru:** Dibuat widget kustom di `lib/core/widgets/skeleton_loader.dart` yang mensimulasikan bentuk antarmuka saat data sedang dimuat dengan efek *shimmer/pulse* yang elegan.
- **Penerapan Luas:** Indikator baru ini diterapkan di tiga halaman utama yang berat akan data:
  - `DashboardPage`
  - `DevicesPage`
  - `HistoryPage`
- **Hasil Akhir:** Saat pengguna me-refresh halaman (Pull-to-Refresh) atau menunggu data di latar belakang, kerangka UI akan terlihat, menjaga kontinuitas desain dan mengurangi rasa menunggu bagi pengguna (*perceived performance*).

## 3. Optimasi Antarmuka Peta (Map)
- **Penanganan Titik Kordinat Bertumpuk (Clustering):** Menyelesaikan masalah di mana dua atau lebih sensor yang berada di lokasi geografis yang persis sama saling menumpuk secara berantakan. Sebelumnya, teks ID perangkat (misalnya `TGN_0002` dan `TGN_0004`) akan bertumpuk silang dan sulit dibaca kecuali pengguna melakukan zoom maksimal. Teks ID tersebut telah dihilangkan dari tampilan pin *default* agar UI peta tetap bersih.
- **Fitur Loncatan Peta (Zoom-to-Sensor):** Menambahkan panel interaktif berisi tombol perangkat-perangkat yang telah terhubung dengan akun pengguna. Menekan tombol tersebut akan langsung memfokuskan (*zoom-in*) peta secara instan ke titik koordinat sensor. State pilihan sensor ini disimpan agar aplikasi 'mengingat' pengaturan saat aplikasi dibuka kembali.

## 4. Re-branding & Standarisasi Halaman Onboarding
Pengalaman pertama pengguna saat membuka aplikasi sangat menentukan. Seluruh halaman orientasi (Onboarding) telah dirapikan agar konsisten dengan desain yang minimalis dan profesional.

- **Desain Ulang `WelcomePage` & `SplashPage`:**
  - Latar belakang telah diseragamkan menjadi warna putih murni.
  - Elemen desain lama (seperti latar belakang gambar bergradasi dan ikon ombak) telah dihapus.
  - Fokus utama sekarang langsung tertuju pada identitas *brand* utama, dengan menampilkan logo sentral TAGANA (`assets/icons/logo.jpg`) berukuran 160x160 hingga 200x200 pixel tepat di tengah halaman.
  - Menghilangkan elemen teks "TAGANA" besar yang redundan dengan logo.
- **Standarisasi Footer Versi Aplikasi:**
  - Diciptakan komponen *reusable* (DRY) baru bernama `AppVersionFooter`.
  - Komponen ini menyematkan teks statis **"Versi 1.0.0 (BETA)"** dengan gaya tipografi redup (muted) di posisi paling bawah layar.
  - Komponen ini diimplementasikan di **seluruh alur orientasi**, antara lain:
    1. `splash_page.dart`
    2. `welcome_page.dart`
    3. `login.dart`
    4. `register.dart`
    5. `enter_device.dart`
    6. `verifying_device.dart`
    7. `bluetooth_connection.dart`
    8. `connection_success.dart`
  - Dengan pendekatan komponen terpusat, modifikasi versi aplikasi di pembaruan selanjutnya hanya perlu mengubah satu *file* dan otomatis berlaku secara global.

## 5. Penyempurnaan AppHeader
- Mempercantik logika tampilan foto profil. Jika pengguna belum mengunggah avatar, aplikasi akan mengonversi nama mereka menjadi inisial dengan latar belakang gradien yang sangat estetik dan sejajar sempurna dengan hierarki tipografi *header*.

## 6. Penyesuaian Backend (Basis Data Supabase)
- Menyediakan instruksi dan struktur *query SQL* untuk proses *seeding* (penanaman) perangkat baru massal ke tabel `devices` di Supabase. 
- *Query* dirancang cerdas dengan ID yang di-*generate* secara acak menggunakan `gen_random_uuid()` dan sengaja mengosongkan *foreign key* `user_id` (`NULL`).
- Mengatur nama bawaan generik (`Perangkat Baru`) agar perangkat yang dibeli dan didistribusikan tidak terikat secara linguistik dengan wilayah tertentu (contoh sebelumnya terikat lokasi seperti "Jogja" dll), memastikan sistem *pairing* bisa dilakukan murni lewat aplikasi (On-demand Pairing).

## 7. Optimasi Alur Koneksi Perangkat (BLE & Wi-Fi)
- **Logika Navigasi Pintar (BLE ke Wi-Fi):** Memperbaiki alur saat menghubungkan perangkat secara *offline*. Kini, pengguna yang mengakses menu "Setup Offline" dari daftar perangkat (`devices_page.dart`) atau "Pengaturan Wi-Fi" dari detail perangkat (`device_detail_page.dart`) akan diarahkan ke *Scanner* Bluetooth terlebih dahulu jika belum terhubung, lalu otomatis diteruskan ke halaman Pengaturan Wi-Fi setelah Bluetooth sukses tersambung (dengan `returnTo=wifi-config`).
- **Penyempurnaan Scanner Bluetooth:** Mengubah sistem filter pemindaian di `bluetooth_connection.dart` agar lebih pintar (Toleransi tinggi / *Case-Insensitive*). Scanner kini mengekstrak 4 digit kode target (misal `0004`) dan mencari alat dengan nama yang mengandung kode tersebut serta berawalan "TAGANA", sehingga variasi nama udara seperti `TAGANA-0004`, `TAGANA_0004`, atau `Tagana 0004` tetap terdeteksi.
- **Pemisahan Fase Verifikasi & *Pairing*:** Memperbaiki *bug* di mana perangkat langsung masuk ke akun pengguna walau belum berhasil dihubungkan via Bluetooth. Telah dibuat fungsi `verifyDeviceOnly` di `device_service.dart` agar pada fase input kode, aplikasi murni hanya memvalidasi keberadaan alat di Supabase tanpa mengikatnya. Proses klaim kepemilikan alat ke akun pengguna (*Pairing*) sekarang hanya dieksekusi di akhir alur ketika koneksi Bluetooth 100% berhasil.
- **Perbaikan Tombol Navigasi (Onboarding):** Memperbaiki *bug* pada tombol *Back* (Kembali) dan *Batal* di halaman `enter_device.dart` serta `bluetooth_connection.dart`. Tombol kini cerdas memeriksa riwayat rute dengan `context.canPop()`, sehingga tidak menimbulkan *error* dan akan mengarahkan pengguna kembali ke Dashboard atau tahap input dengan mulus jika riwayat rute kosong.
- **Validasi Tombol Mode Darurat:** Di halaman `wifi_config_page.dart`, tombol "Putuskan Internet (Mode Darurat)" kini akan **dinonaktifkan (disabled)** secara otomatis jika sensor memang sudah dalam keadaan *Offline* di *database*, untuk mencegah pengguna menekan aksi yang tidak relevan dengan status jaringan.

---
*Dokumen ini dibuat secara terotomasi untuk menjaga jejak sejarah pengembangan TAGANA Flood Monitor.*
