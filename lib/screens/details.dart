import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/demo_data.dart';
import '../widgets/ui.dart';
import 'delivered_v2.dart';
import 'productivity_v2.dart';
import 'trip_v2.dart';
import 'holiday_v2.dart';
import 'rider_tables_v21.dart';
import 'live_sheet.dart';

enum DetailKind { pretrip, aging, rekap, delivered, productivity, trip, dailyActive, target, holiday, whatsapp }

extension DetailLabel on DetailKind {
  String get title => switch(this) {
    DetailKind.pretrip => 'Pre-Trip Control',
    DetailKind.aging => 'Aging Paket',
    DetailKind.rekap => 'Rekap Order',
    DetailKind.delivered => 'Set Delivered',
    DetailKind.productivity => 'Productivity OPR',
    DetailKind.trip => 'New LH Trip',
    DetailKind.dailyActive => 'Daily Active',
    DetailKind.target => 'Monitoring Target Rider',
    DetailKind.holiday => 'Jadwal Libur Rider',
    DetailKind.whatsapp => 'Bagikan Laporan WA',
  };
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.kind});
  final DetailKind kind;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(kind.title)),
    body: switch(kind) {
      DetailKind.pretrip => const LiveSheetView(path: '/v1/pretrip', title: 'Pre-Trip Rider'),
      DetailKind.aging => const LiveSheetView(path: '/v1/aging', title: 'Aging Paket'),
      DetailKind.rekap => const LiveSheetView(path: '/v1/recap-order', title: 'Rekap Order'),
      DetailKind.delivered => const DeliveredView(),
      DetailKind.productivity => const ProductivityView(),
      DetailKind.trip => const TripView(),
      DetailKind.dailyActive => const RiderTableV21(isTarget: false),
      DetailKind.target => const RiderTableV21(isTarget: true),
      DetailKind.holiday => const HolidayView(),
      DetailKind.whatsapp => const WhatsappView(),
    },
  );
}

class PreTripView extends StatefulWidget {
  const PreTripView({super.key});
  @override
  State<PreTripView> createState() => _PreTripViewState();
}
class _PreTripViewState extends State<PreTripView> {
  bool missingOnly = false;
  String type = 'Semua';
  @override
  Widget build(BuildContext context) {
    final list = DailyControlDemo.pretrip.where((r) =>
      (!missingOnly || r.status == 'Belum Isi') && (type == 'Semua' || r.type == type)).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      const DemoNotice(), const SizedBox(height: 12),
      const Row(children: [
        Expanded(child: StatCard('Pre-Trip Rider', '90,48%', icon: Icons.two_wheeler, tint: AppColors.green)),
        SizedBox(width: 8), Expanded(child: StatCard('Pre-Trip Driver', '0,00%', icon: Icons.local_shipping, tint: AppColors.red)),
      ]), const SizedBox(height: 12),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kontrol pengisian setiap pagi', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Hanya yang belum isi'), value: missingOnly, onChanged: (v) => setState(() => missingOnly = v)),
        Wrap(spacing: 7, children: ['Semua', 'Rider', 'Driver'].map((v) => ChoiceChip(label: Text(v), selected: type == v, onSelected: (_) => setState(() => type = v))).toList()),
      ])), const SizedBox(height: 12),
      PageSectionTitle('Daftar (${list.length})', icon: Icons.person_search), const SizedBox(height: 8),
      for (final e in list) ...[
        Panel(padding: const EdgeInsets.all(10), child: Row(children: [
          CircleAvatar(backgroundColor: e.status == 'Fit' ? const Color(0xFFDEF5E8) : const Color(0xFFFFE3E3),
            child: Icon(e.type == 'Rider' ? Icons.two_wheeler : Icons.local_shipping_outlined,
              color: e.status == 'Fit' ? AppColors.green : AppColors.red)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)), Text(e.type, style: const TextStyle(color: AppColors.muted, fontSize: 11))])),
          Pill(e.status, color: e.status == 'Fit' ? AppColors.green : AppColors.red),
        ])), const SizedBox(height: 7),
      ],
    ]);
  }
}

class AgingView extends StatefulWidget {const AgingView({super.key}); @override State<AgingView> createState() => _AgingViewState();}
class _AgingViewState extends State<AgingView> {
  String account = 'Semua';
  String search = '';
  bool activeOnly = false;
  @override
  Widget build(BuildContext context) {
    final accounts = ['Semua', ...DailyControlDemo.aging.map((e) => e.account).toSet().toList()];
    final records = DailyControlDemo.aging.where((e) =>
      (account == 'Semua' || e.account == account) &&
      (!activeOnly || e.status != 'Delivered') &&
      (e.rider.toLowerCase().contains(search.toLowerCase()) || e.resi.toLowerCase().contains(search.toLowerCase()))).toList();
    return ListView(padding: const EdgeInsets.all(14), children: [
      const DemoNotice(), const SizedBox(height: 12),
      const Row(children: [
        Expanded(child: StatCard('Total Aging', '14', icon: Icons.inventory_2_outlined)),
        SizedBox(width: 6), Expanded(child: StatCard('2–3 Days', '6', icon: Icons.access_time, tint: AppColors.orange)),
        SizedBox(width: 6), Expanded(child: StatCard('>3 Days', '8', icon: Icons.warning_amber, tint: AppColors.red)),
      ]), const SizedBox(height: 12),
      Panel(child: Column(children: [
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari rider atau nomor resi'), onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(initialValue: account, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Order Account'),
          items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (v) => setState(() => account = v!)),
        SwitchListTile(dense: true, contentPadding: EdgeInsets.zero, title: const Text('Hanya belum Delivered'), value: activeOnly, onChanged: (v) => setState(() => activeOnly = v)),
      ])), const SizedBox(height: 13),
      PageSectionTitle('Daftar Resi (${records.length})', icon: Icons.list_alt), const SizedBox(height: 9),
      for (final e in records) ...[
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(e.rider, style: const TextStyle(fontWeight: FontWeight.w900))), Pill(e.kategori, color: e.days > 3 ? AppColors.red : AppColors.orange)]),
          const SizedBox(height: 7),
          Row(children: [Expanded(child: Text(e.resi, style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w600))),
            IconButton(onPressed: () async {await Clipboard.setData(ClipboardData(text: e.resi)); if (context.mounted) showFeedback(context, 'Nomor resi tersalin.');}, icon: const Icon(Icons.copy, size: 18))]),
          Text('${e.account} • ${e.days.toStringAsFixed(2)} days • Attempts ${e.attempts}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 7),
          Row(children: [Pill(e.status, color: _statusColor(e.status)), const Spacer(), Text(e.sizeType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))]),
          if (e.reason.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('On Hold Reason: ${e.reason}', style: const TextStyle(fontSize: 12))),
        ])), const SizedBox(height: 8),
      ],
    ]);
  }
}

Color _statusColor(String s) {
  if (s == 'Delivered') return AppColors.green;
  if (s == 'Delivering') return AppColors.blue;
  if (s == 'OnHold') return AppColors.orange;
  return AppColors.purple;
}

class RecapView extends StatefulWidget {const RecapView({super.key}); @override State<RecapView> createState() => _RecapViewState();}
class _RecapViewState extends State<RecapView> {
  bool highest = false;
  bool hourly = false;
  String search = '';
  @override
  Widget build(BuildContext context) {
    final list = DailyControlDemo.riders.where((e) => e.name.toLowerCase().contains(search.toLowerCase())).toList()
      ..sort((a, b) => highest ? b.percentDelivered.compareTo(a.percentDelivered) : a.percentDelivered.compareTo(b.percentDelivered));
    return ListView(padding: const EdgeInsets.all(14), children: [
      const DemoNotice(), const SizedBox(height: 12),
      const Row(children: [Expanded(child: StatCard('Delivered', '1.403', tint: AppColors.green)), SizedBox(width: 6), Expanded(child: StatCard('Delivering', '1.734')), SizedBox(width: 6), Expanded(child: StatCard('OnHold', '63', tint: AppColors.orange))]),
      const SizedBox(height: 8),
      const Row(children: [Expanded(child: StatCard('% Delivered', '46,0%', tint: AppColors.red)), SizedBox(width: 8), Expanded(child: StatCard('Total Order', '3.210'))]),
      const SizedBox(height: 13),
      Panel(child: Column(children: [
        SegmentedButton<bool>(segments: const [ButtonSegment(value: false, label: Text('Per Rider')), ButtonSegment(value: true, label: Text('Per Jam'))], selected: {hourly}, onSelectionChanged: (v) => setState(() => hourly = v.first)),
        const SizedBox(height: 10),
        TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama rider'), onChanged: (v) => setState(() => search = v)),
        const SizedBox(height: 8),
        Row(children: [const Expanded(child: Text('Urutkan % Delivered', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          TextButton.icon(onPressed: () => setState(() => highest = !highest), icon: Icon(highest ? Icons.arrow_downward : Icons.arrow_upward, size: 16), label: Text(highest ? 'Tertinggi' : 'Terendah'))]),
      ])), const SizedBox(height: 12),
      for (final e in list) ...[
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))), Pill('${e.percentDelivered.toStringAsFixed(1)}%', color: e.percentDelivered >= 100 ? AppColors.green : e.percentDelivered >= 85 ? AppColors.orange : AppColors.red)]),
          const SizedBox(height: 9),
          if (!hourly) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _tiny('Delivered', '${e.delivered}', AppColors.green),
            _tiny('Delivering', '${e.delivering}', AppColors.blue),
            _tiny('OnHold', '${e.onHold}', AppColors.orange),
            _tiny('Total', '${e.assigned}', AppColors.navy),
          ]) else ...[
            const Text('Delivered per Jam — contoh distribusi (bukan data aktual)', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 7),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final h in [7,8,9,10,11,12,13,14]) Pill('$h: ${((h - 6) * e.delivered / 42).round()}')]),
          ],
        ])), const SizedBox(height: 8),
      ],
    ]);
  }
}

Widget _tiny(String label, String value, Color color) => Column(children: [Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10)), const SizedBox(height: 3), Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color))]);

class DailyActiveView extends StatelessWidget {const DailyActiveView({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 12),
    const Panel(child: Row(children: [Icon(Icons.calendar_today,color: AppColors.blue), SizedBox(width: 8), Text('November 2026',style: TextStyle(fontWeight: FontWeight.w800)), Spacer(), Pill('Total Rider 26')])), const SizedBox(height: 12),
    const Row(children: [Expanded(child: StatCard('Week 1 Avg','81,5%')), SizedBox(width: 6), Expanded(child: StatCard('Week 2 Avg','99,0%', tint: AppColors.green)), SizedBox(width: 6), Expanded(child: StatCard('Week 3 Avg','54,9%', tint: AppColors.orange))]),
    const SizedBox(height: 12),
    const Panel(child: Wrap(spacing: 10, runSpacing: 6,children: [Pill('M = Masuk',color: AppColors.green), Pill('L = Libur',color: AppColors.purple), Pill('LM = Libur tapi Masuk',color: AppColors.orange),Pill('SM = Masuk saat Libur',color: AppColors.red)])),
    const SizedBox(height: 12),
    for (final rider in DailyControlDemo.riders) ...[
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
        Text(rider.name,style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6), const Text('Dedicated / Rider · Status mingguan (contoh)',style: TextStyle(color: AppColors.muted,fontSize: 11)),
        const SizedBox(height: 7), const Row(children: [Pill('W1: M',color: AppColors.green),SizedBox(width: 6),Pill('W2: M',color: AppColors.green),SizedBox(width: 6),Pill('W3: L',color: AppColors.purple),SizedBox(width: 6),Pill('W4: M',color: AppColors.green)]),
      ])), const SizedBox(height: 8),
    ],
  ]);
}

class TargetView extends StatelessWidget {const TargetView({super.key});
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 12),
    const Panel(child: Column(children: [Row(children: [Pill('Source Week V7'), SizedBox(width: 8),Pill('DELIVERED 9–15')]), SizedBox(height: 12),Text('Aksi Update Rider dan Update Data aktif setelah backend tersambung.',style: TextStyle(fontSize: 12,color: AppColors.muted))])),
    const SizedBox(height: 12),
    for (final group in ['Rider Plus','Rider Dedicated','Driver Dedicated']) ...[
      PageSectionTitle(group,icon: Icons.track_changes), const SizedBox(height: 8),
      const Row(children: [Expanded(child: StatCard('Total kekurangan','537',tint: AppColors.red)),SizedBox(width: 6),Expanded(child: StatCard('Aktif besok','5',tint: AppColors.green)),SizedBox(width: 6),Expanded(child: StatCard('Kebutuhan / orang','53,70'))]),
      const SizedBox(height: 9),
      Panel(child: Column(children: [for (final row in [('Senin','550','767','+217'),('Selasa','550','498','-52'),('Rabu','440','470','+30'),('Kamis','550','452','-98')])
        Padding(padding: const EdgeInsets.symmetric(vertical: 8),child: Row(children: [Expanded(child: Text(row.$1,style:const TextStyle(fontSize:12))),Expanded(child: Text('Target ${row.$2}',style:const TextStyle(fontSize:11))),Expanded(child: Text('Actual ${row.$3}',style:const TextStyle(fontSize:11))),Pill(row.$4,color:row.$4.startsWith('-')?AppColors.red:AppColors.green)]))])),
      const SizedBox(height: 14),
    ],
  ]);
}

class WhatsappView extends StatefulWidget {const WhatsappView({super.key}); @override State<WhatsappView> createState() => _WhatsappViewState();}
class _WhatsappViewState extends State<WhatsappView> {
  late Set<String> riders;
  late Set<String> accounts;
  late TextEditingController editor;
  bool copied = false;
  Timer? copyTimer;
  List<String> get allRiders => DailyControlDemo.aging.where((e) => e.status != 'Delivered').map((e) => e.rider).toSet().toList()..sort();
  List<String> get allAccounts => DailyControlDemo.aging.map((e) => e.account).toSet().toList()..sort();
  @override
  void initState() {
    super.initState();
    riders = allRiders.toSet();
    accounts = allAccounts.toSet();
    editor = TextEditingController();
    _regenerate();
  }
  void _regenerate() {
    final lines = <String>[];
    for (final name in allRiders.where(riders.contains)) {
      final resi = DailyControlDemo.aging.where((e) => e.rider == name && accounts.contains(e.account) && e.status != 'Delivered').map((e) => e.resi).toList();
      if (resi.isEmpty) continue;
      if (lines.isNotEmpty) lines.add('');
      lines..add(name)..addAll(resi);
    }
    editor.text = lines.join('\n');
  }
  void _toggle(Set<String> dest, String v, bool selected) => setState(() {selected ? dest.add(v) : dest.remove(v); _regenerate(); copied = false;});
  @override
  void dispose() {copyTimer?.cancel(); editor.dispose(); super.dispose();}
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: editor.text));
    if (!mounted) return;
    setState(() => copied = true);
    copyTimer?.cancel();
    copyTimer = Timer(const Duration(seconds: 3), () {if (mounted) setState(() => copied = false);});
  }
  Future<void> _openWa() async {
    final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(editor.text)}');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) showFeedback(context, 'WhatsApp tidak dapat dibuka. Coba salin pesan.');
    } catch (e) {if (mounted) showFeedback(context, 'Tidak dapat membuka WhatsApp: $e');}
  }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 12),
    const Panel(child: Row(children: [Icon(Icons.message,color:AppColors.green),SizedBox(width:8),Expanded(child:Text('Backlog Aging 2–3 & >3 Days\nPesan singkat: nama rider + daftar resi',style:TextStyle(fontSize:12,fontWeight:FontWeight.w700)))])),
    const SizedBox(height: 12),
    _filterPanel('Rider (${riders.length}/${allRiders.length})', allRiders, riders), const SizedBox(height: 9),
    _filterPanel('Order Account (${accounts.length}/${allAccounts.length})', allAccounts, accounts), const SizedBox(height: 12),
    const PageSectionTitle('Pesan WhatsApp (bisa diedit)',icon:Icons.edit_note), const SizedBox(height: 8),
    TextField(controller: editor, minLines: 7, maxLines: 15, decoration: const InputDecoration(hintText:'Nama rider\nNomor resi...')),
    const SizedBox(height: 11),
    Row(children: [Expanded(child: FilledButton.icon(onPressed: _copy, icon: Icon(copied?Icons.check:Icons.copy), label: Text(copied?'Tersalin!':'Salin Pesan'))),
      const SizedBox(width: 9), Expanded(child: OutlinedButton.icon(onPressed: _openWa, icon:const Icon(Icons.message_outlined),label:const Text('Buka WA')))]),
    const SizedBox(height: 8),
    const Panel(child: Text('Nama rider dapat diganti dengan @mention manual setelah membuka grup WA. Aplikasi tidak mengirim otomatis ke grup dan tidak melakukan tagging otomatis.',style:TextStyle(fontSize:12,color:AppColors.muted))),
    const SizedBox(height: 20),
  ]);
  Widget _filterPanel(String title, List<String> values, Set<String> current) => Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
    Row(children: [Expanded(child: Text(title,style:const TextStyle(fontWeight:FontWeight.w800))),TextButton(onPressed:()=>setState(() {current.addAll(values);_regenerate();}),child:const Text('Semua')),TextButton(onPressed:()=>setState(() {current.clear();_regenerate();}),child:const Text('Kosongkan'))]),
    Wrap(spacing: 5,runSpacing: 0,children: values.map((v)=>FilterChip(label: Text(v,style:const TextStyle(fontSize:11)),selected: current.contains(v),onSelected: (s)=>_toggle(current,v,s))).toList()),
  ]));
}
