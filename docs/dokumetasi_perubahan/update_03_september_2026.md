# Dokumentasi Perubahan - 3 September 2026

Fokus utama pembaruan kali ini adalah mengubah arsitektur aplikasi menjadi **Offline-First**, memberikan pengalaman pengguna (UX) yang mulus, cepat, dan tanpa *loading* berlebih saat perangkat berada di area susah sinyal atau sama sekali tidak ada internet.

## 1. Arsitektur Offline-First (Local Caching)
Menghapus kebergantungan total aplikasi terhadap koneksi internet melalui mekanisme *Smart Caching* menggunakan `SharedPreferences`. Seluruh layanan telah diperbarui:

- **DashboardService (`fetchDashboardData`)**: Menyimpan ringkasan sensor dan status perangkat secara lokal. Saat mode pesawat atau internet putus, beranda tetap menampilkan data terakhir secara instan.
- **HistoryService (`fetchHistory`)**: Menambahkan fungsi `toJson` dan `fromJson` pada `HistoryEvent` agar semua log aktivitas dan riwayat peringatan tersimpan di penyimpanan internal ponsel.
- **DeviceService (`fetchDevices`)**: Daftar seluruh perangkat sekarang tersimpan secara luring. 
- **DeviceService (`fetchDeviceDetail`)**: Menambahkan fungsi serialisasi pada `DeviceDetailData`, `DeviceLocationInfo`, dan `DeviceActivity`. Jika pengguna dalam keadaan luring dan mencoba melihat perangkat, data *cache* detail akan ditampilkan.
- **Smart Fallback System**: Jika pengguna belum pernah mengklik detail suatu perangkat saat *online*, aplikasi akan menggunakan sistem *fallback* yang secara cerdas mengambil data dasar dari *cache* daftar perangkat (Dashboard) untuk menyusun halaman detail sementara. 
- **Fail-Fast Timeout (2 Detik)**: Menambahkan pembatas `.timeout(const Duration(seconds: 2))` pada seluruh *query* Supabase. Ini mengakhiri kelemahan *OS TCP Timeout* yang sebelumnya membuat layar *loading* tertahan selama 15-30 detik saat ketiadaan sinyal. Aplikasi akan menyadari dalam waktu kurang dari 2 detik bahwa internet terputus dan langsung memuat data lokal.
- **Bug Fix**: Memperbaiki *Type Cast Error* (`dynamic` ke `Map<String, dynamic>`) pada saat membaca memori internal yang sempat menyebabkan layar gagal merender *cache*.

## 2. Pembaruan Map & Tile Caching
- **Anti-Block User Agent**: Menambahkan *header* `'User-Agent': 'com.tagana.app'` ke dalam `CachedTileProvider` agar server *OpenStreetMap* (OSM) tidak lagi memblokir permintaan dari aplikasi.
- **Batasan Skala (Zoom)**: Menambahkan `maxZoom: 19.0` (pada `MapOptions`) dan `maxNativeZoom: 19` (pada `TileLayer`). Perubahan ini menyelesaikan *bug* "Access Blocked" ketika pengguna melakukan *zoom in* yang terlalu dalam (melampaui kemampuan server OSM). Sekarang, peta akan mengambil gambar lokal di zoom 19 lalu merendernya lebih besar secara visual, membuat peta benar-benar bisa bekerja *offline* asalkan area tersebut pernah di-*load* sebelumnya.

## 3. UI/UX & Onboarding
- **Kebijakan Privasi Pintar (Privacy Policy)**: Menggunakan `SharedPreferences` untuk mencatat persetujuan privasi di `PrivacyPolicyPage`. Layar ini hanya akan muncul tepat satu kali seumur hidup aplikasi sesaat setelah aplikasi diinstal, dan tidak akan pernah mengganggu pengguna lagi di masa depan.
- **Scroll Smooth**: Menyuntikkan `BouncingScrollPhysics` ke *ListView* dan *ScrollView* di Dashboard untuk memanfaatkan sepenuhnya *refresh rate* tinggi pada *smartphone* berspesifikasi menengah ke atas, membuat *scrolling* lebih licin.
- **Splash Screen Android (Native Fix)**: Memperbaiki masalah munculnya "Layar Hitam" (Black Screen) sebelum logo *Splash Screen* muncul pada *smartphone* Android API 21+ melalui penyesuaian file `launch_background.xml`. Transisi pembukaan aplikasi kini jauh lebih profesional.

## Status Aplikasi
Aplikasi telah diuji dan kini 100% tahan banting terhadap kondisi hilangnya jaringan secara tiba-tiba tanpa menimbulkan layar macet (*stuck on loading*). Aplikasi siap digunakan dalam pemantauan titik banjir di lokasi lapangan (seperti area pegunungan/hulu) yang rentan mengalami keterbatasan konektivitas internet.
