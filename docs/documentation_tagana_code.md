# Dokumentasi Analisis Sistem & Kode Firmware: TAGANA Sensor (ESP32)

Dokumen ini berisi analisis teknis, penjabaran algoritma, dan arsitektur dari kode firmware `tagana-code.ino` yang didesain untuk perangkat **Tas Siaga TAGANA**. Firmware ini dirancang agar kuat (robust), hemat sumber daya, dan tetap dapat diandalkan baik dalam kondisi *online* maupun **sepenuhnya *offline***.

---

## 1. Arsitektur & Teknologi Utama

Sistem ini menggabungkan berbagai teknologi *embedded* kelas profesional untuk memastikan stabilitas:

| Teknologi | Deskripsi & Implementasi di Sistem |
| :--- | :--- |
| **Dual-Core Processing** | Memanfaatkan prosesor ESP32 secara maksimal. Jaringan dan web server diurus oleh **Core 0**, sedangkan pembacaan sensor dan alarm fisik murni diurus oleh **Core 1**. |
| **FreeRTOS** | Sistem Operasi Waktu-Nyata. Menghilangkan penggunaan `delay()` konvensional yang dapat membekukan sistem (*blocking*). Fungsi `loop()` bawaan bahkan dimatikan untuk efisiensi. |
| **Hybrid Network** | Menggabungkan Wi-Fi (Mode Station & Access Point) dengan Bluetooth Low Energy (BLE) secara bersamaan. |
| **mDNS (Multicast DNS)** | Memungkinkan akses dashboard lokal tanpa perlu mengetik alamat IP yang sulit dihafal. Cukup ketik **`http://tagana.local`** di browser. |
| **Captive Portal** | Memungkinkan pengguna memasukkan nama WiFi dan Password baru melalui antarmuka web, tanpa perlu memprogram ulang (hardcode) ESP32. |

---

## 2. Pemetaan Pin (Hardware Pinout)

Berikut adalah tabel alokasi pin yang dikonfigurasikan pada kode sumber:

| Komponen Hardware | Pin ESP32 | Tipe | Deskripsi (Kegunaan) |
| :--- | :---: | :---: | :--- |
| **Sensor Ketinggian Air** | `34` | Input Analog | Membaca resistansi air (nilai raw ADC 0 - 4095). Threshold banjir di set pada nilai `300`. |
| **Sensor Voltase Baterai** | `33` | Input Analog | Membaca kapasitas sisa daya. (Rentang ADC: 1660 untuk kosong, 2183 untuk penuh). |
| **Buzzer (Alarm Fisik)** | `4` | Output Digital | Membunyikan alarm peringatan banjir dan fitur pencarian (*Locator*). |
| **LED Indikator** | `12` | Output Digital | (Disiapkan pada kode awal) Pin untuk lampu LED hijau opsional. |
| **Modul GPS (TX)** | `16` | UART2 (RX) | Menerima data NMEA dari modul GPS (kabel TX dari modul GPS masuk ke pin 16). |
| **Modul GPS (RX)** | `17` | UART2 (TX) | Mengirim data ke modul GPS (tidak banyak dipakai dalam mode pasif). |

---

## 3. Pustaka (Library) yang Digunakan

Kode ini bergantung pada *library* berikut. Beberapa merupakan bawaan (*built-in*) ESP32 ESP-IDF, dan beberapa lainnya eksternal:

| Nama Library | Kegunaan Spesifik pada Kode |
| :--- | :--- |
| `WiFi.h` | Modul inti koneksi Wi-Fi (menyambungkan ke internet & membuat hotspot). |
| `BLEDevice.h` dkk. | Rangkaian pustaka pengontrol Bluetooth Low Energy (BLE Server & Characteristics). |
| `WiFiManager.h` | Membuat *Captive Portal* cerdas untuk konfigurasi WiFi pertama kali. |
| `WebServer.h` | Menjalankan *Web Server* HTTP asinkron mandiri di port 80. |
| `ESPmDNS.h` | Mendaftarkan domain DNS lokal (`tagana.local`) ke dalam jaringan router. |
| `HTTPClient.h` & `WiFiClientSecure.h` | Membuat jembatan (REST API Client) untuk mengirim data aman (HTTPS) ke *backend* server. |
| `time.h` | Menangani standar kalender ISO dan sinkronisasi zona waktu dunia via NTP server. |
| `TinyGPS++.h` | *Parser* cerdas yang mengekstrak koordinat bujur/lintang (Lat/Lng) dari data teks acak NMEA milik modul GPS. |

---

## 4. Penjelasan Algoritma & Cara Kerja Sistem

Di bawah ini adalah penjelasan blok per blok dari algoritma yang menyokong ketangguhan sistem Tagana.

### A. Multitasking Bebas Hambatan (FreeRTOS Core Split)

Pada Arduino standar, jika perangkat sedang mencari koneksi Wi-Fi, eksekusi kode akan berhenti (*stuck*) dan sensor tidak akan bisa dibaca. Sistem Tagana menyelesaikan ini dengan **FreeRTOS**.

```cpp
// Dijalankan di void setup()
// Memulai Task Sensor & Alarm di CORE 1
xTaskCreatePinnedToCore(TaskSensorAlarm, "TaskSensor", 4096, NULL, 2, NULL, 1);

// Memulai Task Jaringan di CORE 0
xTaskCreatePinnedToCore(TaskNetwork, "TaskNetwork", 8192, NULL, 1, NULL, 0);

void loop() {
  vTaskDelete(NULL); // Hentikan loop bawaan Arduino untuk hemat resource
}
```
**Algoritma:** 
Begitu alat menyala, Core 1 langsung ditugaskan membaca air dan baterai tiada henti. Jika saat booting tas sudah terendam air, alarm buzzer akan *langsung bunyi* detik itu juga, terlepas apakah Wi-Fi berhasil konek atau belum. Proses berat seperti WiFi dan pengiriman HTTP dibuang sepenuhnya ke Core 0.

### B. Mode Akses Offline Jaringan Lokal (Fallback AP & mDNS)

Jika tidak ada sinyal internet, sistem tidak akan mati. Perangkat akan membuat hotspot-nya sendiri yang bisa diakses via browser HP.

**1. Logika Fallback Access Point:**
```cpp
// Di dalam TaskNetwork (Core 0)
if (disconnectStartTime >= 10000) { // Jika putus lebih dari 10 detik
  WiFi.mode(WIFI_AP_STA);           // Buka mode Hotspot + Station
  WiFi.softAP("Tagana-AP");         // Nama WiFi yang dipancarkan
  beep(1, 1000);                    // Bunyi 1 detik sbg penanda ke pengguna
  isFallbackAP = true;
}
```

**2. Resolusi mDNS (Domain Lokal):**
```cpp
// Di dalam setup()
if (MDNS.begin("tagana")) {
  MDNS.addService("http", "tcp", 80);
}
```
**Algoritma:**
*   Pengguna menyambungkan WiFi HP ke `Tagana-AP`.
*   Tidak perlu mengetik `192.168.4.1`, pengguna cukup mengetik `http://tagana.local` di Chrome/Safari.
*   ESP32 akan langsung memuat UI Tactical Telemetry berbasis HTML/CSS lokal dari memori *Flash*. Halaman web akan terus-menerus mengambil data sensor terbaru via endpoint `/data` setiap 1 detik menggunakan `fetch()` Javascript.

### C. Mode Akses Offline Jarak Dekat (Bluetooth Low Energy)

Sebagai jaring pengaman ketiga (khusus Android APK), alat bisa diremot murni lewat Bluetooth, tanpa routing IP sama sekali.

```cpp
// Mengirim data Telemetry ke aplikasi Android (di dalam TaskNetwork)
if (deviceConnected) {
  String json = "{... data sensor ...}";
  pTxCharacteristic->setValue(json.c_str());
  pTxCharacteristic->notify(); // Kirim ke aplikasi HP setiap 100ms
}
```
**Algoritma Parsing Command dari APK:**
```cpp
// Saat alat menerima pesan (write) dari Aplikasi Android
void onWrite(BLECharacteristic *pCharacteristic) {
  String cmd = pCharacteristic->getValue();
  if (cmd == "BUZZER") {
    manualBuzzer = !manualBuzzer; // Menyalakan/mematikan alarm pencari tas
  } else if (cmd.startsWith("WIFI:")) {
    // Memotong string untuk ganti WiFi. Format: "WIFI:NamaWifi:Password"
    String ssid = cmd.substring(...); 
    String pass = cmd.substring(...);
    WiFi.begin(ssid.c_str(), pass.c_str());
  }
}
```

### D. Mode Online: Algoritma Pengiriman Cloud (Backend Hasura)

Saat internet tersedia, data diekstrak ke Cloud Hasura menggunakan metode POST REST API.
Terdapat algoritma cerdas yang membedakan **Interval Waktu** berdasarkan kondisi krisis.

```cpp
// Di dalam TaskNetwork
if (currentFlood) {
    // Mode Darurat: Kirim data SETIAP 3 DETIK (3000 ms)
    if (currentTaskTime - lastSendTime >= 3000) {
        sendToHasura(true);
        lastSendTime = millis();
    }
} else {
    // Mode Normal: Kirim data SETIAP 30 MENIT (1800000 ms) untuk hemat kuota
    if (currentTaskTime - lastNormalSendTime >= 1800000) {
        sendToHasura(false);
        lastNormalSendTime = millis();
    }
}
```
**Payload JSON Hasura:**
Data dibungkus dengan kredensial rahasia pada *header* HTTP:
```json
{
  "object": {
    "bag_id": "TGN_001",
    "water_level": 500,
    "is_flood_detected": true,
    "recorded_at": "2026-08-20T10:30:00Z",
    "latitude": -6.123456,
    "longitude": 106.123456
  }
}
```

### E. Algoritma Akurasi Koordinat GPS (Validasi Satelit)

GPS memancarkan sinyal serial NMEA (seperti `$GPGGA,123519,4807.038,N...`). Kode harus mengekstrak ini secara aman tanpa salah baca.

```cpp
// Di dalam TaskSensorAlarm (Berputar tiap 50ms)
while (GPSSerial.available()) {
  // 1. encode(): Masukkan karakter serial satu per satu ke mesin TinyGPS
  // 2. isValid(): PASTIKAN satelit sudah "Lock" (minimal 3-4 satelit terhubung)
  if (gps.encode(GPSSerial.read()) && gps.location.isValid()) {
    gpsLat = gps.location.lat(); // Simpan Lintang presisi ganda (Double)
    gpsLng = gps.location.lng(); // Simpan Bujur presisi ganda (Double)
    gpsValid = true;             // Tandai bendera bahwa data bisa dipercaya
  }
}
```
*Mengapa akurat?* Karena kita menggunakan `HardwareSerial(2)`. Pembacaan UART dilakukan langsung oleh chip *hardware* pendukung ESP32, bukan oleh CPU (*SoftwareSerial*). Ini mencegah teks GPS terpotong atau *corrupt* akibat CPU sibuk.

### F. Algoritma Filter Penstabil Baterai (Exponential Moving Average)

Sinyal tegangan baterai (ADC) sering bergoyang (naik turun secara fluktuatif) akibat aktivitas WiFi/GPS. Agar UI persentase baterai tidak melompat-lompat (contoh: 80% tiba-tiba ke 75% lalu balik ke 81%), diterapkan rumus matematika EMA:

```cpp
// Smoothing berat: 99% data masa lalu + 1% data asli terbaru
emaBat = (0.01 * currentBatRaw) + (0.99 * emaBat);
batteryRaw = (int)emaBat;
```
Karena ini diputar di dalam *loop* 50ms, data baterai akan menjadi sangat halus dan stabil di antarmuka web, merepresentasikan kapasitas sesungguhnya dengan sangat baik tanpa harus memanggil `delay()`.

### G. Algoritma Alarm Dinamis (Intensitas Mengikuti Banjir)

Untuk memberikan nuansa krisis, bunyi alarm (*Buzzer*) tidak berkedip datar/statis.

```cpp
// Semakin tinggi level air (max 1900), makin cepat bunyi beep (hingga 40ms)
currentDelay = map(waterLevelRaw, FLOOD_THRESHOLD, 1900, 300, 40);
currentDelay = constrain(currentDelay, 40, 300);

if (currentMillis - lastAlarmTime >= currentDelay) {
  lastAlarmTime = currentMillis;
  alarmActive = !alarmActive;
  digitalWrite(BUZZER_PIN, alarmActive ? HIGH : LOW);
}
```
Jika air masih di angka threshold (`300`), buzzer berbunyi santai tiap `300ms`. Jika alat tenggelam total (nilai > `1500`), buzzer akan berteriak sangat panik (berbunyi nyaring tiap `40ms`).