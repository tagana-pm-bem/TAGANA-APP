# Analisis Proyek TAGANA-APP

## 1. Struktur Folder (Feature-First)
Arsitektur menggunakan pola **Feature-First** yang memisahkan fitur berdasarkan domain. Ini sudah rapi dan meminimalisir over-engineering jika tidak ditambah abstraksi berlebihan.

*   **`lib/core/`**: Berisi utilitas dan layanan yang di-share lintas fitur.
    *   `navigation`, `services`, `supabase`, `theme`, `widgets`.
*   **`lib/features/`**: Modul fungsional independen.
    *   `auth`, `dashboard`, `device`, `history`, `map`, `onboarding`, `settings`.

**Rekomendasi (Ponytail Mode):**
*   **YAGNI (You Aren't Gonna Need It):** Jangan buat abstract class/interface untuk repository/service kalau implementasinya cuma satu.
*   Biarkan widget UI langsung memanggil service/state, hindari layer menengah (seperti UseCase) kecuali fiturnya sudah terbukti kompleks.

## 2. Setup Bluetooth (Native BLE)
Berdasarkan `setup_bluetooth.md`, aplikasi menggunakan `flutter_blue_plus` untuk koneksi BLE murni ke perangkat "TAGANA".

*   **Status Saat Ini:** 
    *   Setup permission Android/iOS sudah selesai.
    *   Scan dan filter nama perangkat `TAGANA` beroperasi mandiri (tanpa backend).
    *   Koneksi fisik (connect) dan state UI berfungsi.
*   **Next Step (Minimalist Approach):**
    *   Fokus ke integrasi baca/tulis *characteristic*.
    *   *Backend Integration:* Cukup simpan Device ID yang dipairing ke local storage / Supabase. Jangan buat state sinkronisasi yang rumit sebelum dibutuhkan.
    *   *Auto-reconnect:* Cukup buat satu listener sederhana di background/init app, hindari library background service tambahan kalau OS bisa menangani lewat BLE auto-connect native.
