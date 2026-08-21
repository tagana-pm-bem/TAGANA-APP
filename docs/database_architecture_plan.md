# Dokumen Perencanaan: Arsitektur Database IoT (Supabase)

Dokumen ini merangkum strategi *Backend* untuk menangani data telemetri dari ratusan hingga ribuan Tas Siaga TAGANA (ESP32) tanpa menyebabkan *database bloat* (bengkak/kepenuhan data sampah).

## 1. Prinsip Utama (K.I.S.S - Keep It Simple, Stupid)
- **ESP32 :** ESP32 hanya bertugas melempar data (sensor air, baterai, GPS) secara berkala (tiap 15 detik saat darurat, 30 menit saat normal). Tidak ada logika kepemilikan (No HP/User ID) di dalam mikrokontroler.
- **Supabase "Pintar":** *Edge Function* di Supabase bertugas menyeleksi, menyaring, dan membuang data yang tidak berguna sebelum memasukannya ke tabel riwayat (*History*).

## 2. Struktur Tabel Database

Sistem harus memisahkan data menjadi dua tabel utama:

### A. Tabel `devices_realtime` (Status Saat Ini)
- **Tujuan:** Menampilkan posisi tas di peta dan indikator sensor secara *real-time* di Aplikasi Android.
- **Strategi:** Gunakan perintah **UPSERT** (Update or Insert).
- **Logika:** Jika perangkat `TGN_0001` mengirim data, data lama di tabel ini akan **ditimpa (overwrite)**.
- **Hasil:** Walaupun ada 1.000 tas yang mengirim data jutaan kali, ukuran tabel ini akan selalu mentok di 1.000 baris. Sangat ringan.

### B. Tabel `telemetry_history` (Jejak Perjalanan & Log Banjir)
- **Tujuan:** Menyimpan riwayat jejak rute relawan (GPS) dan riwayat ketinggian banjir untuk grafik statistik.
- **Strategi:** Filter *Significant Delta* (Penyaringan Berbasis Selisih).
- **Logika (Di dalam Edge Function):**
  Sebelum melakukan `INSERT` ke tabel ini, skrip membandingkan data yang baru masuk dengan data terakhir dari tas tersebut:
  1. **Cek Jarak GPS:** Apakah koordinat bergeser > 10 meter (menggunakan rumus *Haversine*)?
  2. **Cek Ketinggian Air:** Apakah level air naik/turun drastis (> 5%)?
  3. **Cek Status Kritis:** Apakah status `is_flood_detected` berubah dari `false` menjadi `true`?
  
  - **Jika salah satu kondisi terpenuhi (YA):** Lakukan `INSERT` sebagai baris baru.
  - **Jika kondisi tidak terpenuhi (TIDAK - Tas diam di tempat):** Jangan lakukan `INSERT` apapun.

## 3. Alur Kepemilikan (Ownership & Security)
- Setiap sensor hanya membawa satu identitas unik murni (`device_code`, misal: `TGN_0001`).
- Relasi antara tas dan pemilik dicatat sepenuhnya di tabel `user_devices` di Supabase (misal: `TGN_0001` dimiliki oleh Nomor HP `0812xxxx`).
- Aplikasi Android akan otomatis membaca kepemilikan ini dari Supabase, lalu mencari koneksi Bluetooth/Hotspot bernama `TAGANA_0001` saat tas berada dalam jangkauan *offline*.