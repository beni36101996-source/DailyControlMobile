# Daily Control Mobile V2 — Revisi 14 November 2026

Ini **source Flutter V2**, bukan APK langsung. Proyek melanjutkan V1 yang sudah berhasil dibuild melalui GitHub Actions.

## Revisi yang sudah masuk

1. **Jadwal Libur Rider**: semua rider sesuai contoh spreadsheet; warna dan legenda Driver Dedicated (ungu), Rider Plus (toska), Rider Dedicated (kuning). Tap nama untuk edit hari/nama/kategori; tambah/hapus rider; tambah/edit/hapus catatan cuti.
2. **Set Delivered**: daftar **26 nama rider contoh** dalam baris padat; Assigned, Delivered, On Hold, %, Target, Pencapaian; warna grup rider dan pencapaian, teks LIBUR/SALAH LIBUR; pencarian, filter kategori, pilihan periode/tanggal. Data referensi yang ditampilkan hanya contoh 13 Nov 2026.
3. **Dashboard Daily Task**: checklist 14 tugas bisa diubah, progres langsung terhitung, status tersimpan di HP.
4. **Productivity OPR**: pilih bulan; tap tanggal untuk mengisi Actual LM Inbound, Operator Masuk, Actual LM Outbound; produktivitas, gap dan persentase dihitung otomatis; dapat mengubah target.
5. **New LH Trip**: pilih tanggal dan edit Slot 1–3. Form mencakup ID, estimasi/jadwal/actual, status, Order, Pack, nomor kendaraan, tipe kendaraan dan driver.
6. **Penyimpanan V2**: input lokal tersimpan antarsesi di HP (`shared_preferences`). Tampil pemberitahuan ringkas agar tidak disalahartikan sudah sinkron ke Google Sheets.
7. Menu V1 lain seperti Upload Harian/Order/Backlog, Aging Paket, Rekap Order, WhatsApp, Daily Active dan Monitoring Target tetap dipertahankan dalam source.

## PENTING: Belum sinkron dengan Spreadsheet!

Aplikasi **tidak otomatis menulis data ke Google Sheets**. Belum ada server API dan autentikasi. UI hanya mengizinkan edit data lokal untuk uji pengalaman pengguna. Semua angka awal adalah contoh dari screenshot, bukan monitoring live. Kontrak API dan aturan keamanan lihat `docs/CONTRAK_SYNC_V2.md`. Mengubah checkbox di HP belum mengubah checkbox spreadsheet sampai API tersambung.

## Pasang pembaruan lewat GitHub Desktop (Windows)

1. Download ZIP V2 dan klik kanan → **Extract All**.
2. Di folder hasil ekstrak, pilih isi folder: `.github`, `docs`, `lib`, `test`, `pubspec.yaml`, `analysis_options.yaml`, `README.md` (jangan salin ZIP ke GitHub).
3. Tekan **Ctrl+C**.
4. GitHub Desktop → pilih repository `DailyControlMobile` → **Repository → Show in Explorer**.
5. Di jendela repository yang terbuka, **Ctrl+V**, pilih **Replace** bila diminta. Jangan menghapus folder `.git`.
6. Kembali ke GitHub Desktop. Centang hanya file source di `lib`, `test`, `.github`, dokumen dan `pubspec.yaml`, **jangan** centang file `.idea`.
7. Summary `Daily Control Mobile V2 - revisi tampilan dan form harian` → **Commit to main** → **Push origin**.
8. Buka GitHub → Actions → Build APK Daily Control Mobile. Jika hijau, klik run → Artifacts → `DailyControlMobile-V2-APK` → unduh ZIP → ekstrak `app-release.apk`.
9. Instal APK pada HP yang sama. Versi APK diperbarui menjadi `0.2.0+2` agar perubahan dikenali. Bila tanda tangan APK rilis berubah antar-build dan Android menolak upgrade, backup data lokal penting sebelum uninstall (uninstall biasanya menghapus data lokal) lalu pasang versi baru.

## Status validasi

Pemeriksaan struktur folder, dependensi dan keseimbangan sintaks berhasil. **Belum menjalankan Flutter SDK/Android build di lingkungan penyusunan ini.** Keberhasilan kompilasi harus dikonfirmasi dari GitHub Actions. Workflow V2 memakai pemeriksaan kode sumber dan unit-test model, serta build APK.
