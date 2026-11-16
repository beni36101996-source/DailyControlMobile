import 'package:flutter/material.dart';
import '../core/control_store.dart';
import '../core/app_theme.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';

Color riderTypeColor(RiderType type) => switch (type) {
  RiderType.driverDedicated => const Color(0xFFB7A6CF),
  RiderType.riderPlus => const Color(0xFF48B9C2),
  RiderType.riderDedicated => const Color(0xFFFFE600),
};

class HolidayView extends StatefulWidget {
  const HolidayView({super.key});
  @override
  State<HolidayView> createState() => _HolidayViewState();
}

class _HolidayViewState extends State<HolidayView> {
  final store = DailyControlStore.instance;
  bool saving = false;
  @override void initState() { super.initState(); if (store.isLive) store.refreshHolidays(); }

  Future<void> _editHoliday([HolidayAssignment? original]) async {
    final name = TextEditingController(text: original?.name ?? '');
    String day = original?.day ?? dcWeekdays.first;
    RiderType type = original?.type ?? RiderType.riderDedicated;
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      showDragHandle: true, builder: (sheetContext) => StatefulBuilder(builder: (ctx, change) =>
      Padding(padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(original == null ? 'Tambah jadwal libur' : 'Edit jadwal libur', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(controller: name, textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Nama rider / driver')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: day, isExpanded: true, decoration: const InputDecoration(labelText: 'Hari libur'),
              items: [for (final d in dcWeekdays) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) => change(() => day = v!)),
            const SizedBox(height: 12),
            DropdownButtonFormField<RiderType>(value: type, isExpanded: true, decoration: const InputDecoration(labelText: 'Kategori (menentukan warna)'),
              items: [for (final g in RiderType.values) DropdownMenuItem(value: g, child: Row(children: [
                Container(width: 16, height: 16, color: riderTypeColor(g)), const SizedBox(width: 8), Text(g.label)]))],
              onChanged: (v) => change(() => type = v!)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: () { if (name.text.trim().isEmpty) return; Navigator.pop(ctx, true); },
              icon: const Icon(Icons.save_outlined), label: const Text('Simpan')),
            if (original != null) TextButton.icon(onPressed: () => Navigator.pop(ctx, false), icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus rider dari jadwal', style: TextStyle(color: AppColors.red))),
          ])))));
    if (!mounted) {name.dispose(); return;}
    final selectedName = name.text.trim().toUpperCase();
    name.dispose();
    if (result == null) return;
    try {
      setState(() => saving = true);
      if (result == false && original != null) {
        await store.removeHoliday(original);
      } else if (result == true && selectedName.isNotEmpty) {
        await store.putHoliday(HolidayAssignment(
          id: original?.id ?? DateTime.now().microsecondsSinceEpoch,
          day: day, name: selectedName, type: type), previous: original);
      }
      if (mounted) showFeedback(context, store.isLive ? 'Perubahan dikonfirmasi server.' : 'Tersimpan di HP. Spreadsheet belum berubah.');
    } catch (e) { if (mounted) showFeedback(context, 'Gagal menyimpan: $e'); }
    finally { if (mounted) setState(() => saving = false); }
  }

  Future<void> _editNote([HolidayNote? original]) async {
    final name = TextEditingController(text: original?.name ?? '');
    final start = TextEditingController(text: original?.start ?? '');
    final end = TextEditingController(text: original?.end ?? '');
    final reason = TextEditingController(text: original?.reason ?? 'Cuti');
    final result = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      showDragHandle: true, builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 0, 18, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Catatan cuti / izin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama rider')),
            const SizedBox(height: 9),
            TextField(controller: start, decoration: const InputDecoration(labelText: 'Mulai (YYYY-MM-DD)')),
            const SizedBox(height: 9),
            TextField(controller: end, decoration: const InputDecoration(labelText: 'Selesai (YYYY-MM-DD)')),
            const SizedBox(height: 9),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Keterangan')),
            const SizedBox(height: 13),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan catatan')),
            if (original != null) TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hapus catatan')),
          ]))));
    if (!mounted) {for (final c in [name,start,end,reason]) {c.dispose();} return;}
    final item = HolidayNote(id: original?.id ?? DateTime.now().microsecondsSinceEpoch,
      name: name.text.trim().toUpperCase(), start: start.text.trim(), end: end.text.trim(), reason: reason.text.trim());
    for (final c in [name,start,end,reason]) { c.dispose(); }
    if (result == null) return;
    try {
      if (result == true) {
        if (item.name.isEmpty) {showFeedback(context, 'Nama wajib diisi.'); return;}
        await store.putNote(item);
      } else if (original != null) {
        await store.removeNote(original);
      }
      if (mounted) showFeedback(context, store.isLive ? 'Catatan dikonfirmasi server.' : 'Catatan tersimpan di HP (belum ke Spreadsheet).');
    } catch (e) {if (mounted) showFeedback(context, 'Gagal: $e');}
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (context, _) =>
    ListView(padding: const EdgeInsets.fromLTRB(10, 10, 10, 24), children: [
      const SyncNotice(), const SizedBox(height: 10),
      Row(children: [const Expanded(child: Text('Jadwal Libur Mingguan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        FilledButton.tonalIcon(onPressed: saving ? null : () => _editHoliday(),
          icon: const Icon(Icons.add, size: 17), label: const Text('Tambah'))]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 7, children: [
        _legend(RiderType.driverDedicated), _legend(RiderType.riderPlus), _legend(RiderType.riderDedicated),
      ]), const SizedBox(height: 11),
      for (final day in dcWeekdays) ...[
        Container(margin: const EdgeInsets.only(bottom: 7), padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDEE5EF))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(day, style: const TextStyle(color: AppColors.blue, fontSize: 14, fontWeight: FontWeight.w900))),
              Text('${store.holidays.where((e) => e.day == day).length} orang', style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
            const SizedBox(height: 6),
            Wrap(spacing: 5, runSpacing: 5, children: [for (final r in store.holidays.where((x) => x.day == day))
              InkWell(onTap: () => _editHoliday(r), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: riderTypeColor(r.type), borderRadius: BorderRadius.circular(5)),
                child: Text(r.name, style: const TextStyle(color: Color(0xFF12243E), fontSize: 10.5, fontWeight: FontWeight.w800)),
              )),
            ]),
          ])),
      ],
      const SizedBox(height: 7),
      Row(children: [const Expanded(child: Text('Catatan Cuti / Izin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
        TextButton.icon(onPressed: () => _editNote(), icon: const Icon(Icons.add, size: 16), label: const Text('Tambah'))]),
      for (final note in store.notes) InkWell(onTap: () => _editNote(note), child: Container(
        margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFFF4C5), borderRadius: BorderRadius.circular(9)),
        child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text('${note.start} s.d. ${note.end} • ${note.reason}', style: const TextStyle(fontSize: 11)),
        ])), const Icon(Icons.edit_outlined, size: 16)]))),
    ]));

  Widget _legend(RiderType type) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 11, height: 11, decoration: BoxDecoration(color: riderTypeColor(type), border: Border.all(color: Colors.black12))),
    const SizedBox(width: 4), Text(type.label, style: const TextStyle(fontSize: 10.5)),
  ]);
}
