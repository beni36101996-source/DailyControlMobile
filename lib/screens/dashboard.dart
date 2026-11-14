import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import '../widgets/ui.dart';
import '../widgets/sync_notice.dart';
import '../core/control_store.dart';
import 'details.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final store = DailyControlStore.instance;
  @override
  void initState() {super.initState(); store.addListener(_refresh);}
  void _refresh() {if (mounted) setState(() {});}
  @override
  void dispose() {store.removeListener(_refresh); super.dispose();}
  void open(DetailKind kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const SyncNotice(), const SizedBox(height: 9),
    const PageSectionTitle('Kinerja & Akses Cepat', icon: Icons.speed), const SizedBox(height: 10),
    const Row(children: [
      Expanded(child: StatCard('FIFO', '95,69%', icon: Icons.check_circle_outline, tint: AppColors.green)),
      SizedBox(width: 9),
      Expanded(child: StatCard('SameDay Delivered', '96,11%', icon: Icons.local_shipping_outlined, tint: AppColors.green)),
    ]), const SizedBox(height: 10),
    Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Link operasional', style: TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        _link('STD Daily', Icons.data_usage, AppColors.green),
        _link('Paket Stuck', Icons.inventory_2_outlined, AppColors.red),
        _link('Expedited', Icons.bolt, AppColors.purple),
        _link('Idle Time', Icons.timer_outlined, AppColors.orange),
      ]),
    ])), const SizedBox(height: 12),
    const Panel(child: Row(children: [
      Icon(Icons.track_changes, color: AppColors.orange, size: 30), SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Live Update Standardization', style: TextStyle(fontWeight: FontWeight.w800)),
        Text('Keritang 2 Hub — Data contoh', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      Pill('53,65%', color: AppColors.orange),
    ])), const SizedBox(height: 15),
    PageSectionTitle('Daily Task', icon: Icons.fact_check_outlined, action: Text('${store.checkedTasks.length}/14', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue))),
    const SizedBox(height: 8),
    Panel(child: Column(children: [
      LinearProgressIndicator(value: store.checkedTasks.length / 14, minHeight: 9, borderRadius: BorderRadius.circular(9)),
      const SizedBox(height: 8),
      const Text('Checklist bisa ditandai di HP. Tanpa API, perubahan BELUM masuk Spreadsheet.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      for (int i = 0; i < DailyControlDemo.weeklyTasks.length; i++)
        CheckboxListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(DailyControlDemo.weeklyTasks[i], style: const TextStyle(fontSize: 12)),
          value: store.checkedTasks.contains(i + 1),
          onChanged: (v) async {
              try {
                await store.setTask(i + 1, v == true);
                if (context.mounted) showFeedback(context, store.isLive ? 'Checklist tersinkron.' : 'Checklist tersimpan di HP (belum ke Sheets).');
              } catch (e) {if (context.mounted) showFeedback(context, 'Gagal menyimpan checklist: $e');}
            },
        ),
    ])), const SizedBox(height: 16),
    PageSectionTitle('Pre-Trip Pagi', icon: Icons.verified_user_outlined,
      action: TextButton(onPressed: () => open(DetailKind.pretrip), child: const Text('Lihat rider'))),
    const SizedBox(height: 7),
    const Row(children: [
      Expanded(child: StatCard('Pre Trip Rider', '90,48%', icon: Icons.two_wheeler, tint: AppColors.green)),
      SizedBox(width: 9),
      Expanded(child: StatCard('Pre Trip Driver', '0,00%', icon: Icons.local_shipping_outlined, tint: AppColors.red)),
    ]), const SizedBox(height: 9),
    QuickItem(title: 'Siapa yang belum mengisi?', subtitle: 'Daftar rider dan driver untuk kontrol pagi', icon: Icons.person_search, onTap: () => open(DetailKind.pretrip)),
    const SizedBox(height: 14),
    PageSectionTitle('Mulai Operasional', icon: Icons.flash_on), const SizedBox(height: 10),
    QuickItem(title: 'Upload Data', subtitle: 'Harian, Order, atau Backlog', icon: Icons.cloud_upload_outlined, onTap: () => widget.onNavigate(1)),
    const SizedBox(height: 8),
    QuickItem(title: 'Set Delivered', subtitle: 'Pilih periode dan lihat angka per rider', icon: Icons.calendar_month, onTap: () => open(DetailKind.delivered)),
    const SizedBox(height: 16),
  ]);

  Widget _link(String label, IconData icon, Color color) => InkWell(
    onTap: () => showFeedback(context, '$label: akses eksternal akan dikonfigurasi saat integrasi.'),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 134, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
    ),
  );
}
