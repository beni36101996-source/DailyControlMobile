import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';
import 'details.dart';
import 'sheets_portal.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  void open(BuildContext context, DetailKind kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
  Future<void> action(BuildContext context, String name, String endpoint) async {
    if (!DailyControlApi.canWrite) {
      showFeedback(context, 'Akses tulis belum aktif. Buka Koneksi LIVE.');
      return;
    }
    final payload = <String, dynamic>{};
    if (endpoint == 'update-delivered') {
      try {
        final response = await DailyControlApi.get('/v1/delivered/periods', const {});
        final periods = (response['periods'] as List).map((x) => '$x').toList();
        if (!context.mounted || periods.isEmpty) return;
        final period = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
          title: const Text('Pilih PERIODE Delivered'),
          children: [for (final p in periods) SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, p), child: Text(p))]));
        if (period == null || !context.mounted) return;
        payload['period'] = period;
      } catch (error) {
        if (context.mounted) showFeedback(context, 'Gagal membaca daftar periode: $error');
        return;
      }
    }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(name),
      content: Text('Aksi ini akan mengubah Google Sheets OPERASIONAL ASLI. ${endpoint == 'update-delivered' ? 'Periode: ${payload['period']}' : 'Pastikan data sumber sudah benar.'} Lanjutkan?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjut'))],
    ));
    if (confirmed != true || !context.mounted) return;
    if (!DailyControlApi.isReady) {showFeedback(context, 'Belum terhubung. Tidak ada perubahan pada Spreadsheet.'); return;}
    try {
      final res = await DailyControlApi.action(endpoint, payload);
      if (context.mounted) showFeedback(context, res['jobId'] != null
        ? 'Masuk antrean: ${res['jobId']}. Cek tab Upload untuk memastikan DONE.'
        : (res['message']?.toString() ?? 'Proses dikonfirmasi server.'));
    } catch (e) {if (context.mounted) showFeedback(context, '$e');}
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const SyncNotice(), const SizedBox(height: 14),
    const PageSectionTitle('Operasional & Admin', icon: Icons.settings_outlined), const SizedBox(height: 12),
    QuickItem(title: 'Buka Spreadsheet Asli', subtitle: 'Seluruh laporan, warna, dan perhitungan dari Google Sheets', icon: Icons.table_chart_outlined, onTap: () => SheetsPortalScreen.openSheet(context, gid: 1043010834)),
    const SizedBox(height: 9),
    QuickItem(title: 'Update Rider / Data Monitoring Target', subtitle: 'Jalankan syncV7AllInOne dari script asli: source week, roster, actual, dan rumus', icon: Icons.groups_2_outlined, onTap: () => action(context, 'Update Rider / Monitoring Target', 'update-target-riders')),
    const SizedBox(height: 9),
    QuickItem(title: 'Update Data DAILY ACTIVE', subtitle: 'Jalankan DAN_updateData dari script asli; membaca sheet harian', icon: Icons.sync_outlined, onTap: () => action(context, 'Update Daily Active', 'update-daily-active')),
    const SizedBox(height: 9),
    QuickItem(title: 'Update Delivered', subtitle: 'Manual; bukan bagian dari Upload Harian', icon: Icons.update, onTap: () => action(context, 'Update Delivered', 'update-delivered')),
    const SizedBox(height: 9),
    QuickItem(title: 'Jadikan Raw Backlog Awal Hari Ini', subtitle: 'Buat baseline snapshot harian', icon: Icons.today, onTap: () => action(context, 'Jadikan Raw Backlog Awal Hari Ini', 'baseline-backlog')),
    const SizedBox(height: 9),
    QuickItem(title: 'Refresh Aging Paket dari Order', subtitle: 'Sinkronkan OnHoldReason & Size Type; snapshot tidak di-reset', icon: Icons.sync, onTap: () => action(context, 'Refresh Aging Paket dari Order', 'refresh-aging')),
    const SizedBox(height: 9),
    QuickItem(title: 'Bagikan Laporan ke WhatsApp', subtitle: 'Pilih banyak rider/akun; salin pesan dan buka WA', icon: Icons.message_outlined, onTap: () => open(context, DetailKind.whatsapp)),
    const SizedBox(height: 9),
    QuickItem(title: 'Delete Sheet (Admin)', subtitle: 'Tidak tersedia melalui mobile untuk melindungi spreadsheet asli', icon: Icons.lock_outline, onTap: () => showFeedback(context, 'Hapus sheet tetap melalui Google Sheets / akun admin.')),
    const SizedBox(height: 10),
    const Panel(child: Text('Update Rider/Monitoring menjalankan syncV7AllInOne. Update Daily Active menjalankan DAN_updateData. Keduanya masuk antrean dan harus berstatus DONE untuk dianggap selesai.', style: TextStyle(fontSize: 12))),
    const SizedBox(height: 14),
    const Panel(child: Text('Aksi hanya tersedia setelah Gateway Apps Script terverifikasi dan izin tulis diaktifkan. Delete Sheet sengaja tidak dibuka ke aplikasi.', style: TextStyle(fontSize: 12))),
  ]);
}
