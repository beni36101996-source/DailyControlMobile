import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../widgets/ui.dart';
import 'details.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});
  void open(BuildContext context, DetailKind kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
  Future<void> action(BuildContext context, String name, String endpoint) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(name),
      content: const Text('Aksi ini akan menulis ke Google Spreadsheet setelah backend dan login terhubung. Untuk sekarang hanya simulasi; data asli tidak berubah.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lanjut'))],
    ));
    if (confirmed != true || !context.mounted) return;
    if (!DailyControlApi.isReady) {showFeedback(context, 'Belum terhubung. Tidak ada perubahan pada Spreadsheet.'); return;}
    try {
      final res = await DailyControlApi.action(endpoint, {});
      if (context.mounted) showFeedback(context, res['message']?.toString() ?? 'Proses diselesaikan server.');
    } catch (e) {if (context.mounted) showFeedback(context, '$e');}
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 14),
    const PageSectionTitle('Operasional & Admin', icon: Icons.settings_outlined), const SizedBox(height: 12),
    QuickItem(title: 'Update Delivered', subtitle: 'Manual; bukan bagian dari Upload Harian', icon: Icons.update, onTap: () => action(context, 'Update Delivered', 'update-delivered')),
    const SizedBox(height: 9),
    QuickItem(title: 'Jadikan Raw Backlog Awal Hari Ini', subtitle: 'Buat baseline snapshot harian', icon: Icons.today, onTap: () => action(context, 'Jadikan Raw Backlog Awal Hari Ini', 'baseline-backlog')),
    const SizedBox(height: 9),
    QuickItem(title: 'Refresh Aging Paket dari Order', subtitle: 'Sinkronkan OnHoldReason & Size Type; snapshot tidak di-reset', icon: Icons.sync, onTap: () => action(context, 'Refresh Aging Paket dari Order', 'refresh-aging')),
    const SizedBox(height: 9),
    QuickItem(title: 'Bagikan Laporan ke WhatsApp', subtitle: 'Pilih banyak rider/akun; salin pesan dan buka WA', icon: Icons.message_outlined, onTap: () => open(context, DetailKind.whatsapp)),
    const SizedBox(height: 9),
    QuickItem(title: 'Delete Sheet (Admin)', subtitle: 'Membutuhkan login admin dan konfirmasi', icon: Icons.delete_outline, onTap: () => action(context, 'Delete Sheet', 'delete-sheet')),
    const SizedBox(height: 14),
    const Panel(child: Text('Aksi tulis sengaja belum diaktifkan pada prototype ini. Sebelum integrasi live, API harus memakai HTTPS, autentikasi pengguna, kontrol admin, dan pencatatan aktivitas.', style: TextStyle(fontSize: 12))),
  ]);
}
