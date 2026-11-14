# Daily Control Mobile V2 — kontrak sinkronisasi (BELUM AKTIF)

**Status V2:** antarmuka baru bisa menyimpan input ke penyimpanan lokal HP dengan `shared_preferences`. Itu BUKAN perubahan ke Google Sheets. Untuk menggunakan data operasional, harus ada backend terautentikasi melalui HTTPS yang menjalankan tindakan di spreadsheet dan mengirim respons `ok:true` **setelah** penulisan selesai. Saat backend tersedia (`DailyControlApi.isReady`), kode `DailyControlStore` mengirim permintaan terlebih dahulu dan hanya kemudian memperbarui cache lokal.

## Data Google Sheets yang perlu dibaca dan ditulis

| Halaman | Baca | Aksi tulis | Aturan spreadsheet |
| --- | --- | --- | --- |
| Dashboard → Daily Task | `GET /v1/dashboard/tasks` | `POST /v1/actions/daily-task` `{taskId: 1..14, completed: boolean}` | Petakan `taskId` ke checklist yang benar. Jangan ubah data lainnya. Segera baca kembali dari server ketika halaman dibuka |
| Jadwal Libur Rider | `GET /v1/holidays` | `POST /v1/actions/holiday-assignment` `{id,day,name,type}` dan `holiday-assignment-delete`; juga `holiday-note`, `holiday-note-delete` | Gunakan sheet `JADWAL LIBUR RIDER KEMUNING RIAU HUB`. Warna = Driver Dedicated ungu, Rider Plus toska, Rider Dedicated kuning. Pertahankan catatan cuti |
| Set Delivered | `GET /v1/delivered?period=...&date=YYYY-MM-DD` | Baca saja | Server mengembalikan seluruh rider sesuai urutan sheet termasuk rider 0, `offLabel` untuk LIBUR / SALAH LIBUR, semua angka, target, dan grup warna |
| Productivity OPR | `GET /v1/productivity?month=YYYY-MM` | `POST /v1/actions/productivity-day` `{date,inbound,operators,outbound}` dan `productivity-target` `{target}` | Input hanya kolom manual per hari; hasil formula Productivity, Gap, Avg, dan % di sheet tidak ditimpa. Pakai tanggal, bukan indeks baris hardcoded |
| New LH Trip | `GET /v1/lh-trip?date=YYYY-MM-DD` | `POST /v1/actions/lh-trip` objek `TripSlot.toJson()` | Per tanggal dan slot 1–3. Jangan menimpa tanggal atau slot lain. Pertahankan kolom operasional (Trip ID, estimated/actual times, status, TO, kendaraan, group, driver) |

**Kontrak respons GET:** `{"ok":true,"rows":[...]}`; untuk `delivered` setiap baris mengandung `riderName`, `assigned`, `delivered`, `onHold`, `target`, `group` (`driverDedicated`, `riderPlus`, `riderDedicated`) dan `offLabel` jika ada.

**Kontrak respons POST:** `{"ok":true,"message":"...","updatedAt":"..."}` hanya setelah spreadsheet sukses diperbarui. Untuk error: `{"ok":false,"message":"..."}` disertai status HTTP non-2xx. Setiap endpoint perlu validasi role, tanggal (Asia/Jakarta), identitas sheet, lock, audit log, idempotensi dan konfirmasi pengubahan nilai.

## Koneksi backend dan keamanan

- **JANGAN** menyisipkan service account JSON, token editor, atau kunci Web App Apps Script ke APK publik.
- Memerlukan login pengguna (mis. OAuth Google) dan backend dengan izin tulis terbatas.
- Backend harus membaca sheet saat membuka halaman agar perubahan dari spreadsheet dan dari HP saling terlihat.
- Saat backend belum ada, banner `MODE LOKAL` dan konfirmasi `belum masuk Spreadsheet` wajib tetap muncul.
- Saat server tersedia, uji baca dahulu, lalu uji tulis hanya pada salinan Daily Control. Jangan aktifkan terhadap spreadsheet produksi tanpa backup, izin, dan pengujian konflik.

## Yang belum diwujudkan dalam V2

Belum ada server/Google OAuth login dan pengambilan data live dari Google Sheets untuk tugas, libur, Productivity, dan LH Trip. UI V2 menyediakan local-save dan kontrak tulis yang aman; hanya Set Delivered sudah mempunyai pembaca GET bersyarat sebagai contoh integrasi, sementara endpoint API aktual harus dibuat. Ini bukan aplikasi sinkronisasi produksi.
