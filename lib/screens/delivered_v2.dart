import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/api_service.dart';
import '../core/control_store.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';
import 'holiday_v2.dart' show riderTypeColor;

class DeliveryRow {
  const DeliveryRow(this.name, this.assigned, this.delivered, this.hold, this.target, this.group, {this.offLabel = ''});
  final String name, offLabel;
  final int assigned, delivered, hold, target;
  final RiderType group;
  double get rate => assigned == 0 ? 0 : delivered / assigned * 100;
  double get achievement => target == 0 ? 0 : delivered / target * 100;
  factory DeliveryRow.fromApi(Map<String, dynamic> x) {
    int numVal(Object? o) => o is num ? o.toInt() : int.tryParse('$o') ?? 0;
    final group = RiderType.values.firstWhere((v) => v.name == '${x['group']}', orElse: () => RiderType.riderDedicated);
    return DeliveryRow('${x['riderName'] ?? x['name'] ?? ''}', numVal(x['assigned']), numVal(x['delivered']),
      numVal(x['onHold'] ?? x['hold']), numVal(x['target']), group, offLabel: '${x['offLabel'] ?? ''}');
  }
}

// Screenshot transcription used only for V2 display testing; NOT a live 13 Nov report.
const demoDelivered13Nov = <DeliveryRow>[
  DeliveryRow('MUHAMMAD WANDA ARYA',77,73,4,75,RiderType.driverDedicated),
  DeliveryRow('HALIMAN',54,53,1,75,RiderType.driverDedicated),
  DeliveryRow('ADRIAN KUSWONDO',0,0,0,75,RiderType.driverDedicated,offLabel:'LIBUR'),
  DeliveryRow('RISFAL FADHILLAH',96,79,17,75,RiderType.driverDedicated),
  DeliveryRow('MARDIANSYAH',57,53,4,75,RiderType.driverDedicated),
  DeliveryRow('DONI',37,26,11,52,RiderType.driverDedicated),
  DeliveryRow('RUTAMA',0,0,0,52,RiderType.driverDedicated,offLabel:'SALAH LIBUR'),
  DeliveryRow('FIQI ARIANTO',98,94,4,110,RiderType.riderPlus),
  DeliveryRow('TRI IRWAN',76,65,11,110,RiderType.riderPlus),
  DeliveryRow('MUHAMMAD THORIQ LUBIS',115,106,9,110,RiderType.riderPlus),
  DeliveryRow('ARIYA WARDANA P',128,116,12,110,RiderType.riderPlus),
  DeliveryRow('AGUNG YUNANDA',0,0,0,110,RiderType.riderPlus,offLabel:'SALAH LIBUR'),
  DeliveryRow('RISKI ABDUR ROHIM',151,134,17,110,RiderType.riderPlus),
  DeliveryRow('RIZKI',77,61,16,110,RiderType.riderPlus),
  DeliveryRow('PRAMUJA',0,0,0,147,RiderType.riderDedicated,offLabel:'LIBUR'),
  DeliveryRow('ARIFFAN SURI PURBA',75,69,6,147,RiderType.riderDedicated),
  DeliveryRow('RIDHO AGUSTIAN',90,87,3,147,RiderType.riderDedicated),
  DeliveryRow('ISWAHYUDI',85,83,2,147,RiderType.riderDedicated),
  DeliveryRow('ALFARIDZI FATURRAHMAN',76,74,2,147,RiderType.riderDedicated),
  DeliveryRow('M. SYAWALUDIN PRATAMA',97,93,4,147,RiderType.riderDedicated),
  DeliveryRow('ISMAIL',0,0,0,147,RiderType.riderDedicated,offLabel:'LIBUR'),
  DeliveryRow('HAMDANI PULUNGAN',148,121,27,147,RiderType.riderDedicated),
  DeliveryRow('RENDI SAPUTRA',97,88,9,147,RiderType.riderDedicated),
  DeliveryRow('BINTANG S',129,113,16,147,RiderType.riderDedicated),
  DeliveryRow('NAZRAH RAMADANIA',65,48,17,56,RiderType.riderDedicated),
  DeliveryRow('PATEKAN',0,0,0,56,RiderType.riderDedicated,offLabel:'SALAH LIBUR'),
];

class DeliveredView extends StatefulWidget {
  const DeliveredView({super.key});
  @override
  State<DeliveredView> createState() => _DeliveredViewState();
}

class _DeliveredViewState extends State<DeliveredView> {
  String period = 'DELIVERED 9 - 15';
  DateTime date = DateTime(2026, 11, 13);
  final TextEditingController searchCtrl = TextEditingController();
  RiderType? filter;
  bool loading = false;
  List<DeliveryRow>? remoteRows;
  String? loadError;
  final periods = const ['DELIVERED 2 - 8', 'DELIVERED 9 - 15', 'DELIVERED 12 - 18',
    'DELIVERED 19 - 25', 'DELIVERED 26 - 1', 'DELIVERED 5 - 11'];

  @override
  void initState() {super.initState(); if (DailyControlApi.isReady) _load();}
  @override
  void dispose() {searchCtrl.dispose(); super.dispose();}

  Future<void> _pickDate() async {
    final newDate = await showDatePicker(context: context, initialDate: date,
      firstDate: DateTime(2025), lastDate: DateTime(2030));
    if (newDate != null) { setState(() { date = newDate; remoteRows = null; loadError = null; }); if (DailyControlApi.isReady) await _load(); }
  }

  Future<void> _load() async {
    setState(() { loading = true; loadError = null; });
    try {
      final response = await DailyControlApi.get('/v1/delivered', {'period': period, 'date': dcDateKey(date)});
      final list = response['rows'];
      if (list is! List) throw StateError('Server belum mengirim rows.');
      if (mounted) setState(() => remoteRows = [for (final x in list) DeliveryRow.fromApi(Map<String, dynamic>.from(x as Map))]);
    } catch (e) { if (mounted) setState(() => loadError = '$e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final example = period == 'DELIVERED 9 - 15' && dcDateKey(date) == '2026-11-13';
    final rows = remoteRows ?? (DailyControlApi.isReady || !example ? <DeliveryRow>[] : demoDelivered13Nov);
    final visible = rows.where((r) => (filter == null || r.group == filter) &&
      r.name.toLowerCase().contains(searchCtrl.text.trim().toLowerCase())).toList();
    final assigned = rows.fold<int>(0, (n, r) => n + r.assigned);
    final delivered = rows.fold<int>(0, (n, r) => n + r.delivered);
    final hold = rows.fold<int>(0, (n, r) => n + r.hold);

    return ListView(padding: const EdgeInsets.fromLTRB(8, 8, 8, 20), children: [
      const SyncNotice(),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: DropdownButtonFormField<String>(
          key: ValueKey(period), isDense: true, value: period,
          decoration: const InputDecoration(labelText: 'Periode', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 9, vertical: 9)),
          items: [for (final p in periods) DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))],
          onChanged: (v) {if (v != null) {setState(() {period = v; remoteRows = null;}); if (DailyControlApi.isReady) _load();}},
        )),
        const SizedBox(width: 7),
        OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month, size: 16),
          label: Text(dcDateShort(date), style: const TextStyle(fontSize: 11)),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14))),
        if (DailyControlApi.isReady) IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh), tooltip: 'Ambil data server'),
      ]),
      const SizedBox(height: 7),
      Row(children: [
        _sum('ASSIGNED', assigned, AppColors.blue), const SizedBox(width: 5),
        _sum('DELIVERED', delivered, AppColors.green), const SizedBox(width: 5),
        _sum('ON HOLD', hold, AppColors.orange),
      ]),
      const SizedBox(height: 7),
      TextField(controller: searchCtrl, onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 12), decoration: const InputDecoration(
          isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 9, horizontal: 9),
          prefixIcon: Icon(Icons.search, size: 18), prefixIconConstraints: BoxConstraints(minWidth: 32),
          hintText: 'Cari nama rider')),
      const SizedBox(height: 7),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        _filterChip('Semua', filter == null, () => setState(() => filter = null)),
        _filterChip('Driver', filter == RiderType.driverDedicated, () => setState(() => filter = RiderType.driverDedicated)),
        _filterChip('Plus', filter == RiderType.riderPlus, () => setState(() => filter = RiderType.riderPlus)),
        _filterChip('Dedicated', filter == RiderType.riderDedicated, () => setState(() => filter = RiderType.riderDedicated)),
      ])),
      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [
        Text('DAFTAR RIDER (${visible.length}/${rows.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.navy)),
        const Spacer(), const Text('ASS | DEL | HOLD | % | TARGET', style: TextStyle(fontSize: 9, color: AppColors.muted)),
      ])),
      if (loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      if (loadError != null) Text('Server: $loadError', style: const TextStyle(color: AppColors.red, fontSize: 12)),
      if (rows.isEmpty && !loading) Padding(padding: const EdgeInsets.all(14), child: Text(
        DailyControlApi.isReady ? 'Tidak ada data dari API untuk tanggal/periode ini.' : 'Belum ada data contoh untuk tanggal/periode ini. Data asli harus dibaca dari Google Sheets melalui API.',
        style: const TextStyle(fontSize: 12, color: AppColors.muted))),
      for (final r in visible) _row(r),
      const SizedBox(height: 6),
      if (!DailyControlApi.isReady) const Text('Angka di atas hanya contoh 13 Nov 2026. Warna dan urutan rider mengikuti referensi spreadsheet; bukan data live.',
        style: TextStyle(fontSize: 10, color: AppColors.muted)),
    ]);
  }

  Widget _sum(String label, int n, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: .11), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
      Text('$n', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color))]),
  ));

  Widget _filterChip(String name, bool selected, VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(right: 5), child: InkWell(onTap: tap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: selected ? AppColors.navy : Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1))),
      child: Text(name, style: TextStyle(fontSize: 10.5, color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700)),
    )));

  Widget _row(DeliveryRow r) {
    final off = r.assigned == 0;
    final achColor = off ? const Color(0xFFB78B8B) : r.achievement >= 100 ? const Color(0xFF9FD8B5) : const Color(0xFFEE5757);
    final rateColor = off ? AppColors.muted : r.rate < 85 ? AppColors.red : r.rate < 100 ? const Color(0xFFAF6A00) : AppColors.green;
    return Container(margin: const EdgeInsets.only(bottom: 3),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFDBE1EB)), borderRadius: BorderRadius.circular(5)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(width: 5, decoration: BoxDecoration(color: riderTypeColor(r.group), borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)))),
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(7, 5, 5, 5), child: Column(children: [
          Row(children: [
            Expanded(child: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppColors.navy))),
            Container(minWidth: 63, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: achColor, borderRadius: BorderRadius.circular(3)),
              child: Text(off ? (r.offLabel.isEmpty ? 'LIBUR' : r.offLabel) : '${r.achievement.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: off ? 9.5 : 10, fontWeight: FontWeight.w900,
                  color: off ? AppColors.ink : r.achievement >= 100 ? const Color(0xFF0F4D29) : Colors.white))),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            _metric('ASS', '${r.assigned}', AppColors.navy),
            _metric('DEL', '${r.delivered}', AppColors.green),
            _metric('HOLD', '${r.hold}', AppColors.orange),
            _metric('%', '${r.rate.toStringAsFixed(1)}%', rateColor),
            _metric('TGT', '${r.target}', AppColors.navy),
          ]),
        ]))),
      ]));
  }

  Widget _metric(String title, String value, Color color) => Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text('$title ', style: const TextStyle(fontSize: 8.3, color: AppColors.muted)),
    Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: color))),
  ]));
}
