# TAGANA APP — Play Store Release Checklist

Checklist persiapan publikasi aplikasi TAGANA ke Google Play Store.

---

## 1. Application Identity

- [ ] Application ID / Package Name final
- [ ] App Name final
- [ ] App Icon final
- [ ] Splash Screen final
- [ ] Version Name ditentukan
- [ ] Version Code ditentukan
- [ ] Build release berhasil tanpa error

Contoh:

```text
Application ID : id.tagana.app
Version Name   : 1.0.0
Version Code   : 1
```

> ⚠️ Application ID sebaiknya dianggap permanen setelah aplikasi dipublikasikan.

---

## 2. Application Signing & Security

- [ ] Release keystore dibuat
- [ ] Keystore disimpan dengan aman
- [ ] Backup keystore tersedia
- [ ] Password keystore terdokumentasi secara aman
- [ ] `key.properties` tidak masuk repository
- [ ] File `.jks` tidak masuk repository
- [ ] Signing configuration berhasil digunakan
- [ ] Release build berhasil dibuat

```bash
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

---

## 3. Functional Testing

### Authentication

- [ ] Register
- [ ] Login
- [ ] Logout
- [ ] Session persistence
- [ ] Error handling

### Device Management

- [ ] Device list
- [ ] Device detail
- [ ] Device status
- [ ] Device connectivity
- [ ] Device realtime update

### BLE Connectivity

- [ ] Bluetooth permission
- [ ] BLE scanning
- [ ] Device connection
- [ ] Device disconnection
- [ ] Reconnection
- [ ] BLE status indicator
- [ ] Navigation setelah koneksi BLE

### Wi-Fi Configuration

- [ ] Wi-Fi configuration
- [ ] SSID detection
- [ ] Connection status
- [ ] Cloud connectivity

### Emergency Mode

- [ ] Emergency page
- [ ] BLE connectivity status
- [ ] Internet connectivity status
- [ ] Buzzer control
- [ ] Realtime device status
- [ ] Cloud fallback ketika BLE tidak tersedia

### Map Monitoring

- [ ] Map berhasil dimuat
- [ ] Marker device tampil
- [ ] Search device
- [ ] Filter device
- [ ] Marker interaction
- [ ] Device preview
- [ ] Status device sesuai data

### Profile & Settings

- [ ] Edit profile
- [ ] Update name
- [ ] Update email
- [ ] Update phone
- [ ] Avatar upload
- [ ] Avatar preview
- [ ] Settings persistence

---

## 4. Privacy & Compliance

- [ ] Privacy Policy tersedia
- [ ] URL Privacy Policy aktif
- [ ] Data yang dikumpulkan telah diidentifikasi
- [ ] Data Safety Form diisi
- [ ] Third-party service didokumentasikan
- [ ] Permission aplikasi ditinjau
- [ ] Bluetooth permission declaration disiapkan
- [ ] Lokasi permission ditinjau
- [ ] Camera permission ditinjau
- [ ] Storage/Media permission ditinjau

---

## 5. Google Play Store Assets

### Store Listing

- [ ] App Name
- [ ] Short Description
- [ ] Full Description
- [ ] App Category
- [ ] Contact Email
- [ ] Privacy Policy URL

### Visual Assets

- [ ] App Icon
- [ ] Feature Graphic
- [ ] Phone Screenshots
- [ ] Tablet Screenshots (opsional)

Screenshot yang disarankan:

- [ ] Login
- [ ] Dashboard
- [ ] Device Monitoring
- [ ] Device Detail
- [ ] Map
- [ ] Emergency Mode
- [ ] Profile

---

## 6. Google Play Console Setup

- [ ] Google Play Developer Account dibuat
- [ ] Ownership akun menggunakan akun official organisasi
- [ ] Developer access diberikan kepada tim
- [ ] Role & permission anggota ditentukan
- [ ] Application dibuat di Play Console
- [ ] App Bundle (.aab) berhasil diupload

---

## 7. Internal Testing

Target:

```text
Developer
QA
Project Manager
Internal Team
```

Checklist:

- [ ] Internal testing track dibuat
- [ ] Tester ditambahkan
- [ ] AAB diupload
- [ ] Instalasi berhasil
- [ ] Crash monitoring dilakukan
- [ ] Critical bug diperbaiki

---

## 8. Closed Testing

Target:

```text
Beta Tester
Selected Users
Field Tester
```

Checklist:

- [ ] Closed testing track dibuat
- [ ] Tester group ditentukan
- [ ] Feedback dikumpulkan
- [ ] Critical issue diperbaiki
- [ ] Release candidate dibuat

---

## 9. Production Release

- [ ] Final AAB dibuat
- [ ] Version Code ditingkatkan
- [ ] Release Notes dibuat
- [ ] Data Safety diverifikasi
- [ ] Privacy Policy diverifikasi
- [ ] Store Listing lengkap
- [ ] Production release dibuat
- [ ] Submit for review
- [ ] Google review completed
- [ ] Application published

---

# Release Flow

```text
Development
     │
     ▼
Release Build
     │
     ▼
Internal Testing
     │
     ▼
Bug Fixing
     │
     ▼
Closed Testing
     │
     ▼
Release Candidate
     │
     ▼
Production Review
     │
     ▼
Google Play Store 🚀
```

---

# Release Ownership Recommendation

```text
Official Organization Account
            │
            ▼
Google Play Console
            │
     ┌──────┴──────┐
     │             │
 Administrator   Developer
     │             │
 Project Owner   Development Team
```

> Google Play Console dan aplikasi production sebaiknya dimiliki oleh akun resmi organisasi atau project owner, bukan akun pribadi developer.

---

# Final Go / No-Go Checklist

Sebelum menekan tombol **Submit for Review**:

- [ ] Tidak ada critical bug
- [ ] Release build berhasil
- [ ] AAB sudah diuji
- [ ] Application signing aman
- [ ] Privacy Policy aktif
- [ ] Data Safety sesuai implementasi aplikasi
- [ ] Permission sudah diverifikasi
- [ ] Screenshot tersedia
- [ ] Store listing lengkap
- [ ] Testing selesai
- [ ] Ownership & akses tim sudah jelas

## Status Release

```text
☐ NOT READY
☐ READY FOR TESTING
☐ READY FOR PRODUCTION
☐ PUBLISHED
```