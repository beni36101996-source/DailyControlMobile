import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/operational_links.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import '../widgets/ui.dart';
import '../widgets/sync_notice.dart';
import '../core/control_store.dart';
import '../core/api_service.dart';
import 'details.dart';
import 'pretrip_missing.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onNavigate});
  final ValueChanged<int> onNavigate;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final store = DailyControlStore.instance;
  Map<String, dynamic>? liveDashboard;
  @override
  void initState() {
    super.initState();
    store.addListener(_refresh);
    if (store.isLive) {
      _loadLiveDashboard();
      store.refreshTasks().catchError((Object e) {
        if (mounted) showFeedback(context, 'Checklist belum bisa dibaca dari Sheets: $e');
      });
    }
  }
  Future<void> _loadLiveDashboard() async {
    try {
      final data = await DailyControlApi.get('/v1/dashboard', const {});
      if (mounted) setState(() => liveDashboard = data);
    } catch (error) {
      if (mounted) showFeedback(context, 'Dashboard LIVE belum bisa dimuat: $error');
    }
  }
  void _refresh() {if (mounted) setState(() {});}
  @override
  void dispose() {store.removeListener(_refresh); super.dispose();}
  void open(DetailKind kind) {
    if (kind == DetailKind.pretrip) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PretripMissingScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
    }
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const SyncNotice(), const SizedBox(height: 9),
    const PageSectionTitle('Kinerja & Akses Cepat', icon: Icons.speed), const SizedBox(height: 10),
    Row(children: [
      Expanded(child: StatCard('FIFO', '—', icon: Icons.check_circle_outline, tint: AppColors.green)),
      const SizedBox(width: 9),
      Expanded(child: StatCard('SameDay Delivered', '—', icon: Icons.local_shipping_outlined, tint: AppColors.green)),
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
    Panel(child: Row(children: [
      const Icon(Icons.track_changes, color: AppColors.orange, size: 30), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Live Update Standardization', style: TextStyle(fontWeight: FontWeight.w800)),
        Text(DailyControlApi.isReady ? 'Sumber: Dashboard asli' : 'Belum terhubung (data contoh tidak ditampilkan)',
          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      if (DailyControlApi.isReady && liveDashboard != null) const Pill('LIVE', color: AppColors.green),
    ])), const SizedBox(height: 15),
    PageSectionTitle('Daily Task', icon: Icons.fact_check_outlined, action: Text('${store.checkedTasks.length}/14', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue))),
    const SizedBox(height: 8),
    Panel(child: Column(children: [
      LinearProgressIndicator(value: store.checkedTasks.length / 14, minHeight: 9, borderRadius: BorderRadius.circular(9)),
      const SizedBox(height: 8),
      Text(store.tasksFromServer && store.isLive ? 'Dibaca langsung dari DASHBOARD!M17:M30.' : 'Belum menerima checklist dari Google Sheets. Hubungkan API terlebih dahulu.',
        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      for (int i = 0; i < 14; i++)
        CheckboxListTile(
          dense: true, contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(store.tasksFromServer && store.liveTaskLabels.length > i ? store.liveTaskLabels[i] : DailyControlDemo.weeklyTasks[i],
            style: const TextStyle(fontSize: 12)),
          value: store.checkedTasks.contains(i + 1),
          onChanged: (DailyControlApi.canWrite && store.tasksFromServer) ? (v) async {
              try {
                await store.setTask(i + 1, v == true);
                if (context.mounted) showFeedback(context, store.isLive ? 'Checklist tersinkron.' : 'Checklist tersimpan di HP (belum ke Sheets).');
              } catch (e) {if (context.mounted) showFeedback(context, 'Gagal menyimpan checklist: $e');}
            } : null,
        ),
    ])), const SizedBox(height: 16),
    PageSectionTitle('Pre-Trip Pagi', icon: Icons.verified_user_outlined,
      action: TextButton(onPressed: () => open(DetailKind.pretrip), child: const Text('Lihat rider'))),
    const SizedBox(height: 7),
    Row(children: [
      Expanded(child: StatCard('Pre Trip Rider', '—', icon: Icons.two_wheeler, tint: AppColors.green)),
      const SizedBox(width: 9),
      Expanded(child: StatCard('Pre Trip Driver', '—', icon: Icons.local_shipping_outlined, tint: AppColors.red)),
    ]), const SizedBox(height: 9),
    QuickItem(title: 'Siapa yang belum mengisi?', subtitle: 'Daftar rider dan driver untuk kontrol pagi', icon: Icons.person_search, onTap: () => open(DetailKind.pretrip)),
    const SizedBox(height: 14),
    const SizedBox(height: 16),
  ]);

  Future<void> _openOperationalLink(String name) async {
    final saved = await OperationalLinks.load(name);
    if (!mounted) return;
    if (saved.isEmpty) {
      await _editOperationalLink(name);
      return;
    }
    final uri = Uri.tryParse(saved);
    if (uri == null || uri.scheme != 'https' || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showFeedback(context, 'Link tidak bisa dibuka. Periksa alamatnya.');
    }
  }

  Future<void> _editOperationalLink(String name) async {
    final controller = TextEditingController(text: await OperationalLinks.load(name));
    if (!mounted) {controller.dispose(); return;}
    final changed = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Link $name'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tempel URL HTTPS dari tombol Buka file pada spreadsheet. Tidak perlu mengubah kode aplikasi.', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 10),
        TextField(controller: controller, keyboardType: TextInputType.url, autocorrect: false,
          decoration: const InputDecoration(labelText: 'Alamat HTTPS', hintText: 'https://...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Simpan link')),
      ],
    ));
    controller.dispose();
    if (changed == null || !mounted) return;
    try {
      await OperationalLinks.save(name, changed);
      if (mounted) showFeedback(context, 'Link $name tersimpan. Ketuk kartu untuk membuka.');
    } catch (e) {if (mounted) showFeedback(context, '$e');}
  }

  Widget _link(String label, IconData icon, Color color) => InkWell(
    onTap: () => _openOperationalLink(label),
    onLongPress: () => _editOperationalLink(label),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 134, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [Icon(icon, color: color), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3), const Text('Tahan untuk edit link', style: TextStyle(fontSize: 9, color: AppColors.muted))]),
    ),
  );
}
