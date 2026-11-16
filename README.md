# Daily Control Hub Mobile — Operasional

Aplikasi Flutter untuk Android. Dibangun via GitHub Actions dari repository `DailyControlMobile`.

## Akses Data

`lib/core/api_service.dart` menghubungkan Flutter ke Apps Script **standalone di Gmail pribadi**.
Kredensial disimpan di Android Keystore. Tidak ada API key dalam source.

## Koneksi dan unggah

- Baca/tulis UI: langsung ke tab asli via Gateway.
- Upload Harian/Order/Backlog, Update Delivered, Baseline Backlog, Refresh Aging: antrean via dua sheet
  tersembunyi. Worker pada Apps Script asli memproses berdasarkan urutan, **tidak instant**.
- Periksa menu **Upload → Status Upload/Pekerjaan**. DONE berarti selesai di script asli.

## Build

Di repository root: `pubspec.yaml`, `lib/`, `test/`, `.github/workflows/build_android_apk.yml`.
Jalankan GitHub Actions `Build APK Daily Control Mobile`, ambil artifact
`DailyControlMobile-Operasional-APK`, lalu ekstrak `app-release.apk`.

Panduan pemasangan lengkap ada pada `../README_MULAI_DISINI.txt` di paket sumber.
