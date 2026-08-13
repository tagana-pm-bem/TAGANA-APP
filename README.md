# TAGANA App

Aplikasi mobile untuk monitoring dan pengelolaan perangkat TAGANA berbasis ESP32.

TAGANA App dikembangkan menggunakan Flutter dan digunakan untuk menghubungkan, memonitor, serta mengelola perangkat TAGANA yang terdaftar pada pengguna.

## Overview

TAGANA merupakan sistem monitoring perangkat lapangan yang terhubung dengan aplikasi mobile melalui beberapa mekanisme konektivitas.

Aplikasi mendukung:

- Registrasi perangkat menggunakan kode perangkat `TGN_XXXX`
- Verifikasi perangkat melalui Bluetooth Low Energy (BLE)
- Monitoring ketinggian air
- Monitoring lokasi melalui GPS
- Monitoring status baterai
- Monitoring koneksi WiFi
- Monitoring status koneksi perangkat
- Pengelolaan beberapa perangkat dalam satu aplikasi
- Riwayat data perangkat
- Tampilan lokasi perangkat pada peta
- Konfigurasi jaringan perangkat
- Network reset
- Emergency connectivity melalui BLE
- Emergency access melalui WiFi Hotspot dan Local Web Interface

## Tech Stack

### Mobile

- Flutter
- Dart
- Riverpod
- GoRouter
- GraphQL
- Flutter SVG
- Google Fonts
- Lucide Icons

### Backend & Data

- Hasura
- Supabase
- GraphQL

### Hardware

- ESP32
- Water Level Sensor
- GPS
- Battery Monitoring
- WiFi
- Bluetooth Low Energy (BLE)

## Architecture

Secara umum, aplikasi berkomunikasi dengan perangkat TAGANA melalui beberapa jalur konektivitas.

### Normal Connectivity

```text
ESP32
  │
  │ WiFi
  ▼
Internet
  │
  ▼
Backend
  │
  ▼
Flutter App
```

### Emergency Connectivity — BLE

```text
ESP32
  │
  │ Bluetooth Low Energy
  ▼
Flutter App
```

### Emergency Connectivity — Local Web

```text
ESP32
  │
  │ WiFi Hotspot
  ▼
Mobile Device
  │
  │ Browser
  ▼
Local Web Interface
```

BLE digunakan sebagai jalur komunikasi langsung dengan aplikasi, sedangkan WiFi Hotspot digunakan sebagai jalur akses ke Local Web Interface ketika koneksi internet tidak tersedia.

## Project Structure

```text
TAGANA-APP/
│
├── android/
├── ios/
│
├── assets/
│   ├── images/
│   └── icons/
│
├── docs/
│
├── lib/
│   ├── app/
│   ├── core/
│   └── features/
│
├── test/
├── integration_test/
│
├── .env.example
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml
└── README.md
```

## Main Features

### Device Management

Pengguna dapat mengelola perangkat TAGANA yang dimilikinya.

Setiap perangkat diidentifikasi menggunakan kode perangkat seperti:

```text
TGN_XXXX
```

Satu aplikasi dapat digunakan untuk memonitor beberapa perangkat yang telah terdaftar pada pengguna.

### Device Verification

Perangkat diverifikasi melalui BLE sebelum ditambahkan ke aplikasi.

```text
Input TGN Code
      ↓
BLE Discovery
      ↓
Device Verification
      ↓
WiFi Configuration
      ↓
Device Registered
```

### Monitoring

Aplikasi menyediakan informasi monitoring perangkat, meliputi:

- Water level
- GPS / Location
- Battery
- WiFi status
- Connection status
- Last update

### Emergency Connectivity

Ketika koneksi internet tidak tersedia, perangkat menyediakan jalur komunikasi alternatif.

#### BLE

Digunakan untuk komunikasi langsung antara ESP32 dan aplikasi Flutter.

#### WiFi Hotspot

ESP32 dapat menyediakan WiFi Hotspot yang memungkinkan perangkat mobile terhubung secara langsung.

Setelah terhubung, pengguna dapat mengakses Local Web Interface melalui browser.

## Development Setup

### Requirements

Pastikan environment berikut sudah tersedia:

- Flutter SDK
- Dart SDK
- Android Studio atau Android SDK
- VS Code atau IDE lainnya
- Git

Cek Flutter environment:

```bash
flutter doctor
```

### Clone Repository

```bash
git clone https://github.com/tagana-pm-bem/TAGANA-APP.git
cd TAGANA-APP
```

### Install Dependencies

```bash
flutter pub get
```

### Run Application

```bash
flutter run
```

### Run Tests

```bash
flutter test
```

### Analyze Code

```bash
flutter analyze
```

## Environment Configuration

Konfigurasi environment tidak disimpan langsung di repository.

Buat file:

```text
.env
```

berdasarkan:

```text
.env.example
```

Contoh:

```env
HASURA_ENDPOINT=
```

> Jangan commit file `.env` atau credential/secret ke repository.

## Versioning

Aplikasi menggunakan format:

```text
MAJOR.MINOR.PATCH+BUILD
```

Contoh:

```text
1.0.0+1
```

Keterangan:

- **MAJOR** — perubahan besar atau breaking changes
- **MINOR** — penambahan fitur
- **PATCH** — perbaikan bug
- **BUILD** — nomor build aplikasi

Contoh:

```text
1.0.0+1   → Initial release
1.0.1+2   → Bug fix
1.1.0+3   → Feature update
2.0.0+10  → Major release
```

## Documentation

Dokumentasi teknis yang diperlukan dalam pengembangan aplikasi tersedia pada folder:

```text
docs/
```

Dokumen utama yang akan digunakan meliputi:

- System Requirements
- Product Requirements
- BLE Protocol
- API Specification
- Emergency Connectivity Specification

Dokumentasi lengkap produk dan hasil pembahasan stakeholder dapat dikelola pada repository dokumentasi terpisah.

## Development Guidelines

Beberapa prinsip pengembangan yang digunakan:

- Gunakan pendekatan **feature-first**
- Pisahkan UI, state management, repository, dan service
- Hindari business logic di dalam widget
- Jangan menyimpan credential atau secret di source code
- Gunakan environment configuration untuk konfigurasi yang diperlukan
- Buat unit test untuk business logic penting
- Buat integration test untuk flow utama
- Dokumentasikan perubahan pada protokol BLE dan API
- Jangan menambahkan dependency tanpa kebutuhan yang jelas

## Project Status

> **In Development**

Aplikasi TAGANA masih dalam tahap pengembangan. Beberapa fitur dan spesifikasi teknis masih dapat berubah berdasarkan hasil pembahasan dengan stakeholder dan tim hardware.

## License

This project is maintained by the TAGANA development team.