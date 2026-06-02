# GoPay Workflow Orchestrator

[![GitHub](https://img.shields.io/badge/GitHub-Gopay__plus__automatic-blue?logo=github)](https://github.com/ywnd1144/Gopay_plus_automatic)
[![Stars](https://img.shields.io/github/stars/ywnd1144/Gopay_plus_automatic?style=social)](https://github.com/ywnd1144/Gopay_plus_automatic)

> URL Proyek: <https://github.com/ywnd1144/Gopay_plus_automatic>

Sebuah kerangka kerja orkestrasi alur kerja ringan yang berorientasi pada tautan pembayaran regional, digunakan untuk meneliti dan melakukan proses *debug* pada skenario seperti perpindahan penyedia pembayaran multi-tahap, permintaan tokenisasi, tantangan verifikasi, *polling* asinkron, dan konfirmasi status akhir.

Proyek ini berfokus pada keandalan rekayasa (*engineering reliability*), integrasi antarmuka, observabilitas status, dan pengujian otomatis dalam alur kerja pembayaran yang kompleks. Proyek ini mengorganisir langkah-langkah yang tersebar di berbagai sistem menjadi sebuah proses yang dapat direproduksi, diobservasi, dan diperluas, sehingga memudahkan pengembang untuk menganalisis perilaku tautan, menemukan status yang tidak normal, dan meningkatkan kualitas integrasi.

---

## Posisi Proyek

Dalam bisnis dunia nyata, alur pembayaran yang lengkap biasanya tidak selesai hanya dengan satu permintaan. Proses tersebut mungkin melibatkan:

- Status sesi di sisi aplikasi
- Inisialisasi *payment gateway*
- Perpindahan (*handoff*) dompet eksternal atau penyedia pembayaran regional
- Permintaan dan konfirmasi tokenisasi
- OTP, PIN, atau tantangan verifikasi lainnya
- *Callback* asinkron dan *polling* status
- Validasi hasil akhir

Proyek ini menyediakan lapisan orkestrasi alur kerja berukuran kecil yang memecah langkah-langkah di atas menjadi modul-modul yang dapat diobservasi, diganti, dan di-*debug*.

Cocok digunakan untuk:

- Pengujian integrasi tautan pembayaran
- Penelitian integrasi penyedia pembayaran regional
- Proses *debug* pada perpindahan dompet dan *callback*
- Analisis alur kerja tantangan verifikasi
- Pengujian stabilitas di bawah lingkungan proksi jaringan
- Reproduksi perilaku mesin status multi-tahap
- Pengujian regresi otomatis dan observasi log

---

## Kemampuan Inti

- Titik masuk alur kerja melalui HTTP
- Layanan alur kerja pembayaran gRPC
- Pemrosesan permintaan pembayaran tokenisasi
- Perpindahan penyedia eksternal dan pelacakan status
- Pemrosesan tantangan verifikasi OTP / PIN
- Mode verifikasi manual dan verifikasi berbantuan API
- Eksekusi berbasis konfigurasi
- Lapisan permintaan jaringan yang mendeteksi proksi
- Output log terstruktur
- *Polling* status dan konfirmasi hasil akhir
- Penerapan (Deployment) yang ramah Docker

---

## Gambaran Arsitektur

```text
Client / Test Harness
        |
        v
HTTP Orchestrator
        |
        v
Payment Workflow Engine
        |
        +--> Gateway Initialization
        |
        +--> Provider Handoff
        |
        +--> Verification Challenge
        |
        +--> Status Polling
        |
        v
Final State Validator
```

Proyek ini memisahkan logika orkestrasi alur kerja dari operasi pembayaran spesifik, sehingga memudahkan penggantian penyedia, metode verifikasi, atau lingkungan eksekusi di kemudian hari.

File-file utama:

```text
orchestrator.py       # Titik masuk alur kerja HTTP
payment_core.py       # Layanan alur kerja pembayaran gRPC
config.py             # Konfigurasi saat waktu berjalan (runtime)
main.py               # Titik masuk startup lokal
start.sh              # Skrip pembantu penerapan (deployment)
Dockerfile            # Definisi image container
requirements.txt      # Dependensi Python
```

---

## Alur Kerja

Sebuah alur kerja standar biasanya mencakup tahap-tahap berikut:

1. Menerima kredensial sesi atau token pengujian
2. Menginisialisasi alur pembayaran
3. Membuat permintaan perpindahan penyedia
4. Menunggu status verifikasi eksternal
5. Menyelesaikan tantangan OTP / PIN sesuai kebutuhan
6. Melakukan *polling* status penyedia
7. Memvalidasi hasil alur kerja akhir

Setiap tahap dapat diobservasi dan diganti secara independen, memfasilitasi proses *debug* kinerja tautan di berbagai lingkungan.

---

## Mode Verifikasi

Proyek ini mendukung berbagai metode penanganan verifikasi, sehingga dapat beradaptasi dengan berbagai lingkungan pengujian:

```text
manual      # Menyelesaikan tantangan verifikasi secara manual
sms_api     # Mengembalikan hasil verifikasi via antarmuka (API)
whatsapp    # Mengembalikan hasil verifikasi via saluran pesan (WhatsApp)
```

Logika penanganan verifikasi dienkapsulasi di balik antarmuka terpadu, memungkinkan *handler* baru ditambahkan di kemudian hari tanpa memodifikasi alur kerja utama.

---

## Instruksi Konfigurasi

Parameter untuk menjalankan dapat disediakan melalui variabel lingkungan (environment variables) atau file konfigurasi lokal.

Item konfigurasi umum:

```text
PROXY_URL          Alamat proksi jaringan
VERIFY_MODE        Mode penanganan verifikasi
POLL_INTERVAL      Interval waktu untuk polling status
REQUEST_TIMEOUT    Durasi waktu tunggu (timeout) permintaan
LOG_LEVEL          Tingkat log
```

Contoh:

```env
PROXY_URL=
VERIFY_MODE=manual
POLL_INTERVAL=3
REQUEST_TIMEOUT=30
LOG_LEVEL=INFO
```

Harap letakkan informasi sensitif pada variabel lingkungan atau alat manajemen kunci, dan jangan men-*commit*-nya ke dalam repositori.

---

## Eksekusi Lokal

Instal dependensi:

```bash
pip install -r requirements.txt
```

Mulai layanan:

```bash
python main.py
```

Atau gunakan skrip startup:

```bash
bash start.sh
```

Jalankan di container:

```bash
docker build -t gopay-workflow-orchestrator .
docker run --env-file .env gopay-workflow-orchestrator
```

---

## Contoh Permintaan

Layanan ini menyediakan antarmuka HTTP ringan untuk membuat dan melacak tugas alur kerja.

Struktur contoh permintaan:

```json
{
  "session_token": "example-session-token",
  "verification_mode": "manual",
  "proxy": "http://127.0.0.1:8080"
}
```

Struktur contoh respons:

```json
{
  "job_id": "workflow_123",
  "status": "pending",
  "next_action": "provider_verification"
}
```

Status pengembalian mungkin berbeda berdasarkan wilayah, penyedia, dan lingkungan jaringan yang berbeda. Hasil aktual bergantung pada log eksekusi dan respons dari penyedia.

---

## Pencatatan Log dan Observasi

Proyek ini merekam kejadian-kejadian (events) penting pada alur kerja untuk membantu menemukan masalah tautan:

- Inisialisasi permintaan
- Status respons gateway
- Status perpindahan penyedia
- Status tantangan verifikasi
- Hasil *polling*
- Hasil akhir alur kerja
- Status percobaan ulang (retry), *timeout*, dan pengecualian (exception)

Desain pencatatan log bertujuan untuk membantu menganalisis perubahan status tanpa mencetak kredensial sensitif.

---

## Tujuan Desain

Tujuan inti dari proyek ini adalah untuk menyediakan kerangka kerja penelitian alur pembayaran yang sederhana, dapat direproduksi, dan mudah di-*debug*.

Fokus utama meliputi:

- Mengurangi biaya *debug* dari tautan pembayaran multi-tahap
- Memecah alur kerja kompleks menjadi modul-modul yang jelas
- Meningkatkan observabilitas perpindahan penyedia dan *callback*
- Mencatat status-status tidak normal yang umum terjadi
- Mendukung eksperimen integrasi yang dapat diulang
- Membuat logika penanganan tantangan verifikasi lebih mudah dipelihara

---

## Peta Jalan (Roadmap)

- Memperbaiki lapisan abstraksi penyedia
- Menambahkan kasus pengujian (test cases) terstruktur
- Menambahkan pemeriksaan CI
- Menambahkan validasi konfigurasi bertipe (typed)
- Memperbaiki redaksi log
- Menambahkan mode putar ulang (replay) alur kerja
- Menambahkan lebih banyak contoh pengujian integrasi
- Menyempurnakan dokumentasi transisi status

---

## Kontribusi

Perbaikan dari siapa pun selalu diterima.

Area yang cocok untuk berkontribusi:

- Adaptor penyedia
- *Handler* verifikasi
- Logika percobaan ulang (retry) dan *backoff*
- Kasus pengujian (test cases)
- Peningkatan dokumentasi
- Pencatatan log dan observabilitas
- Pengalaman penerapan (deployment) container

Harap jangan men-*commit* kunci rahasia, kredensial sesi, kode verifikasi, PIN, kredensial proksi, atau data operasional privat apa pun.

---

## Instruksi Keamanan

Proyek ini mungkin melibatkan alur pembayaran, tantangan verifikasi, dan antarmuka penyedia eksternal.

Sangat direkomendasikan untuk menjalankan ini terutama di lingkungan pengujian yang terisolasi. Output dari proses *debug* harus disensor (redacted) sebelum dibagikan. Kredensial sesi, kode verifikasi, PIN, kredensial proksi, dan data pribadi penyedia harus selalu dijauhkan dari repositori.

---

## Lisensi

MIT

---

## Riwayat Bintang (Star History)

[![Star History Chart](https://api.star-history.com/svg?repos=ywnd1144/Gopay_plus_automatic&type=Date)](https://star-history.com/#ywnd1144/Gopay_plus_automatic&Date)
