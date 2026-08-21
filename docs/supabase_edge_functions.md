# Dokumentasi Supabase Edge Functions

Dokumen ini menjelaskan daftar endpoint Edge Functions yang digunakan pada proyek TAGANA sebagai jembatan logika *backend* (serverless) antara aplikasi Flutter, perangkat ESP32, dan database Supabase.

Base URL Edge Functions:
`https://wkizrilfoovxksyxnstx.supabase.co/functions/v1/`

---

## 1. Register User
**Endpoint:** `/register-user`
**Method:** `POST`

**Deskripsi:**
Menangani proses registrasi dan otentikasi pengguna baru maupun lama (login). Karena aplikasi menggunakan skema autentikasi berbasis nomor telepon (WhatsApp), fungsi ini kemungkinan menerima payload berisi data nomor telepon pengguna dan mengelola proses sinkronisasi dengan *Supabase Auth* dan tabel `user_profiles`.

**Perkiraan Payload Request:**
```json
{
  "phone": "+6281234567890",
  "name": "Nama Pengguna" // opsional jika hanya login
}
```

---

## 2. Pair Device
**Endpoint:** `/pair-device`
**Method:** `POST`
**Headers:** Membutuhkan *Authorization: Bearer [User_Access_Token]*

**Deskripsi:**
Digunakan oleh aplikasi Flutter untuk mendaftarkan (menghubungkan) perangkat TAGANA fisik ke akun pengguna. Fungsi ini akan memvalidasi *device code* dan mengikat perangkat tersebut ke *user_id* yang sedang melakukan *request* ke dalam tabel `devices`.

**Perkiraan Payload Request:**
```json
{
  "device_code": "TGN_001",
  "device_name": "Tas Siaga Utama"
}
```

---

## 3. Device Ingest (Telemetry Sensor)
**Endpoint:** `/device-ingest`
**Method:** `POST`

**Deskripsi:**
Ini adalah endpoint utama yang di-hit (dipanggil) secara langsung oleh **Perangkat ESP32** setiap kali ada data telemetry baru atau peringatan bahaya (banjir). 

Fungsi ini bertugas:
1. Menerima payload JSON dari ESP32.
2. Menyimpan data historis ke tabel `sensor_readings`.
3. Memperbarui status alat terkini di tabel `device_status`.
4. Memicu pembuatan peringatan (`alerts`) dan push notifications (`notifications`) jika terdeteksi anomali seperti air naik melebihi batas atau baterai mau habis.

**Perkiraan Payload Request (Dari Firmware ESP32):**
```json
{
  "object": {
    "bag_id": "TGN_001",
    "water_level": 500,
    "is_flood_detected": true,
    "battery_level": 85,
    "recorded_at": "2026-08-20T10:30:00Z",
    "latitude": -6.123456,
    "longitude": 106.123456
  }
}
```
