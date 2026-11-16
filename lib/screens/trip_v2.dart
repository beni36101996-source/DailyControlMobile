import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/control_store.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';

class TripView extends StatefulWidget {
  const TripView({super.key});
  @override State<TripView> createState() => _TripViewState();
}

class _TripViewState extends State<TripView> {
  final store = DailyControlStore.instance;
  DateTime date = DateTime.now();
  bool saving = false;
  @override void initState() { super.initState(); if (store.isLive) store.refreshTrips(); }
  String get key => dcDateKey(date);

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(context: context, initialDate: date,
      firstDate: DateTime(2025), lastDate: DateTime(2030));
    if (chosen != null) setState(() => date = chosen);
  }

  Future<void> _editTrip(int slot) async {
    final old = store.trips['${key}_$slot'] ?? TripSlot(date: key, slot: slot);
    final defs = <(String, String, String)>[
      ('tripId', 'Trip ID', old.tripId),
      ('estimateArrival', 'Estimate Arrival', old.estimateArrival),
      ('departureStation', 'Departure Station', old.departureStation),
      ('nextStation', 'Next To Station', old.nextStation),
      ('scheduleDeparture', 'Schedule Departure', old.scheduleDeparture),
      ('actualDeparture', 'Actual Departure', old.actualDeparture),
      ('actualArrival', 'Actual Arrival', old.actualArrival),
      ('status', 'Status (Arrived / Departed ...)', old.status),
      ('orderCount', 'TO (Order)', old.orderCount),
      ('packCount', 'TO Pack', old.packCount),
      ('vehicle', 'Nomor Kendaraan', old.vehicle),
      ('vehicleGroup', 'Vehicle Group Type', old.vehicleGroup),
      ('driver', 'Nama Driver', old.driver),
    ];
    final ctrls = {for (final d in defs) d.$1: TextEditingController(text: d.$3)};
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(15, 0, 15, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SizedBox(height: MediaQuery.sizeOf(ctx).height * .75,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Isi LH Trip • ${dcDateShort(date)} • Slot $slot', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Isi berdasarkan laporan Linehaul. Kolom kosong boleh dilewati.',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
            const SizedBox(height: 9),
            Expanded(child: ListView(children: [for (final item in defs) Padding(
              padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: ctrls[item.$1],
                decoration: InputDecoration(labelText: item.$2, isDense: true)))])),
            const SizedBox(height: 9),
            FilledButton.icon(onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.save_outlined), label: const Text('Simpan Slot Ini')),
          ]))));
    final fields = {for (final e in ctrls.entries) e.key: e.value.text.trim()};
    for (final c in ctrls.values) {c.dispose();}
    if (ok != true || !mounted) return;
    try {
      setState(() => saving = true);
      await store.putTrip(TripSlot(date: key, slot: slot,
        tripId: fields['tripId']!, estimateArrival: fields['estimateArrival']!,
        departureStation: fields['departureStation']!, nextStation: fields['nextStation']!,
        scheduleDeparture: fields['scheduleDeparture']!, actualDeparture: fields['actualDeparture']!,
        actualArrival: fields['actualArrival']!, status: fields['status']!, orderCount: fields['orderCount']!,
        packCount: fields['packCount']!, vehicle: fields['vehicle']!, vehicleGroup: fields['vehicleGroup']!, driver: fields['driver']!));
      if (mounted) showFeedback(context, store.isLive ? 'LH Trip dikonfirmasi server.' : 'LH Trip tersimpan lokal di HP. Belum masuk Spreadsheet.');
    } catch (e) {if (mounted) showFeedback(context, 'Gagal menyimpan: $e');}
    finally {if (mounted) setState(() => saving = false);}
  }

  @override Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (context, _) {
    final slots = [for (var i = 1; i <= 3; i++) store.trips['${key}_$i'] ?? TripSlot(date: key, slot: i)];
    final filled = slots.where((x) => x.hasData).length;
    return ListView(padding: const EdgeInsets.fromLTRB(10, 10, 10, 25), children: [
      const SyncNotice(), const SizedBox(height: 10),
      Row(children: [const Expanded(child: Text('New LH Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
        OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month, size: 17),
          label: Text(dcDateShort(date), style: const TextStyle(fontSize: 11)))]),
      const SizedBox(height: 9),
      Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: const Color(0xFFE3EEF9), borderRadius: BorderRadius.circular(9)),
        child: Row(children: [const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.blue), const SizedBox(width: 8),
          Expanded(child: Text('Terisi $filled / 3 slot • Pilih tanggal, lalu tekan Isi / Edit untuk memasukkan laporan.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))])),
      const SizedBox(height: 10),
      for (final t in slots) Container(
        margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCE5F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFECD6), borderRadius: BorderRadius.circular(14)),
            child: Text('SLOT ${t.slot}', style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w900))),
            const SizedBox(width: 7),
            Expanded(child: Text(t.tripId.isEmpty ? 'Trip ID belum diisi' : t.tripId,
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12))),
            TextButton.icon(onPressed: saving ? null : () => _editTrip(t.slot),
              icon: const Icon(Icons.edit_outlined, size: 15), label: const Text('Isi / Edit', style: TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 5),
          Row(children: [Expanded(child: _entry('Estimate', t.estimateArrival)),
            Expanded(child: _entry('Arrival', t.actualArrival)), Expanded(child: _entry('Status', t.status))]),
          const SizedBox(height: 5),
          Row(children: [Expanded(child: _entry('TO Order', t.orderCount)),
            Expanded(child: _entry('Kendaraan', t.vehicle)), Expanded(child: _entry('Driver', t.driver))]),
          if (t.departureStation.isNotEmpty || t.nextStation.isNotEmpty) Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text('${t.departureStation} → ${t.nextStation}', maxLines: 1,
              overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.muted))),
        ])),
      const Text('Tanggal dan slot dapat diedit setiap hari. Data masih contoh/lokal sampai autentikasi API Daily Control tersambung.',
        style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
    ]);
  });

  Widget _entry(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
    Text(value.isEmpty ? '—' : value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
  ]);
}
