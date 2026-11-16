# DAILY CONTROL MOBILE — SPREADSHEET ASLI (16 NOVEMBER 2026)

## Keputusan desain
- **Home lama dipertahankan**, khusus tombol Pre-Trip sekarang menampilkan nama **berstatus X / belum isi** dari data asli, bukan semua orang.
- **Laporan** membuka tab pada **Google Sheets asli** di HP (via app Sheets/browser). Tidak meniru atau mengubah rumus/warna/format. Sel tetap dapat diedit memakai akun Google yang memiliki izin Editor.
- **Navigasi aplikasi** hanya berisi Dashboard, Rekap Order, Aging Paket, Productivity OPR, Monitoring Target Rider, Jadwal Libur Rider, New LH Trip, Daily Active, dan periode DELIVERED.
- Tidak ada pintasan Raw Data, Raw Backlog, Master, Snapshot, backup, dan sheet bantu. Semua data tersebut tetap utuh di spreadsheet asli.
- **Upload** CSV Harian/Order dan CSV/Excel Backlog tetap satu menu; Upload Harian tidak menjalankan Update Delivered otomatis.
- **Menu** berisi Update Rider/Monitoring (via `syncV7AllInOne`), Update DAILY ACTIVE (via `DAN_updateData`), Update Delivered, Baseline Backlog, Refresh Aging, WhatsApp, dan Koneksi.
- Update dan upload yang berjalan melalui antrean **hanya selesai bila status DONE** pada layar Upload.

## Cara memasang source APK
1. Ekstrak `DailyControlMobile_Spreadsheet_Asli_Source_GitHub.zip`.
2. Salin isi folder hasil ekstrak ke **root** repository `DailyControlMobile` melalui GitHub Desktop, replace jika diminta; **jangan hapus folder `.git`**.
3. Commit dan Push. GitHub Actions otomatis membangun `DailyControlMobile-Operasional-APK`; unduh hasil jika centang hijau.
4. APK mengingat URL Gateway dan API key bila instalasi menimpa versi lama tanpa membersihkan data. Jika belum terhubung, gunakan menu Koneksi (atau QR admin).

## Pembaruan backend untuk tombol tambahan
Untuk **Update Rider / Monitoring**, **Update Daily Active**, dan **periode DELIVERED otomatis**, gunakan dua file pada `DailyControlMobile_Backend_Tombol_Update.zip`:
- `GatewayBaca.gs`: **replace isi file dengan nama yang sama** di proyek Apps Script Gmail pribadi; Deploy > Manage deployments > Edit > New version > Deploy.
- `MobileQueueWorker.gs`: **replace isi file dengan nama yang sama** di Apps Script asli; Save, tidak perlu mengubah trigger worker yang sudah aktif.

**Penting:** jangan menambahkan file dengan isi yang sama sebagai duplikat fungsi; backup kode lama dulu. Kode baru dibuat berdasar versi paket Gateway sebelumnya, sehingga jika ada perubahan kode Gateway/Worker setelah paket itu dipasang, cek perbedaannya dulu sebelum replace.

## Batasan dan keamanan
- *Google Sheets asli* dibuka di aplikasi Google Sheets/browser; bukan WebView terselubung. Tab lainnya yang masih tampak di Google Sheets mengikuti izin/pengaturan spreadsheet asli, bukan daftar navigasi APK.
- Pre-Trip menggunakan **X = belum mengisi** berdasarkan `BotRiderKemuning.gs`; status kosong dilabeli belum tersedia, bukan salah dihitung sebagai X.
- Target tombol Update Rider/Monitoring menjalankan fungsi `syncV7AllInOne` **asli** yang juga menyinkronkan roster, source week, actual, dan formula. Update Data Daily Active menjalankan `DAN_updateData` **asli**.
- Dua action baru butuh update backend; jika hanya APK diperbarui, action baru akan mendapat pesan `Aksi API belum didukung` dan **tidak menulis data**.
- Gateway mempergunakan kunci bersama dalam QR; batasi pemakai, rotasi kunci yang pernah terlihat, dan gunakan integrasi perusahaan yang diizinkan.
- **Belum dikompilasi di lingkungan ini**. Periksa hasil GitHub Actions dan uji satu operasi terkontrol sebelum digunakan secara luas.
