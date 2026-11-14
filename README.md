# Daily Control Hub Mobile — V1 Android

Ini **proyek kode Flutter aplikasi Android**, bukan AppSheet/WebView. Layout dan navigasi merupakan prototipe pertama sesuai fungsi Daily Control Kemuning Riau Hub.

## Status yang harus dipahami

- ✅ **Tersedia di kode:** Dashboard, checklist demo, Pre-Trip, 3 pilihan file upload di HP, validasi dasar CSV, Aging Paket, Rekap Order, Set Delivered per rider, Productivity, Daily Active, Monitoring Target, Jadwal Libur, LH Trip, WhatsApp filter & copy, menu operasional.
- ✅ **File picker:** Memilih CSV untuk Harian/Order, CSV atau Excel untuk Backlog; menampilkan pratinjau nama file dan jumlah baris CSV perkiraan.
- ❗ **Belum tersambung:** Login, backend API, sinkronisasi data live Google Sheets, penulisan real upload, penghapusan, dan trigger bisnis. Semua angka dashboard saat ini **DEMO**, bukan data nyata.
- 🔒 **Aman untuk testing:** Tanpa API, tombol proses dan aksi admin tidak melakukan perubahan terhadap Spreadsheet; tidak ada klaim upload berhasil palsu.
- ⚙️ **Build APK:** Perlu Flutter + Android SDK (tidak terpasang di lingkungan pembuatan ini); bisa dilakukan pada komputer atau GitHub Actions.

## Membuat aplikasi Android pertama kali

1. Install **Flutter stable** dan **Android Studio** (Android SDK tersedia).
2. Ekstrak proyek ini ke folder `DailyControlMobile_V1`.
3. Buka terminal pada folder tersebut, lalu jalankan:

   ```bash
   flutter doctor
   flutter create --platforms=android --org com.kemuninghub .
   flutter pub get
   flutter run
   ```

4. Saat siap membuat file APK untuk diinstal:

   ```bash
   flutter build apk --release
   ```

5. File APK hasil build ada di `build/app/outputs/flutter-apk/app-release.apk`.

**Alternatif tanpa memasang Flutter lokal:** upload isi proyek ke repository GitHub milik sendiri, buka tab **Actions → Build APK Daily Control Mobile → Run workflow**, kemudian unduh artifact APK dari run tersebut. Workflow berada di `.github/workflows/build_android_apk.yml`. Ini membutuhkan akun GitHub serta proses build yang berhasil di layanan GitHub.

## Navigasi aplikasi

| Tab | Isi |
|---|---|
| Home | FIFO, SameDay Delivered, link operasional, Live Standardization, 14 Daily Task, Pre-Trip Rider/Driver |
| Upload | Upload Harian, Order, Backlog, mode sheet baru/ada dan pratinjau file |
| Laporan | Rekap Order, Aging Paket, Set Delivered (periode/tanggal/per rider), Productivity OPR, New LH Trip |
| Rider | Pre-Trip, Daily Active, Monitoring Target Rider, Jadwal Libur Rider |
| Menu | Update Delivered manual, baseline Backlog, Refresh Aging, WhatsApp, Delete Sheet khusus admin |

## Prinsip penting yang dipertahankan

- Upload Data Harian **tidak** memanggil Update Delivered.
- Nama rider dan Assigned/Delivered/OnHold/Target/Pencapaian terlihat langsung di Set Delivered.
- File Backlog di hari yang sama harus diubah menjadi snapshot dengan logika V12 di **backend**, bukan diam-diam diasumsikan dari data contoh pada HP.
- No. resi aging dapat disalin; WA membentuk nama rider lalu resi satu baris per nomor, dengan multi-select rider & account.
- WA tidak mengirim otomatis ke grup dan tidak melakukan mention otomatis.
- Semua data contoh hanya untuk layout/testing; jangan digunakan mengambil keputusan operasional.

## Struktur kode

- `lib/main.dart` — entry point
- `lib/screens/shell.dart` — navigasi 5 tab
- `lib/screens/dashboard.dart` — Dashboard dan Pre-Trip shortcut
- `lib/screens/upload.dart` — pemilihan file, validasi pratinjau, upload handler
- `lib/screens/monitoring.dart` — menu laporan
- `lib/screens/details.dart` — konten rinci laporan dan WhatsApp
- `lib/screens/rider.dart` — rider control
- `lib/screens/tools.dart` — menu aksi operasional
- `lib/core/api_service.dart` — kontrak API (tidak aktif sebelum login aman)
- `lib/core/demo_data.dart` — contoh data untuk pengujian UI
- `docs/INTEGRASI_API.md` — rencana integrasi yang tidak merusak Daily Control

## Apa yang perlu dibuat pada V2

1. Backend API terautentikasi (Cloud Run/serupa), tanpa memasukkan secret Spreadsheet di APK.
2. Login admin/operator dan kontrol hak akses per tindakan.
3. Baca data nyata (API read-only), baru uji upload di salinan Spreadsheet.
4. Implementasi benar Upload Harian, Update Delivered manual, Backlog V12 + snapshot WIB, Refresh Aging, dan event audit.
5. Setelah lolos uji, arahkan API ke file operasional utama dengan backup dan rollback.
