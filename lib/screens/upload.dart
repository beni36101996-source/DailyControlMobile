import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/api_service.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';

enum UploadKind { harian, order, backlog }

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  UploadKind selected = UploadKind.harian;
  String mode = 'baru';
  final sheetController = TextEditingController();
  String? fileName;
  Uint8List? fileBytes;
  String? info;
  List<String> headers = [];
  int? estimatedRows;
  bool uploading = false;
  bool checkingJobs = false;
  List<Map<String,dynamic>> jobs = [];

  String get label => switch (selected) {
    UploadKind.harian => 'Upload Data Harian',
    UploadKind.order => 'Upload Data Order',
    UploadKind.backlog => 'Upload Data Backlog',
  };

  @override
  void dispose() { sheetController.dispose(); super.dispose(); }

  Future<void> pick() async {
    try {
      final allowed = selected == UploadKind.backlog ? <String>['xlsx', 'csv'] : <String>['csv'];
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: allowed, withData: true);
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      var bytes = picked.bytes;
      if (bytes == null && picked.path != null) bytes = await File(picked.path!).readAsBytes();
      if (bytes == null) throw StateError('File tidak dapat dibaca.');
      final name = picked.name;
      final ext = name.toLowerCase().split('.').last;
      if (!allowed.contains(ext)) throw StateError('Format file tidak sesuai jenis upload.');
      List<String> cols = [];
      int? rowCount;
      String note = 'File dipilih, siap diperiksa. Belum diunggah ke Spreadsheet.';
      if (ext == 'csv') {
        final contents = utf8.decode(bytes, allowMalformed: true).replaceFirst('\uFEFF', '');
        final lines = const LineSplitter().convert(contents);
        rowCount = lines.isEmpty ? 0 : lines.length - 1;
        cols = lines.isEmpty ? [] : lines.first.split(',').map((e) => e.replaceAll('"', '').trim()).toList();
        final required = selected == UploadKind.harian
          ? ['Driver', 'Vehicle Type', 'Contract Type']
          : selected == UploadKind.order ? ['Order ID'] : ['Shipment ID'];
        final missing = required.where((c) => !cols.any((h) => h.toLowerCase() == c.toLowerCase())).toList();
        note = missing.isEmpty
          ? 'Pratinjau CSV terbaca. Perkiraan $rowCount baris; belum diunggah.'
          : 'Perlu verifikasi format. Kolom belum ditemukan: ${missing.join(', ')}. Nama kolom dapat berbeda pada export.';
      } else {
        note = 'Excel dipilih (${(bytes.length / 1024).toStringAsFixed(0)} KB). Pemeriksaan kolom Excel akan dilakukan server setelah integrasi.';
      }
      if (!mounted) return;
      setState(() { fileName = name; fileBytes = bytes; headers = cols; estimatedRows = rowCount; info = note; });
    } catch (e) {
      if (mounted) showFeedback(context, 'Gagal memilih file: $e');
    }
  }

  Future<void> upload() async {
    if (fileBytes == null || fileName == null) { showFeedback(context, 'Pilih file terlebih dahulu.'); return; }
    if (selected == UploadKind.harian && sheetController.text.trim().isEmpty) { showFeedback(context, 'Isi nama sheet harian.'); return; }
    if (!DailyControlApi.canUpload) {
      await showDialog<void>(context: context, builder: (context) => AlertDialog(
        title: const Text('Upload belum diizinkan'),
        content: const Text('File sudah dipilih. Namun koneksi belum diverifikasi atau izin upload server belum diaktifkan. Spreadsheet BELUM berubah. Buka menu Koneksi LIVE.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
      ));
      return;
    }
    setState(() => uploading = true);
    try {
      final res = await DailyControlApi.upload(kind: selected.name, fileName: fileName!, bytes: fileBytes!, sheetName: selected == UploadKind.harian ? sheetController.text.trim() : null, mode: selected == UploadKind.harian ? mode : null);
      if (mounted) {
        showFeedback(context, res['jobId'] != null
          ? 'Masuk antrean: ${res['jobId']}. Belum selesai; cek status di bawah.'
          : (res['message']?.toString() ?? 'Proses diterima server.'));
        await refreshJobs();
      }
    } catch (e) {
      if (mounted) showFeedback(context, 'Upload tidak berhasil: $e');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> refreshJobs() async {
    if (!DailyControlApi.isReady || checkingJobs) return;
    setState(() => checkingJobs = true);
    try {
      final fresh = await DailyControlApi.latestJobs();
      if (mounted) setState(() => jobs = fresh);
    } catch (e) {
      if (mounted) showFeedback(context, 'Status antrean belum terbaca: $e');
    } finally {
      if (mounted) setState(() => checkingJobs = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const SyncNotice(), const SizedBox(height: 14),
    const PageSectionTitle('Upload & Tools', icon: Icons.cloud_upload_outlined),
    const SizedBox(height: 10),
    Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pilih jenis upload', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      for (final k in UploadKind.values) ...[
        RadioListTile<UploadKind>(
          dense: true, contentPadding: EdgeInsets.zero, value: k, groupValue: selected,
          title: Text(switch (k) {UploadKind.harian => 'Data Harian (CSV)', UploadKind.order => 'Data Order (CSV)', UploadKind.backlog => 'Data Backlog (Excel / CSV)'}),
          subtitle: Text(switch (k) {UploadKind.harian => 'Membuat / memperbarui sheet tanggal; tanpa Update Delivered otomatis', UploadKind.order => 'Rekap Order & Delivered per Jam', UploadKind.backlog => 'Aging Paket & Snapshot Harian'}),
          onChanged: (v) => setState(() { selected = v!; fileName = null; fileBytes = null; info = null; headers = []; estimatedRows = null; }),
        ),
        if (k != UploadKind.values.last) const Divider(height: 8),
      ],
    ])), const SizedBox(height: 12),
    if (selected == UploadKind.harian) ...[
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Mode Data Harian', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'baru', label: Text('Buat Sheet Baru')), ButtonSegment(value: 'existing', label: Text('Sheet Ada'))],
          selected: {mode}, onSelectionChanged: (v) => setState(() => mode = v.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: sheetController, decoration: const InputDecoration(labelText: 'Nama sheet', hintText: '14 november')),
        const SizedBox(height: 8),
        const Text('Upload ini hanya mengisi sheet tanggal. Update Delivered dilakukan terpisah melalui menu operasional.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
      ])), const SizedBox(height: 12),
    ],
    Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: uploading ? null : pick, icon: const Icon(Icons.folder_open), label: const Text('Pilih File dari HP')),
      if (fileName != null) ...[
        const SizedBox(height: 12),
        Row(children: [const Icon(Icons.insert_drive_file_outlined, color: AppColors.blue), const SizedBox(width: 8), Expanded(child: Text(fileName!, style: const TextStyle(fontWeight: FontWeight.w700))), IconButton(onPressed: () => setState(() { fileName = null; fileBytes = null; info = null; }), icon: const Icon(Icons.close))]),
        if (estimatedRows != null) Text('Perkiraan baris CSV: $estimatedRows', style: const TextStyle(fontSize: 12)),
        if (info != null) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Text(info!, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
        if (headers.isNotEmpty) Text('Kolom CSV: ${headers.take(6).join(' · ')}${headers.length > 6 ? ' · ...' : ''}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: uploading ? null : upload, icon: const Icon(Icons.cloud_upload), label: Text(uploading ? 'Memproses...' : 'Upload & Proses'),
        style: FilledButton.styleFrom(padding: const EdgeInsets.all(14))),
      const SizedBox(height: 8),
      const Text('Upload hanya dianggap berhasil jika server mengonfirmasi. Upload Harian tidak menjalankan Update Delivered otomatis.', style: TextStyle(color: AppColors.muted, fontSize: 11)),
    ])),
    const SizedBox(height: 12),
    Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Status Upload / Pekerjaan', style: TextStyle(fontWeight: FontWeight.w800))),
        IconButton(onPressed: checkingJobs || !DailyControlApi.isReady ? null : refreshJobs,
          icon: const Icon(Icons.refresh), tooltip: 'Ambil status terbaru'),
      ]),
      if (checkingJobs) const LinearProgressIndicator(),
      if (jobs.isEmpty) const Text('Tekan refresh untuk melihat antrean dan hasil proses dari server.',
        style: TextStyle(fontSize: 11)),
      for (final job in jobs) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(job['status'] == 'DONE' ? Icons.check_circle :
            job['status'] == 'ERROR' ? Icons.error : Icons.schedule,
            size: 17, color: job['status'] == 'DONE' ? Colors.green :
              job['status'] == 'ERROR' ? Colors.red : Colors.orange),
          const SizedBox(width: 6),
          Expanded(child: Text('${job['action']} • ${job['status']} • ${job['note'] ?? ''}',
            style: const TextStyle(fontSize: 11))),
        ])),
    ])),
    const SizedBox(height: 12),
    Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Status Integrasi', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 8),
      Row(children: [Icon(DailyControlApi.isReady ? Icons.check_circle : Icons.info_outline, color: DailyControlApi.isReady ? AppColors.green : AppColors.orange), const SizedBox(width: 8), Expanded(child: Text(DailyControlApi.isReady ? 'Backend tersedia' : 'Upload live belum diaktifkan server'))]),
    ])), const SizedBox(height: 20),
  ]);
}
