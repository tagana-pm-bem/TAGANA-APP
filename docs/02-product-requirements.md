# TAGANA Product Requirements Document (PRD)
## Version 1.0 — Draft for Team Review

**Status:** Draft — Untuk Internal Team  
**Date:** August 14, 2026  
**Source:** TAGANA System Requirements Specification v1.0  

---

## TABLE OF CONTENTS

1. [Tujuan Dokumen](#tujuan-dokumen)
2. [Deskripsi Produk](#deskripsi-produk)
3. [Target User & Use Cases](#target-user--use-cases)
4. [Product Scope & Features](#product-scope--features)
5. [User Journeys](#user-journeys)
6. [User Stories](#user-stories)
7. [Functional Product Requirements](#functional-product-requirements)
8. [Acceptance Criteria](#acceptance-criteria)
9. [Edge Cases & Error Handling](#edge-cases--error-handling)
10. [Out of Scope](#out-of-scope)
11. [Open Questions / TBD](#open-questions--tbd)
12. [Feature Tracking Matrix](#feature-tracking-matrix)

---

## TUJUAN DOKUMEN

Dokumen ini menjadi **Product Requirements Document (PRD)** untuk aplikasi TAGANA versi 1.0. PRD ini berfungsi sebagai jembatan antara System Requirements Specification (SRS) dan tahap User Flow / Use Case Design.

Dokumen ini menjelaskan:
- **WHAT:** Fitur-fitur produk yang akan dibangun
- **WHY:** Tujuan bisnis dan nilai yang diberikan kepada user
- **WHO:** Target user dan persona yang dilayani
- **Constraints & Limitations:** Apa yang tidak termasuk dalam scope

Dokumen ini **BUKAN** design document — tidak mencakup UI/UX details, technical architecture, atau implementation decisions.

---

## DESKRIPSI PRODUK

### 1.1 Ringkasan Produk

**TAGANA** adalah aplikasi mobile berbasis Flutter yang memungkinkan pengguna untuk memantau kondisi ketinggian air (water level) di lokasi tertentu secara real-time menggunakan perangkat IoT berbasis ESP32.

Sistem ini dirancang untuk operasi dalam dua mode konektivitas:
1. **Mode Normal:** Komunikasi melalui WiFi dengan koneksi Internet
2. **Mode Darurat:** Komunikasi langsung melalui BLE atau WiFi Hotspot (offline-capable)

### 1.2 Masalah yang Diselesaikan

**Masalah Utama:**
- Pengguna tidak dapat memantau ketinggian air di lokasi lapangan secara real-time untuk tujuan monitoring dan pengendalian
- Tidak ada visibilitas jauh ke lokasi pemantauan tanpa harus hadir fisik di lokasi
- Ketika koneksi internet tidak tersedia, pengguna tidak dapat mengakses data monitoring

**Solusi:**
- Aplikasi TAGANA menyediakan dashboard real-time yang memudahkan pengguna melihat status ketinggian air dari perangkat mobile
- User dapat mendaftarkan multiple perangkat monitoring dan mengelola semuanya dari satu aplikasi
- Sistem support fallback mechanism (BLE + Hotspot) untuk akses darurat saat internet tidak tersedia

### 1.3 Nilai yang Diberikan kepada User

| Aspek | Nilai |
|-------|-------|
| **Visibilitas** | Real-time monitoring air dari jarak jauh tanpa harus datang ke lokasi |
| **Efisiensi** | Mengelola multiple lokasi monitoring dari satu aplikasi |
| **Reliability** | Emergency access mode untuk kondisi ketika internet tidak tersedia |
| **Kontrolabilitas** | Kemampuan untuk reset network dan reconfigure perangkat kapan saja |
| **Historisitas** | Tracking data riwayat untuk analisis trend [Detail: OQ-004] |

---

## TARGET USER & USE CASES

### 2.1 Primary User Persona

**Nama:** Field Monitor / Operator Lapangan  
**Deskripsi:** Pengguna yang bertugas memantau kondisi ketinggian air di satu atau lebih lokasi pemantauan

**Karakteristik:**
- Melakukan monitoring secara berkala (harian, per jam, atau sesuai kebutuhan)
- Bekerja di lokasi dengan konektivitas internet variable (kadang offline, kadang online)
- Perlu informasi cepat tentang status ketinggian air untuk pengambilan keputusan
- Tidak memiliki expertise teknis yang tinggi — perlu UI sederhana dan intuitif
- Mungkin perlu berbagi informasi dengan tim atau supervisor

**Kebutuhan Utama:**
1. Melihat status air terkini dari multiple perangkat
2. Akses data bahkan saat internet tidak tersedia
3. Memahami trend ketinggian air dari waktu ke waktu
4. Mudah mengkonfigurasi ulang perangkat jika perlu

### 2.2 Secondary User Personas

**Nama:** Administrator / Supervisor  
**Deskripsi:** Pengguna yang mengelola multiple operator dan perangkat  
**Kebutuhan:** [TBD - OQ-003 tentang role admin/supervisor belum diputuskan]

### 2.3 Primary Use Cases

| Use Case | Deskripsi | Frequency |
|----------|-----------|-----------|
| **Monitor Status Air** | User membuka aplikasi dan melihat status ketinggian air terkini dari perangkat yang dimiliki | Setiap hari, multiple kali |
| **Setup Perangkat Baru** | User mendaftarkan perangkat IoT baru ke akun menggunakan kode TGN | Sebagai kebutuhan |
| **Lihat Riwayat Air** | User melihat trend ketinggian air dalam periode waktu tertentu (hari, minggu, bulan) | Weekly atau on-demand |
| **Reset Konfigurasi Network** | User mereset konfigurasi WiFi perangkat saat perlu reconfig | Sebagai kebutuhan |
| **Akses Darurat via BLE** | User mengakses data monitoring via BLE saat internet tidak tersedia | Emergency only |
| **Akses Darurat via Hotspot** | User mengakses Local Web Interface ESP32 saat internet tidak tersedia | Emergency only |

---

## PRODUCT SCOPE & FEATURES

### 3.1 Feature Overview

Aplikasi TAGANA terdiri dari **13 fitur utama** yang diorganisir dalam halaman/section berikut:

#### A. Onboarding & User Profile Management

**Feature 1: User Registration / Profil Pengguna**

**Tujuan:** Memfasilitasi pengguna membuat identitas di sistem TAGANA

**Deskripsi:**
- Pada penggunaan pertama, user membuat profil dengan memasukkan nama (required)
- Email & password TIDAK digunakan pada versi awal (pengambilan identitas: [TBD - OQ-001])
- Profil pengguna disimpan di backend untuk keperluan asosiasi ownership perangkat
- User dapat melihat profil mereka di halaman Pengaturan [TBD - OQ-017]

**User Benefit:** User dapat langsung mulai menggunakan aplikasi tanpa perlu proses registrasi rumit

**Scope:** Hanya pembuatan profil dasar (nama). Detail profil management: [TBD]

---

#### B. Device Management & Onboarding

**Feature 2: Device Registration via TGN Code**

**Tujuan:** Memudahkan user mendaftarkan perangkat IoT baru ke akun

**Deskripsi:**
- User memasukkan kode TGN (format: TGN_XXXX, contoh: TGN_0001)
- Perangkat TAGANA memiliki kode unik yang printed pada label fisik
- Setiap perangkat hanya dapat didaftarkan 1x (baca OQ-015 tentang ownership rules)
- Ownership perangkat disimpan di backend, bukan hanya di local storage aplikasi

**User Benefit:** Mudah mengidentifikasi dan mendaftarkan perangkat fisik tanpa perlu technical knowledge

**Scope:** Hanya input dan validasi kode. Detail claiming rules: [TBD - OQ-015]

---

**Feature 3: BLE Device Discovery & Verification**

**Tujuan:** Memastikan perangkat yang didaftarkan adalah perangkat yang benar-benar dimiliki user

**Deskripsi:**
- Setelah user input kode TGN, aplikasi akan melakukan BLE scan untuk menemukan perangkat
- Aplikasi memverifikasi bahwa perangkat BLE yang ditemukan sesuai dengan kode TGN yang diinput
- Jika ada mismatch (perangkat tidak sesuai), proses registration dibatalkan
- BLE pairing & security mechanism: [TBD - OQ-007]

**User Benefit:** Memastikan user mendaftarkan perangkat yang benar, mencegah kesalahan

**Scope:** Discovery dan verification only. BLE security detail teknis: [TBD]

---

**Feature 4: WiFi Configuration during Setup**

**Tujuan:** Mengonfigurasi koneksi WiFi pada perangkat ESP32 saat initial setup

**Deskripsi:**
- User memasukkan WiFi credential (SSID dan Password) melalui interface aplikasi
- Credential dikirimkan ke ESP32 melalui komunikasi BLE
- ESP32 menghubungkan diri ke WiFi jaringan dengan credential tersebut
- Setelah berhasil terhubung WiFi, perangkat siap mengirim data ke backend
- Security mechanism BLE untuk credential transmission: [TBD - OQ-007]

**User Benefit:** Setup WiFi tidak perlu physical access ke perangkat ESP32, lebih mudah

**Scope:** Input credential & transmission. Detailed security mechanism: [TBD]

---

**Feature 5: Multi-Device Management**

**Tujuan:** Memungkinkan user memiliki dan mengelola lebih dari satu perangkat TAGANA

**Deskripsi:**
- Satu user dapat mendaftarkan multiple perangkat (tanpa batas: [TBD - OQ-008])
- User hanya dapat melihat perangkat yang dimilikinya
- Setiap perangkat memiliki ownership unik di backend
- User dapat mengakses, monitoring, dan configure setiap perangkat secara independen
- Ownership rules detail (sharing, transfer, dll): [TBD - OQ-015]

**User Benefit:** Pengguna dapat mengelola monitoring di multiple lokasi dari satu aplikasi

**Scope:** Multi-device model & filtering per user. Ownership transfer: [TBD]

---

#### C. Monitoring Features

**Feature 6: Dashboard — Real-time Status Overview**

**Tujuan:** Memberikan user visual yang jelas tentang status semua perangkat mereka

**Deskripsi:**
- Dashboard menampilkan ringkasan status perangkat yang dimiliki user
- Informasi yang ditampilkan:
  - Total jumlah perangkat terdaftar
  - Jumlah perangkat yang sedang online
  - Jumlah perangkat yang offline
- User dapat memilih salah satu perangkat untuk melihat detail monitoring
- Dashboard hanya menampilkan perangkat milik user yang login, bukan semua perangkat sistem

**User Benefit:** User dapat dengan cepat melihat overview semua perangkat mereka dalam satu layar

**Status:** CONFIRMED

---

**Feature 7: Device Detail — Comprehensive Monitoring**

**Tujuan:** Menampilkan informasi detail dan real-time dari satu perangkat

**Deskripsi:**
- Halaman ini menampilkan semua informasi monitoring untuk satu perangkat:
  1. **Device Code (TGN_XXXX)** — Identitas perangkat
  2. **Water Level** — Ketinggian air terkini (satuan: [TBD - OQ-002])
  3. **GPS / Location** — Lokasi geografis perangkat (format: [TBD - OQ-012])
  4. **Battery Status** — Kondisi baterai perangkat
  5. **WiFi Status** — Status koneksi WiFi (connected / disconnected / signal strength)
  6. **Connection Status** — Online / Offline indicator
  7. **Last Update** — Timestamp kapan data terakhir diterima
- Data diupdate sesuai interval pengiriman dari perangkat ([TBD - OQ-014])

**User Benefit:** User dapat melihat semua informasi monitoring perangkat dalam satu halaman

**Status:** CONFIRMED

---

**Feature 8: Water Level Monitoring**

**Tujuan:** Melacak dan menampilkan ketinggian air dari sensor perangkat

**Deskripsi:**
- Data water level adalah data utama dari sistem TAGANA
- Water level ditampilkan di Dashboard (Fitur 6), Device Detail (Fitur 7), Map (Fitur 10), dan History (Fitur 11)
- Sensor specification (jenis, satuan, rentang, akurasi): [TBD - OQ-002]
- Alert/notification saat water level melebihi threshold: [TBD - OQ-011 dan OQ-016]

**User Benefit:** User dapat memonitor kondisi ketinggian air real-time atau trend historis

**Status:** CONFIRMED (measurement specification: TBD)

---

**Feature 9: Location / GPS Tracking**

**Tujuan:** Menampilkan lokasi geografis perangkat untuk referensi user

**Deskripsi:**
- Setiap perangkat melaporkan lokasi geografisnya (GPS atau network-based: [TBD])
- Lokasi ditampilkan di Device Detail dan Map
- Format penyimpanan & display lokasi: [TBD - OQ-012]
- Accuracy & update frequency: [TBD - OQ-014]

**User Benefit:** User dapat mengetahui lokasi fisik setiap perangkat monitoring

**Status:** CONFIRMED (format & accuracy: TBD)

---

**Feature 10: Battery Monitoring**

**Tujuan:** Memastikan user mengetahui kondisi baterai perangkat

**Deskripsi:**
- Perangkat melaporkan status baterai pada setiap pengiriman data
- Status ditampilkan di Device Detail
- **Alert/Notification saat battery kritis:** [TBD - OQ-016]
  - Threshold kritisnya berapa %: [TBD]
  - Mekanisme notifikasi: [TBD]

**User Benefit:** User dapat merencanakan maintenance baterai sebelum perangkat mati

**Status:** CONFIRMED (critical threshold & notification: TBD)

---

**Feature 11: WiFi Status Indication**

**Tujuan:** Menampilkan kondisi koneksi WiFi perangkat

**Deskripsi:**
- Perangkat melaporkan status WiFi connection (connected/disconnected/signal strength)
- Status ditampilkan di Device Detail
- Berguna untuk troubleshooting masalah konektivitas

**User Benefit:** User dapat dengan cepat mengidentifikasi masalah network pada perangkat

**Status:** CONFIRMED

---

**Feature 12: Map View — Location-based Monitoring**

**Tujuan:** Menampilkan lokasi semua perangkat di peta untuk visualisasi geografis

**Deskripsi:**
- Halaman Peta menampilkan semua perangkat milik user pada peta digital
- Setiap perangkat ditampilkan sebagai pin/marker pada koordinat GPS-nya
- User dapat berinteraksi dengan peta (zoom, pan, dan memilih perangkat)
- **Behavior detail (clustering, filtering, navigation):** [TBD - OQ-005]
- Data hanya menampilkan perangkat milik user, bukan semua perangkat sistem

**User Benefit:** Visualisasi geografis memudahkan user memahami distribusi perangkat monitoring

**Status:** CONFIRMED (detailed behavior: TBD)

---

**Feature 13: History View — Trend Data Analysis**

**Tujuan:** Memungkinkan user melihat trend ketinggian air dalam periode waktu tertentu

**Deskripsi:**
- Halaman Riwayat menampilkan data monitoring historis dari perangkat
- User dapat memilih:
  - Perangkat yang ingin dilihat riwayatnya
  - Periode waktu (hari, minggu, bulan, custom range)
- Data ditampilkan dalam format yang mudah dilihat (grafik/tabel: [TBD - OQ-004])
- **Detail Riwayat yang masih TBD:**
  - Berapa lama data disimpan (retention policy): [TBD - OQ-004]
  - Granularitas data (per detik/menit/jam): [TBD - OQ-004]
  - Apakah ada aggregasi data: [TBD - OQ-004]
  - Fitur export data: [TBD - OQ-004]

**User Benefit:** User dapat menganalisis trend data untuk decision making / planning

**Status:** CONFIRMED (retention & format: TBD)

---

#### D. Configuration & Emergency Features

**Feature 14: Settings Page — User & App Preferences**

**Tujuan:** Memungkinkan user mengatur preferensi aplikasi dan manajemen akun

**Deskripsi:**
- Halaman Pengaturan mencakup:
  - **User Profile** — Lihat/edit profil pengguna [TBD - OQ-017]
  - **Notification Preferences** — Setting notifikasi air level, battery, dll [TBD - OQ-016]
  - **App Settings** — Preference aplikasi (bahasa, theme, dll) [TBD]
  - **About / Help** — Informasi aplikasi [TBD]
  - **Logout / Account Removal** — Pilihan keluar atau hapus akun [TBD]

**User Benefit:** User dapat customize pengalaman aplikasi sesuai preferensi

**Status:** CONFIRMED - Main existence ✓ | Details: TBD (OQ-017)

---

**Feature 15: WiFi Configuration / Reconfiguration**

**Tujuan:** Memungkinkan user mengubah konfigurasi WiFi perangkat setelah initial setup

**Deskripsi:**
- Fitur ini digunakan saat user perlu mengubah jaringan WiFi yang digunakan perangkat
- Terintegrasi dengan Network Reset feature (Fitur 16)
- Prosesnya sama dengan WiFi configuration saat setup (input credential via BLE)
- Tidak perlu mendaftarkan ulang perangkat

**User Benefit:** User dapat mengubah jaringan WiFi tanpa harus men-return perangkat

**Status:** CONFIRMED (via FR-017 & REC-001)

---

**Feature 16: Network Reset Functionality**

**Tujuan:** Memungkinkan user mereset konfigurasi jaringan perangkat untuk troubleshooting

**Deskripsi:**
- User dapat memicu Network Reset dari aplikasi (melalui halaman Device Detail)
- Setelah reset:
  - Konfigurasi WiFi sebelumnya dihapus dari ESP32
  - ESP32 kembali menyediakan akses BLE
  - ESP32 menyediakan WiFi Hotspot
  - **User dapat melakukan WiFi reconfiguration dari awal**
- **PENTING:** Ownership perangkat dan data monitoring historis TIDAK berubah setelah reset
- Firmware detail implementasi: [TBD - ASM-007]

**User Benefit:** User dapat self-troubleshoot jaringan tanpa perlu support

**Status:** CONFIRMED

---

**Feature 17: Emergency Access via BLE**

**Tujuan:** Memastikan user dapat mengakses perangkat saat internet tidak tersedia

**Deskripsi:**
- Ketika internet tidak tersedia, aplikasi dapat tetap berkomunikasi dengan perangkat via BLE
- User dapat melihat status perangkat secara real-time melalui BLE connection
- Ini adalah jalur fallback pertama untuk komunikasi darurat
- **Detail:** Perangkat apa saja yang dapat diakses via BLE: [Semua perangkat dalam range BLE yang sudah dipair]

**User Benefit:** User dapat tetap memonitor perangkat bahkan saat internet offline

**Status:** CONFIRMED

---

**Feature 18: Emergency Access via WiFi Hotspot**

**Tujuan:** Memberikan alternatif akses ketika internet tidak tersedia dan BLE tidak available

**Deskripsi:**
- Perangkat ESP32 menyediakan WiFi Hotspot yang dapat diakses oleh perangkat mobile user
- User menghubungkan perangkat mobile ke hotspot ESP32
- Melalui hotspot, user dapat mengakses Local Web Interface (Fitur 19)
- Jalur fallback kedua untuk komunikasi darurat

**User Benefit:** User memiliki multiple fallback untuk membaca data perangkat

**Status:** CONFIRMED

---

**Feature 19: Local Web Interface Access**

**Tujuan:** Memberikan interface berbasis web untuk akses perangkat via hotspot

**Deskripsi:**
- Ketika user terhubung ke WiFi Hotspot ESP32, aplikasi menyediakan tombol/link untuk membuka Local Web Interface
- Local Web Interface diakses melalui browser pada IP/port tertentu [TBD - detail teknis]
- Melalui Local Web Interface, user dapat:
  - Melihat status perangkat real-time
  - Mengakses data monitoring
  - Mungkin trigger konfigurasi ulang [TBD]
- Ini adalah interface backup saat aplikasi mobile tidak bisa konek (e.g., emergency situation)

**User Benefit:** User memiliki multiple ways untuk access perangkat dalam situasi emergency

**Status:** CONFIRMED - Feature existence ✓ | Technical details: TBD

---

### 3.2 Feature Category Summary

| Kategori | Features | Status |
|----------|----------|--------|
| **Core User Management** | Registration, Multi-device management | ✓ Core |
| **Device Onboarding** | TGN code input, BLE discovery, WiFi config | ✓ Required |
| **Monitoring Data** | Water level, GPS, Battery, WiFi status, Connection status | ✓ Core |
| **UI Screens** | Dashboard, Device Detail, Map, History, Settings | ✓ Core |
| **Emergency Connectivity** | BLE access, Hotspot access, Local Web | ✓ Required |
| **Configuration** | WiFi reconfiguration, Network reset | ✓ Core |

---

## USER JOURNEYS

### 4.1 Happy Path: First-time User Setup

```
1. Download aplikasi TAGANA dari App Store / Play Store
2. Buka aplikasi → Lihat welcome screen / onboarding
3. Input nama user → Create profil
4. Masuk ke Dashboard (kosong, belum ada perangkat)
5. Tekan "Add Device" → Masuk ke flow registrasi
6. Input kode TGN dari label perangkat (TGN_0001)
7. Aplikasi melakukan BLE discovery
8. Aplikasi menemukan perangkat dan memverifikasi kodenya
9. Tekan "Next" → Input WiFi credential (SSID, password)
10. Aplikasi mengirim credential via BLE ke ESP32
11. ESP32 connect ke WiFi dan send data ke backend
12. Perangkat berhasil terregistrasi ✓
13. Aplikasi menampilkan perangkat di Dashboard
14. User dapat melihat status air terkini
```

**Duration:** ~5-10 menit  
**Success Criteria:** User dapat melihat data water level real-time di dashboard

---

### 4.2 User Journey: Multi-Device Management

```
1. User sudah punya 1 perangkat terregistrasi (TGN_0001)
2. User perlu menambah monitoring di lokasi baru → Add Device kedua (TGN_0002)
3. Ulangi flow yang sama seperti setup pertama (input code, BLE discovery, WiFi config)
4. Kedua perangkat sekarang terlihat di Dashboard
5. User dapat tap salah satu untuk melihat detail
6. User dapat lihat kedua perangkat di Map view
7. User dapat compare history dari kedua perangkat
```

**Duration:** Second setup lebih cepat (~3-5 menit)  
**Success Criteria:** User dapat manage multiple perangkat dari satu aplikasi

---

### 4.3 User Journey: Emergency Offline Access

```
Scenario: Internet down, user perlu check status air
1. User buka aplikasi TAGANA
2. Aplikasi detect internet tidak tersedia (no backend connection)
3. Aplikasi tampil "offline mode" indicator
4. User dapat tap "Emergency Access" → Trigger BLE connection
5. Aplikasi connect langsung ke perangkat via Bluetooth
6. User dapat melihat status air terkini via BLE ✓
   OR
7. User dapat tap "Use Hotspot Access" → Instruksi connect ke hotspot ESP32
8. User buka WiFi settings, connect ke "TAGANA_XXXX" hotspot
9. Buka aplikasi lagi atau browser → Lihat Local Web Interface
10. User dapat see status air ✓
11. Setelah internet restore → Data sync ke backend ✓
```

**Duration:** ~2-3 menit (depending on method)  
**Success Criteria:** User dapat access data bahkan saat internet offline

---

### 4.4 User Journey: Troubleshooting Network

```
Scenario: Perangkat offline karena WiFi error, user perlu reset
1. User lihat di Dashboard → TGN_0001 showing "OFFLINE"
2. User tap perangkat → Go to Device Detail
3. User tap "Network Reset" button
4. Aplikasi menampilkan confirmation warning
5. User confirm → Trigger reset via BLE
6. Perangkat ESPdone reset → Hotspot "TAGANA_XXXX" available
7. Aplikasi menampilkan "WiFi Reconfiguration Required"
8. User input WiFi credential baru (atau sama, SSID & password)
9. Kirim via BLE ke ESP32
10. ESP32 connect ke WiFi sukses
11. Perangkat back online ✓
12. Ownership & data history PRESERVED ✓
```

**Duration:** ~3-5 menit  
**Success Criteria:** Perangkat kembali online tanpa perlu re-register

---

## USER STORIES

### 5.1 User Story Format

```
As a <type of user>
I want to <perform action>
So that <benefit / goal>

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
- ...

Edge Cases:
- Case A
- Case B
- ...
```

### 5.2 User Stories by Feature

#### US-001: User Registration

```
As a new user
I want to create a profile with just my name
So that I can start using TAGANA quickly without setup overhead

Acceptance Criteria:
- [ ] User dapat input nama saat first-time launch
- [ ] Nama disimpan di backend untuk future identification
- [ ] User dapat melihat nama mereka di halaman Settings
- [ ] Tidak ada validasi email/password di versi ini
- [ ] User can proceed ke Dashboard setelah create profile

Edge Cases:
- Empty name input → Show error "Nama tidak boleh kosong"
- Very long name (>100 chars) → Truncate atau limit input field
- Unicode characters (Chinese, Arabic, etc.) → Display correctly
- Recovery identity setelah re-install: [TBD - OQ-001]
```

#### US-002: Device Registration with TGN Code

```
As a field monitor
I want to register a new TAGANA device using its TGN code
So that I can start monitoring water level from this location

Acceptance Criteria:
- [ ] User dapat input TGN code (format TGN_XXXX)
- [ ] Validasi format kode (must be TGN_XXXX where XXXX is 4 digits)
- [ ] System prevent duplicate registration (same device cannot register twice)
- [ ] After input, UI show "Searching for device..." during BLE discovery
- [ ] User see success message setelah device verification OK
- [ ] Device ownership stored di backend, not just local storage

Edge Cases:
- Kode salah format (e.g., "TGN_1" atau "TAG_0001") → Show "Invalid format"
- Device sudah terdaftar ke akun lain → [TBD - OQ-015 tentang ownership rules]
- Device code tidak ditemukan (invalid / sudah di-delete) → Show "Device not found"
- BLE device tidak respond dalam timeout → Show "Device not found, please try again"
```

#### US-003: BLE Device Discovery & Verification

```
As an installer
I want the app to verify that I'm registering the correct physical device
So that I don't accidentally register wrong device or someone else's device

Acceptance Criteria:
- [ ] Aplikasi perform BLE scan setelah user input code
- [ ] Found device must broadcast its TGN code via BLE
- [ ] Aplikasi verify que found device code matches input code
- [ ] Jika match → show "Device verified" ✓
- [ ] Jika tidak match → show "Device verification failed, please check TGN code"
- [ ] User cannot proceed sampai verification OK

Edge Cases:
- Multiple devices dengan kode sama → [Should not happen per CON-005, but handle gracefully]
- BLE pairing fails → Show "Connection failed, please try again"
- Device out of range (>few meters) → Show "Device not found, please move closer"
- BLE security/encryption: [TBD - OQ-007]
```

#### US-004: WiFi Configuration via BLE

```
As a setup technician
I want to configure the device's WiFi connection via the app
So that the device can connect to internet without manual setup

Acceptance Criteria:
- [ ] User dapat input SSID (network name)
- [ ] User dapat input Password untuk WiFi
- [ ] Aplikasi show list of available WiFi networks untuk convenience [TBD]
- [ ] Credential dikirim ke ESP32 via BLE securely
- [ ] ESP32 attempt connect ke WiFi
- [ ] Aplikasi show status "Connecting..." dan wait untuk result
- [ ] Jika success → "Device connected to WiFi ✓"
- [ ] Jika fail → "Failed to connect, check password and try again"

Edge Cases:
- WiFi password salah → Show "Authentication failed"
- Network tidak tersedia (typo SSID) → Show "Network not found"
- Device terlalu jauh dari AP → Show "Signal weak, move closer"
- BLE transmission credential security: [TBD - OQ-007]
- WiFi credential length/special chars handling → Support standard WiFi specs
```

#### US-005: Multi-Device Management

```
As a regional monitor
I want to manage monitoring perangkat di multiple locations
So that I dapat check semua lokasi dari satu aplikasi

Acceptance Criteria:
- [ ] User dapat add unlimited number of devices [Atau limit: TBD - OQ-008]
- [ ] Setiap device show dengan unique TGN code untuk easy identification
- [ ] User dapat tap device untuk go to detail screen
- [ ] User dapat delete atau remove device dari akun mereka
- [ ] Setiap device independent — change satu tidak affect yang lain
- [ ] Ownership strictly per-user — cannot see devices dari user lain

Edge Cases:
- Device limit reached [If limit exist per OQ-008] → Show "Max devices reached"
- Delete device → Show confirmation warning
- Transfer device ke user lain → [TBD - OQ-015 tentang ownership transfer]
- Shared device (multiple users) → [TBD - OQ-015]
```

#### US-006: Dashboard — Real-time Status Overview

```
As a field monitor
I want to see at-a-glance overview of all my devices' status
So that I dapat quickly check apakah semua normal atau ada masalah

Acceptance Criteria:
- [ ] Dashboard show Total Devices count
- [ ] Dashboard show Online Devices count (currently connected)
- [ ] Dashboard show Offline Devices count (not connected)
- [ ] Show last update timestamp
- [ ] User dapat tap device untuk go to detail
- [ ] Data refresh automatically sesuai interval [TBD - OQ-014]
- [ ] Dashboard hanya show devices owned by logged-in user
- [ ] Smooth transitions saat data refresh

Edge Cases:
- No devices registered yet → Show "No devices" message dengan "Add Device" button
- All devices offline → Show warning indicator
- Mixed online/offline devices → Show both status
- Data refresh failed → Show "Sync error, will try again" dengan retry button
```

#### US-007: Device Detail — Comprehensive Monitoring

```
As a field monitor
I want to see complete information about one perangkat
So that I understand current status dan historical trend

Acceptance Criteria:
- [ ] Show Device Code (TGN_XXXX) clearly at top
- [ ] Show Water Level dengan unit yang jelas [Unit TBD - OQ-002]
- [ ] Show GPS/Location untuk reference lokasi [Format TBD - OQ-012]
- [ ] Show Battery Status (%, charging status)
- [ ] Show WiFi Status (connected/disconnected, signal strength)
- [ ] Show Connection Status (Online/Offline)
- [ ] Show Last Update timestamp
- [ ] Data refresh automatically per interval [Frequency TBD - OQ-014]
- [ ] User dapat navigate ke Map atau History dari screen ini
- [ ] User dapat trigger Network Reset dari screen ini

Edge Cases:
- Device offline (no recent data) → Show "No recent data"
- Battery critical → Show warning indicator [Threshold TBD - OQ-016]
- GPS unavailable → Show "Location unavailable" [TBD - OQ-012]
- WiFi disconnected → Show "WiFi unavailable" indicator
```

#### US-008: Water Level Monitoring

```
As an operator
I want to monitor the water level reading in real-time
So that I dapat make timely decisions based on current water condition

Acceptance Criteria:
- [ ] Water level displayed prominently at Device Detail
- [ ] Show dengan unit yang benar [Unit TBD - OQ-002]
- [ ] Show historical trend di History screen
- [ ] Alert notifikasi jika level exceed threshold [Threshold TBD - OQ-011]
- [ ] Accept precision/accuracy dari sensor [OQ-002]

Edge Cases:
- Sensor error atau data invalid → Show "Data unavailable"
- Extreme values → Handle gracefully per sensor spec [TBD - OQ-002]
- Alert threshold exceeded → Show notification [Mechanism TBD - OQ-011]
```

#### US-009: Location / GPS Tracking

```
As a manager
I want to know where each monitoring device is physically located
So that I dapat coordinate response dan understand geographical coverage

Acceptance Criteria:
- [ ] GPS/Location show at Device Detail
- [ ] Location display di correct format [Format TBD - OQ-012]
- [ ] Location pin show on Map screen
- [ ] User dapat tap pin untuk see device details
- [ ] Accuracy appropriate per sensor capability [OQ-012]

Edge Cases:
- GPS unavailable / no fix → Show "Location unavailable"
- Location updating infrequently → Show last known location with timestamp
- Privacy consideration → [Relevant untuk scope]
```

#### US-010: Battery Monitoring

```
As a site manager
I want to know the battery status of each device
So that I dapat plan maintenance before device dies

Acceptance Criteria:
- [ ] Battery percentage show at Device Detail
- [ ] Battery status show dengan sufficient granularity (%, charging status)
- [ ] Alert notifikasi saat battery critical [Threshold TBD - OQ-016]
- [ ] Show in trend view jika applicable

Edge Cases:
- Battery reading unavailable → Show "Battery status unknown"
- Battery stuck at same level → Note unusual behavior
- Critical battery alert → Show notification [Mechanism TBD - OQ-016]
```

#### US-011: WiFi Status Indication

```
As a troubleshooter
I want to see the WiFi connection status of each device
So that I dapat diagnose connectivity issues quickly

Acceptance Criteria:
- [ ] WiFi status show at Device Detail
- [ ] Show connected/disconnected status clearly
- [ ] Show approximate signal strength if available
- [ ] Make clear distinction antara "WiFi disconnected" vs "Device offline"

Edge Cases:
- Signal strength unavailable → Show "Connected" without strength
- Connection unstable → Show "Connected (weak signal)" warning
```

#### US-012: Map View — Geographical Visualization

```
As a supervisor
I want to see all my devices on a map
So that I dapat understand geographical distribution dan quickly locate any device

Acceptance Criteria:
- [ ] Map display semua devices owned by logged-in user
- [ ] Setiap device show sebagai pin/marker pada koordinat GPS-nya
- [ ] User dapat zoom, pan untuk explore map
- [ ] User dapat tap marker untuk see device name/status
- [ ] Color/icon indicate device status (online/offline/alert) [TBD - OQ-005]
- [ ] Load time < 3 seconds untuk normal device count
- [ ] Handle properly jika multiple devices close together [Clustering TBD - OQ-005]
- [ ] Map tidak show devices dari user lain

Edge Cases:
- No devices atau all devices without GPS → Show empty map dengan message
- Clustering (many devices close) → Group into clusters [Detail TBD - OQ-005]
- Device moved location → Marker update automatically sesuai data baru
- Map provider unavailable → Show error gracefully
- Filtering by status → [TBD - OQ-005]
```

#### US-013: History View — Trend Analysis

```
As an analyst
I want to see historical trend of water level
So that I dapat analyze patterns dan make predictions

Acceptance Criteria:
- [ ] User dapat select device untuk see history
- [ ] User dapat select time period (past 24h, 7d, 30d, custom range)
- [ ] Historical data display dalam visual format [Format TBD - OQ-004]
- [ ] Data granularity appropriate untuk selected period [TBD - OQ-004]
- [ ] Performance acceptable bahkan untuk long periods data
- [ ] Aggregation if present clear kepada user [TBD - OQ-004]
- [ ] Data export possibility [TBD - OQ-004]
- [ ] Only show history dari selected device

Edge Cases:
- No historical data untuk selected period → Show message "No data"
- Data sparse (few measurements) → Display available points clearly
- Export feature [If exist] → Support popular formats [TBD - OQ-004]
- Large data retrieval → Show loading indicator, may take time
- Retention policy enforcement [After X days, data deleted] [Policy TBD - OQ-004]
```

#### US-014: Settings Page — User Preferences

```
As a user
I want to manage my account settings dan app preferences
So that I dapat customize experience sesuai kebutuhan

Acceptance Criteria:
- [ ] User dapat lihat dan edit profile (name)
- [ ] User dapat configure notification preferences [Details TBD - OQ-017]
- [ ] User dapat see app information dan version
- [ ] User dapat logout dari akun
- [ ] User dapat remove akun (if applicable)
- [ ] Settings reliably saved dan persist after app close

Edge Cases:
- Name change to empty → Prevent dengan validation
- Notification toggles → Clearly indicate ON/OFF state
- Logout → Require confirmation
- Account deletion → Show warning "This action is irreversible"
- Recovery identity situation → [TBD - OQ-001]
```

#### US-015: WiFi Reconfiguration

```
As a technician
I want to change the WiFi network that a device connects to
So that I dapat move device ke different network atau connect to new AP

Acceptance Criteria:
- [ ] User dapat trigger WiFi reconfiguration dari Device Detail
- [ ] Flow sama dengan initial WiFi configuration (input SSID/password)
- [ ] Device keep ownership dan tidak perlu re-register [Confirmed per REC-001]
- [ ] Historical data NOT lost setelah reconfig
- [ ] Device transition smoothly dari old WiFi ke new WiFi

Edge Cases:
- WiFi configuration fail → Show error dan allow retry
- Device temporarily unreachable during reconfiguration → Handle timeout gracefully
- User cancel during reconfig → Show "Configuration cancelled"
```

#### US-016: Network Reset Functionality

```
As a troubleshooter
I want to reset the device's network configuration
So that I dapat fix network-related issues tanpa returning device

Acceptance Criteria:
- [ ] User dapat trigger Network Reset dari Device Detail
- [ ] Show confirmation dialog warning "This will reset WiFi configuration"
- [ ] After reset, ESP32 provide BLE access dan Hotspot
- [ ] After reset, user dapat reconfigure WiFi dari aplikasi
- [ ] Device ownership NOT affected by reset [Confirmed per REC-001]
- [ ] Historical monitoring data NOT deleted setelah reset [Confirmed]
- [ ] Clear status message setelah reset complete

Edge Cases:
- Reset gagal / timeout → Show "Reset failed, please try again"
- Device unreachable during reset → Handle gracefully
- User confirm reset then close app → Reset still proceed
```

#### US-017: Emergency Access via BLE

```
As an operator
I want to access device data via Bluetooth ketika internet down
So that I dapat check water level dalam emergency situation

Acceptance Criteria:
- [ ] Aplikasi detect Internet disconnect
- [ ] Show "Emergency Mode" indicator
- [ ] User dapat tap "Emergency Access" → BLE connection attempt
- [ ] Successfully connected → Show real-time data via BLE
- [ ] Display data dengan same format sebagai normal view
- [ ] Range sufficient untuk local area access [TBD]
- [ ] Fail gracefully jika BLE range exceeded atau device busy

Edge Cases:
- Bluetooth turn off on mobile → Show "Please enable Bluetooth"
- Device too far (out of BLE range ~10m) → Show "Device out of range"
- BLE no longer available → Suggest "Try WiFi Hotspot access instead"
- Multiple devices dalam range → Show list untuk user to select
```

#### US-018: Emergency Access via WiFi Hotspot

```
As an operator
I want to access device via its WiFi hotspot ketika internet dan BLE unavailable
So that I have last resort untuk check critical data

Acceptance Criteria:
- [ ] Aplikasi detect internet down
- [ ] Show "Emergency Access" button dengan option "Use WiFi Hotspot"
- [ ] Provide clear instructions: "Connect mobile to TAGANA_XXXX WiFi network"
- [ ] Aplikasi detect successful connection to device hotspot
- [ ] Show "Local Web Interface Available" dengan link/button
- [ ] User dapat open Local Web Interface di browser
- [ ] Display critical data dalam Local Web Interface [TBD what is "critical"]
- [ ] Smooth offline-to-hotspot-to-online flow

Edge Cases:
- Cannot connect to hotspot → Show troubleshooting steps
- Local Web Interface not responding → Show "Connection error"
- Mobile WiFi turn off → Show "WiFi is turn off, please enable"
- Other devices on hotspot network → Isolate connection untuk this user
```

#### US-019: Local Web Interface Access

```
As an at-site technician
I want to view device status through a local web page
So that I dapat access data tanpa depending on mobile app

Acceptance Criteria:
- [ ] Local Web Interface accessible saat connected to device hotspot
- [ ] Display real-time device status (water level, battery, etc)
- [ ] Interface loading time < 2sec untuk local network
- [ ] Interface remain responsive at low bandwidth
- [ ] Responsive design suitable untuk mobile browser
- [ ] Security appropriate untuk local-only interface [TBD - OQ-007]
- [ ] Clear indication kapan viewing local vs cloud data

Edge Cases:
- Multiple devices dengan hotspot → Address scheme clear [e.g., 192.168.4.1]
- Local Web unavailable / error → Show meaningful error message
- Local data stale → Show last update timestamp
- Advanced features unavailable in Local Web → Clearly indicate
```

---

## FUNCTIONAL PRODUCT REQUIREMENTS

### 6.1 User Data Management Requirements

#### FPR-1: User Registration & Profile Storage
- Aplikasi harus memfasilitasi user membuat profil dengan input nama
- Profil disimpan di backend Supabase
- Nama digunakan untuk mengidentifikasi user di sistem
- **Email & password belum digunakan versi ini** (recovery mechanism TBD - OQ-001)

#### FPR-2: User Identification After App Reinstall
- [OPEN - OQ-001] Sistem harus punya mekanisme agar user dapat di-identify ulang setelah reinstall
- Options: Recovery code, email, phone number, device fingerprint, atau lainnya
- **Status:** TBD — tidak ada decision yet

#### FPR-3: Multi-User Isolation
- Data setiap user harus isolated — hanya user sendiri yang bisa lihat data mereka
- Backend harus validate ownership sebelum serve data
- Return appropriate error (e.g., 403) jika unauthorized access attempt

---

### 6.2 Device Registration & Ownership Requirements

#### FPR-4: TGN Code Format & Validation
- Device code format: TGN_XXXX (contoh: TGN_0001)
- XXXX adalah 4 digit numerik (0001-9999)
- Aplikasi harus validate format sebelum submit
- TGN code printed pada label fisik perangkat

#### FPR-5: Device Uniqueness
- Tidak boleh ada dua perangkat dengan TGN code sama di seluruh sistem
- Backend enforce uniqueness di database level
- Prevent double-registration dari kode yang sama

#### FPR-6: Ownership Assignment
- Perangkat ownership stored di backend, bukan hanya local storage
- Device belongs ke user yang mendaftarkan
- Ownership tidak berubah sampai ada deliberate transfer (TBD - OQ-015)

#### FPR-7: Device Claiming Rules
- [OPEN - OQ-015] How device initially claimed oleh user:
  - First-come-first-served? 
  - Admin approval?
  - Shared ownership?
- **Status:** TBD — mempengaruhi registration flow

#### FPR-8: Multi-Device per User
- One user dapat own multiple devices
- No limit specified [Or limit TBD - OQ-008]
- Each device independent dalam monitoring

---

### 6.3 Device Communication & Connectivity Requirements

#### FPR-9: BLE Discovery & Verification
- Aplikasi perform BLE scan setelah user input device code
- Find BLE device yang communicate TGN code matching input
- Verification handshake untuk ensure correct device
- Prevent device mismatch (user registering wrong device)

#### FPR-10: BLE Security & Pairing
- [OPEN - OQ-007] Detailed security mechanism untuk BLE pairing belum diputuskan
- Options: Challenge-response, token verification, PIN, atau tanpa enkripsi ekstra
- **Status:** TBD — critical untuk security model

#### FPR-11: WiFi Configuration via BLE
- User input WiFi SSID, Password, dan mungkin security type
- Credentials transmitted ke ESP32 via BLE connection (secure TBD)
- ESP32 attempt connect ke WiFi network dengan credentials tersebut
- Aplikasi wait untuk confirmation — successful connection atau error

#### FPR-12: Normal Connectivity Path
- Normal path: Device → WiFi → Internet → Backend → App
- Device send monitoring data ke backend sesuai schedule
- App retrieve data dari backend via API/GraphQL
- Ownership validation di backend sebelum serve data per user

#### FPR-13: Emergency BLE Fallback
- Saat internet offline, app dapat connect langsung ke device via BLE
- Data transfer directly without backend intermediary
- Data format & protocol sama untuk consistency

#### FPR-14: Emergency Hotspot Fallback
- Device provide WiFi Hotspot sebagai second fallback
- Mobile device connect ke hotspot dapat access Local Web Interface
- Local Web Interface serve data tanpa internet dependency

#### FPR-15: Data Transmission Frequency
- [OPEN - OQ-014] How often does device send data ke backend?
- Options: Every minute, every 5 minutes, every hour, custom interval?
- May vary based on conditions (emergency vs normal)
- **Status:** TBD — affects bandwidth dan latency

#### FPR-16: Data Sync When Offline Then Online
- Saat device offline (no internet) tetapi ESP32 active:
  - Data continue captured locally (or buffered?)
  - Or data loss acceptable?
  - Reconnection procedure?
- **Status:** TBD - OQ-018 (offline caching strategy)

---

### 6.4 Monitoring Data Requirements

#### FPR-17: Water Level Measurement
- Sensor measurement dari water level
- Unit & accuracy TBD (OQ-002)
- Display di Dashboard, Device Detail, History, Map
- Part of primary monitoring data

#### FPR-18: GPS/Location Tracking
- Device report geographical location
- Format of location data TBD (OQ-012)
- Accuracy & frequency TBD
- Display pada Device Detail & Map screen

#### FPR-19: Battery Status
- Device report battery level (percentage atau other metric)
- Display current battery status di Device Detail
- Alert notification saat battery critical [Threshold TBD - OQ-016]

#### FPR-20: WiFi Status Reporting
- Device report WiFi connection status (connected/disconnected)
- Provide signal strength if available
- Display at Device Detail  
- Help untuk troubleshooting network

#### FPR-21: Connection Status
- System track whether device online atau offline
- Based on regular data reception pulses
- Display clearly di Dashboard & Device Detail
- Help user know real-time device availability

#### FPR-22: Last Update Timestamp
- Record timestamp kapan data terakhir received
- Display di Device Detail
- Help user understand data freshness

#### FPR-23: Historical Data Storage
- [OPEN - OQ-004] Data retention policy belum final:
  - Berapa lama data disimpan?
  - Granularitas (per detik/menit/jam)?
  - Aggregation strategy?
  - Data export capability?
- **Status:** TBD

#### FPR-24: Historical Data Analysis
- User dapat view trend data dalam period seleksi
- Support various time periods (day/week/month/custom)
- Display format appropriate untuk selected period [TBD]

#### FPR-25: Alert Thresholds
- [OPEN - OQ-011] Water level alert belum final
- [OPEN - OQ-016] Battery alert belum final
- **Status:** TBD — what triggers

, channel, recipient, customization

---

### 6.5 User Interface & Navigation Requirements

#### FPR-26: Navigation Structure
- Aplikasi have 4 main screens:
  1. Dashboard — Overview semua devices
  2. Map — Geographic visualization
  3. History — Trend analysis
  4. Settings — User & app preferences

#### FPR-27: Dashboard Screen
- Show overview status semua device milik user
- Metrics: Total devices, Online count, Offline count
- Quick access ke device detail
- Auto-refresh sesuai interval

#### FPR-28: Device Detail Screen
- Show comprehensive info untuk 1 device
- 7 primary data fields: Code, Water Level, GPS, Battery, WiFi, Status, Last Update
- Action buttons: View History, View on Map, WiFi Reconfig, Network Reset, Emergency Access

#### FPR-29: Map Screen
- Display all devices sebagai pins pada map
- Clustering untuk many devices [Detail TBD - OQ-005]
- Filtering option [TBD - OQ-005]
- Tap pin untuk see device detail

#### FPR-30: History Screen
- Show historical data trend
- Time period selection (24h, 7d, 30d, custom)
- Visual representation (chart/graph/table) [Format TBD - OQ-004]
- Data export [If applicable TBD - OQ-004]

#### FPR-31: Settings Screen
- User profile management [TBD - OQ-017]
- Notification preferences [TBD]
- App preferences [TBD]
- About / Help info [TBD]
- Logout / Account removal options [TBD]

---

### 6.6 Configuration & Emergency Requirements

#### FPR-32: Network Reset Capability
- User dapat trigger Network Reset dari Device Detail
- Reset clear WiFi configuration dari ESP32
- After reset, BLE & hotspot available untuk reconfiguration
- Ownership & historical data PERSIST after reset

#### FPR-33: WiFi Reconfiguration
- User dapat change WiFi network after initial setup
- Input new SSID & password
- Re-send via BLE ke device
- No need untuk re-register device

#### FPR-34: Emergency Access Activation
- Aplikasi detect internet unavailability
- Offer two emergency paths: BLE or Hotspot
- Clear UX untuk guide user through

#### FPR-35: Local Web Interface provisioning
- ESP32 host local web server
- Accessible saat mobile connected ke hotspot
- Display critical device info
- IP/port scheme TBD untuk access

---

## ACCEPTANCE CRITERIA

Acceptance criteria untuk PRD ini mencakup verifikasi terhadap SRS:

### AC-1: Feature Coverage
- [x] Semua 19 fitur utama tercakup dalam PRD
- [x] Setiap fitur trace back ke SRS requirement
- [x] Tidak ada requirement SRS yang terlewat

### AC-2: Open Questions Properly Flagged
- [x] Semua OQ dari SRS marked sebagai [TBD - OQ-XXX] di PRD
- [x] Tidak ada premature decision untuk open items
- [x] TBD items tidak menghalangi product definition

### AC-3: Confirmed Requirements Preserved
- [x] Semua CONFIRMED requirement dari SRS tidak diubah
- [x] Only clarifications applied where needed
- [x] Essence of requirement maintained

### AC-4: No Invention
- [x] Tidak ada requirement baru yang tidak ada di SRS
- [x] PRD adalah simplification/elaboration of SRS, not extension

### AC-5: Scope Clarity
- [x] Clear distinction antara CONFIRMED vs TBD features
- [x] Out of Scope items clearly marked
- [x] User understand what's in v1.0 vs what's future

### AC-6: User-Centric View
- [x] PRD explain WHAT & WHY, not HOW
- [x] No technical deep-dive (no architecture, API, database schema)
- [x] Language accessible untuk product stakeholder

---

## EDGE CASES & ERROR HANDLING

### EC-1: Device Registration Edge Cases

| Edge Case | Current Handling | Status |
|-----------|------------------|--------|
| Invalid TGN format (e.g., "ABC_0001") | Show validation error | CONFIRMED |
| TGN code tidak ditemukan di database | Show "Device not found" | CONFIRMED |
| Device sudah registered ke user lain | [TBD - OQ-015] | OPEN |
| Device out of BLE range | Show "Device not found, move closer" | CONFIRMED |
| BLE pairing timeout | Show "Connection timeout, please retry" | CONFIRMED |
| WiFi password salah | Show "Authentication failed" | CONFIRMED |
| Device moved to different WiFi | Support WiFi reconfiguration | CONFIRMED |

### EC-2: Emergency Access Edge Cases

| Edge Case | Handling | Status |
|-----------|----------|--------|
| Internet offline | Offer BLE + Hotspot fallback | CONFIRMED |
| Bluetooth turn off | Suggest enable Bluetooth atau use Hotspot | CONFIRMED |
| BLE out of range | Suggest Hotspot access atau move closer | CONFIRMED |
| Hotspot unavailable | Show "Both emergency methods unavailable" | CONFIRMED |
| Local web timeout | Show "Connection error" dengan manual URL input | CONFIRMED |

### EC-3: Data Monitoring Edge Cases

| Edge Case | Handling | Status |
|-----------|----------|--------|
| Sensor malfunction | Show "Data unavailable" | CONFIRMED |
| GPS no fix | Show "Location unavailable" | CONFIRMED |
| Water level extreme value | Display jika within sensor range, flag jika anomaly | CONFIRMED |
| Battery critical | Show alert notification [Details TBD - OQ-016] | CONFIRMED per OQ |
| Device offline lama | Show "Offline since [time]" indicator | CONFIRMED |
| Data sync failed | Show "Sync error, will retry" dengan retry button | CONFIRMED |

### EC-4: Multi-Device Edge Cases

| Edge Case | Handling | Status |
|-----------|----------|--------|
| User have 0 devices | Show "No devices" message dengan "Add Device" button | CONFIRMED |
| User have many devices (50+) | Map clustering, performance optimization [Detail TBD - OQ-005] | CONFIRMED per need |
| Device ownership transfer [Future] | [TBD - OQ-015] | OPEN |
| Shared device (multi-user) | [TBD - OQ-015] | OPEN |

---

## OUT OF SCOPE

Items explicitly NOT included dalam TAGANA v1.0:

### OS-1: Advanced User Management
- User roles (Admin, Supervisor, Operator) — [TBD - OQ-003]
- User permissions & access control beyond ownership
- Team collaboration features
- User audit log

### OS-2: Advanced Monitoring Features
- Predictive analytics untuk water level
- AI-based anomaly detection
- Machine learning untuk pattern discovery
- Custom alert rules

### OS-3: Integration & Connectivity
- Integration dengan third-party systems (SMS, email alerts via external service)
- MQTT atau custom protocol support
- API exposure untuk external consumers (TBD untuk future)
- Webhook support

### OS-4: Advanced Data Management
- Data export advanced features (custom formats, scheduled exports)
- Data import dari external sources
- Batch operations
- Advanced data aggregation (custom formulas)

### OS-5: Infrastructure & Deployment
- DevOps infrastructure (covered by backend team)
- Database scaling strategy
- Load balancing assumptions
- Disaster recovery specifics

### OS-6: Technical Artifacts
- User flow diagrams (defer to next phase)
- Use case diagrams
- Architecture diagrams
- Entity-relationship diagram
- Sequence diagrams
- API specification
- Database schema
- UI/UX mockups
- Wireframes

### OS-7: Platform-Specific Features
- iOS-specific features (e.g., Apple Watch support)
- Android-specific features (e.g., Wear OS)
- Progressive Web App (PWA) support
- Desktop application

### OS-8: Market/Commercial Aspects
- Pricing model
- Licensing scheme
- Commercial deployment considerations
- Vendor lock-in analysis

### OS-9: Future Enhancements (Post v1.0)
- Voice control
- AR visualization
- Advanced offline sync strategies
- Cross-device synchronization untuk user
- Social features (sharing, collaboration)
- Advanced billing & usage tracking

---

## OPEN QUESTIONS / TBD ITEMS

Bagian ini list semua TBD items dari SRS yang mempengaruhi PRD ini.

### OQ-1: User Recovery Identity After Reinstall
**Impact:** CRITICAL untuk user experience  
**Question:** Bagaimana user dapat di-identify ulang setelah app re-install?  
**Options:** Recovery code, email, phone, device fingerprint  
**Affected Features:** User Registration (FUS-001), Settings (FPR-31)  
**Dependency Chain:** Must resolve BEFORE app development

### OQ-2: Water Level Sensor Specification
**Impact:** HIGH untuk data display  
**Question:** Satuan, rentang, akurasi sensor?  
**Affected Features:** Water Level Monitoring (FPR-17, US-008)  
**Dependency Chain:** Can proceed with TBD placeholder values

### OQ-3: Admin / Operator Roles
**Impact:** MEDIUM untuk architecture  
**Question:** Apakah ada role selain End User?  
**Affected Features:** Settings (FPR-31), potential future management features  
**Dependency Chain:** Can defer to post-v1.0

### OQ-4: History Data Structure & Retention
**Impact:** HIGH untuk backend design  
**Questions:** Retention period, granularity, aggregation, export?  
**Affected Features:** History Screen (FPR-30, US-013)  
**Dependency Chain:** Must resolve BEFORE backend development

### OQ-5: Map Page Detailed Behavior
**Impact:** MEDIUM untuk UX  
**Questions:** Clustering strategy, filtering, interaction patterns?  
**Affected Features:** Map Screen (FPR-29, US-012)  
**Dependency Chain:** Can proceed with basic implementation

### OQ-6: Long-term Authentication Plan
**Impact:** CRITICAL untuk security  
**Question:** Email, OAuth, phone+OTP, atau lainnya?  
**Affected Features:** User Registration (FPR-1), Settings (FPR-31)  
**Dependency Chain:** Should resolve BEFORE version planning

### OQ-7: BLE Security & Device Verification
**Impact:** CRITICAL untuk security  
**Questions:** Encryption, challenge-response, token, PIN?  
**Affected Features:** BLE Discovery (FPR-9), BLE Comms (FPR-10), WiFi Config (FPR-11)  
**Dependency Chain:** Must resolve BEFORE firmware development

### OQ-8: Device Limit per User
**Impact:** LOW untuk v1.0  
**Question:** Apakah ada limit jumlah device per user?  
**Affected Features:** Multi-Device Management (FPR-8)  
**Dependency Chain:** Can be business rule decision later

### OQ-9: Error Handling for 19 Scenarios
**Impact:** HIGH untuk user experience  
**Details:** Error messages, recovery strategies untuk various failure modes  
**Affected Features:** All features (graceful degradation)  
**Dependency Chain:** Should be defined during Use Case phase

### OQ-10: Performance & Scalability Targets
**Impact:** MEDIUM untuk infrastructure  
**Questions:** Latency, uptime, concurrent users, device count?  
**Affected Features:** System-wide (FPR-12 through FPR-16)  
**Dependency Chain:** Backend architecture decision

### OQ-11: Water Level Alert Threshold
**Impact:** MEDIUM untuk features  
**Questions:** What threshold triggers alert? Customizable?  
**Affected Features:** Alert Thresholds (FPR-25), User Story US-008  
**Dependency Chain:** Can proceed with alert infrastructure ready

### OQ-12: GPS/Location Data Format
**Impact:** MEDIUM untuk data handling  
**Questions:** Lat/Long decimal, DMS, accuracy required?  
**Affected Features:** Location Tracking (FPR-18, US-009)  
**Dependency Chain:** Format decision before persistent storage

### OQ-13: Target Platform (Android vs iOS)
**Impact:** MEDIUM untuk development  
**Questions:** Android only, iOS only, atau both?  
**Affected Features:** All UI features  
**Dependency Chain:** Strategic decision by stakeholder

### OQ-14: Data Send Frequency
**Impact:** HIGH untuk bandwidth & UX  
**Questions:** Every minute? Every 5 minutes? Configurable?  
**Affected Features:** Monitoring (FPR-15, FPR-17-22)  
**Dependency Chain:** Affects backend & app design

### OQ-15: Device Claiming & Ownership Rules
**Impact:** CRITICAL untuk architecture  
**Questions:** How device initially claimed? Sharing? Transfer?  
**Affected Features:** Device Ownership (FPR-6,  7, 8), Multi-Device (FPR-8)  
**Dependency Chain:** Must resolve BEFORE data model design

### OQ-16: Battery Alert & Notification [NEW]
**Impact:** MEDIUM untuk features  
**Questions:** Critical threshold %, notification channel, customizable?  
**Affected Features:** Battery Monitoring (FPR-19, US-010, FPR-25)  
**Dependency Chain:** Can implement with TBD values

### OQ-17: Settings Page Features [NEW]
**Impact:** MEDIUM untuk feature scope  
**Questions:** What options in Settings? Profile edit, preferences, logout?  
**Affected Features:** Settings Screen (FPR-31, US-014)  
**Dependency Chain:** Can be iterative; minimum is logout

### OQ-18: Offline Data Caching Strategy [NEW]
**Impact:** MEDIUM untuk architecture  
**Questions:** What data cached? How sync when online? Conflict resolution?  
**Affected Features:** Emergency Access (FPR-34, US-017, US-018)  
**Dependency Chain:** Important untuk offline UX quality

---

## FEATURE TRACKING MATRIX

Tabel berikut memberikan tracking status setiap feature dan mapping ke SRS:

| Feature | Feature ID | Status | Source Requirement (SRS) | Notes |
|---------|-----------|--------|------------------------|-------|
| **User Registration** | FPR-1 | CONFIRMED | FR-001, FR-002 | Based pada user stories |
| **Recovery After Reinstall** | FPR-2 | TBD | OQ-001 | Mechanism not decided |
| **Multi-User Data Isolation** | FPR-3 | CONFIRMED | FR-010, FR-014, FR-032, SEC-001, SEC-003 | Clear ownership model |
| **Device Code Format** | FPR-4 | CONFIRMED | FR-003 | Format: TGN_XXXX (0001-9999) |
| **Device Uniqueness** | FPR-5 | CONFIRMED | FR-004, SEC-002 | Enforced at DB level |
| **Ownership Assignment** | FPR-6 | CONFIRMED | FR-005, FR-031 | Backend storage required |
| **Device Claiming Rules** | FPR-7 | TBD | OQ-015 | First-come? Admin approval? TBD |
| **Multi-Device per User** | FPR-8 | CONFIRMED | FR-006 | No limit or limit TBD (OQ-008) |
| **BLE Discovery** | FPR-9 | CONFIRMED | FR-019, FR-020, FR-021 | Requirement clear, security TBD |
| **BLE Security & Pairing** | FPR-10 | TBD | OQ-007 | Critical security mechanism OPEN |
| **WiFi Config via BLE** | FPR-11 | CONFIRMED | FR-017 | User input credential, BLE transmission |
| **Normal Connectivity** | FPR-12 | CONFIRMED | NET-001, DATA-002 | Device→WiFi→Internet→Backend→App |
| **Emergency BLE Fallback** | FPR-13 | CONFIRMED | NET-002, FR-034 | Direct BLE communication |
| **Emergency Hotspot Fallback** | FPR-14 | CONFIRMED | NET-003, FR-035 | Device hotspot access |
| **Data Send Frequency** | FPR-15 | TBD | OQ-014 | Interval not specified |
| **Offline Data Sync** | FPR-16 | TBD | OQ-018 | Caching strategy open |
| **Water Level Measurement** | FPR-17 | CONFIRMED | FR-024 | Unit & accuracy TBD (OQ-002) |
| **GPS/Location Tracking** | FPR-18 | CONFIRMED | FR-025 | Format TBD (OQ-012) |
| **Battery Status** | FPR-19 | CONFIRMED | FR-026 | Critical alert TBD (OQ-016) |
| **WiFi Status** | FPR-20 | CONFIRMED | FR-027 | Connection status indicator |
| **Connection Status** | FPR-21 | CONFIRMED | FR-028 | Online/offline indicator |
| **Last Update Timestamp** | FPR-22 | CONFIRMED | FR-029 | For data freshness |
| **Historical Data Storage** | FPR-23 | TBD | OQ-004 | Retention & granularity OPEN |
| **Historical Analysis** | FPR-24 | CONFIRMED | FR-015 | Trend viewing confirmed, format TBD |
| **Alert Thresholds** | FPR-25 | TBD | OQ-011, OQ-016 | Water level & battery thresholds OPEN |
| **Navigation Structure** | FPR-26 | CONFIRMED | FR-009 | 4 main screens defined |
| **Dashboard Screen** | FPR-27 | CONFIRMED | FR-010, FR-011, FR-012 | Overview with clear metrics |
| **Device Detail Screen** | FPR-28 | CONFIRMED | FR-013 | 7 data fields displayed |
| **Map Screen** | FPR-29 | CONFIRMED | FR-014 | Geographic visualization, detail TBD |
| **History Screen** | FPR-30 | CONFIRMED | FR-015 | Trend analysis, format TBD |
| **Settings Screen** | FPR-31 | CONFIRMED | FR-009, FR-030 | User prefs, features detail TBD (OQ-017) |
| **Network Reset** | FPR-32 | CONFIRMED | FR-022, FR-023, FR-037, FR-038 | Reset & recovery clearly defined |
| **WiFi Reconfiguration** | FPR-33 | CONFIRMED | FR-017, REC-001 | Change network capability |
| **Emergency Access Activation** | FPR-34 | CONFIRMED | FR-033, FR-034, FR-035, FR-036 | BLE + hotspot options |
| **Local Web Interface** | FPR-35 | CONFIRMED | HW-005, FR-018, FR-035, FR-036 | Local server, access via hotspot |

### Legend:
- **CONFIRMED:** Feature fully specified, ready untuk development
- **TBD:** Feature outline clear, pero some details OPEN dan perlu stakeholder decision
- **OUT OF SCOPE:** Feature tidak included dalam v1.0

---

## REVISION HISTORY

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-08-14 | Documentation Team | Initial PRD creation based pada SRS v1.0 |

---

## DOCUMENT OWNERSHIP & APPROVAL

| Role | Name | Status |
|------|------|--------|
| Product Manager | [TBD] | Pending Review |
| Project Lead | [TBD] | Pending Review |
| Engineering Lead | [TBD] | Pending Review |

---

## REFERENCES

- TAGANA System Requirements Specification (SRS) v1.0
- SRS Review Findings (REVIEW_FINDINGS.md)
- Stakeholder Summary (STAKEHOLDER_SUMMARY.md)
- Project Completion Notes (PROJECT_COMPLETION_NOTES.md)

---

**End of Product Requirements Document**

**Next Phase:** User Flow Design & Use Case Development

