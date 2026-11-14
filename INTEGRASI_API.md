# Rencana integrasi Android ↔ Daily Control (belum aktif)

## Mengapa perlu lapisan API

Apps Script sidebar/HTML yang sebelumnya dipakai bukan antarmuka upload Android. APK harus mengirim file ke layanan backend yang mengautentikasi pengguna dan memanggil fungsi Apps Script/Sheets yang diizinkan. **Jangan memasukkan token tetap, client secret, atau akses editor Google Sheets ke dalam APK.**

## Kontrak endpoint yang telah disiapkan dalam `lib/core/api_service.dart`

Semua endpoint POST JSON via HTTPS, dengan header `Authorization: Bearer <access_token_pengguna>`; server memverifikasi identitas, role, ukuran berkas, jenis file, dan keberhasilan kerja sebelum merespons.

| Endpoint | Permintaan | Alur yang wajib dijaga |
|---|---|---|
| `/v1/upload/harian` | `fileName`, `base64Data`, `sheetName`, `mode` (`baru` atau `existing`) | Buat/isi sheet harian saja. JANGAN panggil Update Delivered. |
| `/v1/upload/order` | `fileName`, `base64Data` | Perbarui Raw Data dan Rekap Order, cocokkan metadata Aging secara aman. |
| `/v1/upload/backlog` | `fileName`, `base64Data` | Gunakan Snapshot Aging Harian V12 berbasis tanggal Asia/Jakarta. |
| `/v1/actions/update-delivered` | Data pemilihan periode/tanggal | Hanya bila admin memerintahkan, dengan validasi tanggal dan periode. |
| `/v1/actions/baseline-backlog` | Konfirmasi tindakan | Jangan timpa snapshot yang sudah terbentuk tanpa approval yang jelas. |
| `/v1/actions/refresh-aging` | - | Hanya enrichment OnHoldReason dan Size Type, tidak menghapus resi atau riwayat. |
| `/v1/actions/delete-sheet` | Nama sheet + bukti konfirmasi admin | Tolak non-sheet harian/dilindungi, catat audit log, validasi akses. |

Respons sukses hanya jika tindakan server benar-benar commit:

```json
{"ok":true,"message":"Upload berhasil; 124 baris diproses","processedRows":124,"updatedAt":"2026-11-14T14:00:00+07:00"}
```

Jika gagal:

```json
{"ok":false,"message":"CSV tidak sesuai: kolom Driver tidak ditemukan"}
```

## Endpoint baca yang masih perlu diimplementasikan

- `GET /v1/dashboard` — KPI FIFO, STD, Pre-Trip dan Daily Task
- `GET /v1/aging?date=...&account=...` — semua resi dari snapshot harian termasuk Delivered otomatis
- `GET /v1/orders` — Rekap per rider, Delivered per Jam
- `GET /v1/delivered/periods` & `/v1/delivered?period=...&date=...` — data per rider dan periode
- `GET /v1/productivity`, `/v1/daily-active`, `/v1/target-rider`, `/v1/schedule`, `/v1/lh-trip`

## Rujukan kode asli (tidak disertakan dalam paket untuk menjaga privasi)

- `UploadHandler.gs`: `createSheetFromCSV`, `importCSV`.
- `UpdateDataDelivered.gs`: pemilih periode dan pemanggilan fungsi terkait.
- `UpdateIsiDelivered.gs`: `UID_updateDelivered`.
- `UpdateDalamPeriode.gs`: `updateDeliveredPeriod`.
- `ModulRekapRider.gs`: menu Upload Order, Upload Backlog, Snapshot Aging, WhatsApp.
- `DailyActive.gs`, `MonitoringTargetProductivity.gs`, `ProductivityOPR.gs`, `RiderTest.gs`: sumber logika dashboard rider.

## Pengujian sebelum live

- Salinan Spreadsheet (staging), tidak menyentuh operasional sampai disetujui.
- Kasus 20 resi pagi → 10 resi siang → 20 tetap tercatat, 10 Delivered otomatis.
- Hari berikutnya dimulai dari snapshot baru dan tidak membawa resi Delivered kemarin.
- Order CSV menyusul Backlog: OnHoldReason dan Size Type terisi ulang, status tidak berubah.
- Upload Harian hanya membuat/isi sheet tanggal; Update Delivered adalah aksi kedua yang terpisah.
- Error API ditampilkan jelas dengan status gagal, dapat dicoba ulang tanpa menggandakan data.
- Rate limit, idempotency key, time zone Asia/Jakarta, timeout, audit, dan kontrol akses admin.
