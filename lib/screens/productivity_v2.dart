import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../core/control_store.dart';
import '../widgets/sync_notice.dart';
import '../widgets/ui.dart';

class ProductivityView extends StatefulWidget {
  const ProductivityView({super.key});
  @override
  State<ProductivityView> createState() => _ProductivityViewState();
}

class _ProductivityViewState extends State<ProductivityView> {
  final store = DailyControlStore.instance;
  DateTime month = DateTime(2026, 11);
  static const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  bool saving = false;
  String get monthName => '${months[month.month - 1]} ${month.year}';

  Future<void> _editTarget() async {
    final ctrl = TextEditingController(text: store.dailyProductivityTarget.toStringAsFixed(0));
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Target Productivity'),
      content: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Target paket / operator')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan'))]));
    final n = double.tryParse(ctrl.text.replaceAll(',', '.'));
    ctrl.dispose();
    if (ok == true && n != null && n > 0) {
      try {await store.setProductivityTarget(n); if (mounted) showFeedback(context, store.isLive ? 'Target dikonfirmasi server.' : 'Target tersimpan lokal di HP.');}
      catch (e) {if (mounted) showFeedback(context, 'Gagal: $e');}
    }
  }

  Future<void> _editDay(DateTime date) async {
    final key = dcDateKey(date);
    final value = store.productivity[key] ?? ProductivityDay(date: key);
    final inCtrl = TextEditingController(text: value.inbound?.toString() ?? '');
    final opCtrl = TextEditingController(text: value.operators?.toString() ?? '');
    final outCtrl = TextEditingController(text: value.outbound?.toString() ?? '');
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true,
      showDragHandle: true, builder: (ctx) => Padding(padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Isi Productivity • ${dcDateShort(date)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _numberField(inCtrl, 'Actual LM Inbound'), const SizedBox(height: 9),
            _numberField(opCtrl, 'Operator Masuk'), const SizedBox(height: 9),
            _numberField(outCtrl, 'Actual LM Outbound'), const SizedBox(height: 12),
            const Text('Productivity, Gap ke Target, dan % dihitung otomatis dari input.',
              style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.save_outlined), label: const Text('Simpan Input Harian')),
          ]))));
    int? parse(String s) => s.trim().isEmpty ? null : int.tryParse(s.replaceAll('.', '').replaceAll(',', ''));
    final a = parse(inCtrl.text), b = parse(opCtrl.text), c = parse(outCtrl.text);
    for (final ctrl in [inCtrl, opCtrl, outCtrl]) {ctrl.dispose();}
    if (ok != true || !mounted) return;
    if ((a != null && a < 0) || (b != null && b < 0) || (c != null && c < 0)) {
      showFeedback(context, 'Angka tidak boleh negatif.'); return;
    }
    try {
      setState(() => saving = true);
      await store.putProductivity(ProductivityDay(date: key, inbound: a, operators: b, outbound: c));
      if (mounted) showFeedback(context, store.isLive ? 'Input berhasil dikonfirmasi server.' : 'Tersimpan lokal di HP. Google Sheets belum berubah.');
    } catch (e) {if (mounted) showFeedback(context, 'Gagal menyimpan: $e');}
    finally {if (mounted) setState(() => saving = false);}
  }

  Widget _numberField(TextEditingController ctrl, String label) => TextField(
    controller: ctrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label, hintText: 'Isi angka untuk tanggal ini'));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: store, builder: (context, _) {
    final days = DateTime(month.year, month.month + 1, 0).day;
    final entries = [for (var i = 1; i <= days; i++) store.productivity[dcDateKey(DateTime(month.year, month.month, i))]].whereType<ProductivityDay>().toList();
    final totalOut = entries.fold<int>(0, (v, e) => v + (e.outbound ?? 0));
    final totalOps = entries.fold<int>(0, (v, e) => v + (e.operators ?? 0));
    return ListView(padding: const EdgeInsets.fromLTRB(10, 10, 10, 24), children: [
      const SyncNotice(), const SizedBox(height: 10),
      Row(children: [IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)),
        Expanded(child: Text(monthName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
        IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right)),
        OutlinedButton(onPressed: _editTarget, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 9)),
          child: Text('Target ${store.dailyProductivityTarget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11))),
      ]),
      Row(children: [
        _summary('Outbound', totalOut.toString(), AppColors.green), const SizedBox(width: 5),
        _summary('Operator', '$totalOps', AppColors.purple), const SizedBox(width: 5),
        _summary('Hari terisi', '${entries.where((e) => e.outbound != null).length}/$days', AppColors.blue),
      ]), const SizedBox(height: 9),
      Row(children: [const Expanded(child: Text('INPUT PRODUCTIVITY PER TANGGAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5))),
        TextButton.icon(onPressed: () {
          final today = DateTime.now();
          setState(() => month = DateTime(today.year, today.month));
          _editDay(today);
        }, icon: const Icon(Icons.add_circle_outline, size: 17), label: const Text('Isi hari ini', style: TextStyle(fontSize: 12)))
      ]),
      for (var d = 1; d <= days; d++) _dayRow(DateTime(month.year, month.month, d)),
      const SizedBox(height: 5),
      const Text('Data contoh 1–10 Nov hanya untuk uji. Tap tanggal untuk mengisi/mengubah. Form menyimpan di HP sampai API Spreadsheet diaktifkan.',
        style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
    ]);
  });

  Widget _summary(String label, String value, Color color) => Expanded(child: Container(
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)),
    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 5), child: Column(children: [
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800)),
      Text(value, style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w900)),
    ])));

  Widget _dayRow(DateTime date) {
    final day = store.productivity[dcDateKey(date)];
    final p = day?.percent(store.dailyProductivityTarget);
    final color = p == null ? const Color(0xFF9AA5B1) : p < 85 ? AppColors.red : p < 100 ? const Color(0xFFE5A82A) : AppColors.green;
    return InkWell(onTap: saving ? null : () => _editDay(date), child: Container(
      margin: const EdgeInsets.only(bottom: 3), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: color, width: 4),
        top: const BorderSide(color: Color(0xFFE4EAF1)), right: const BorderSide(color: Color(0xFFE4EAF1)),
        bottom: const BorderSide(color: Color(0xFFE4EAF1))), borderRadius: BorderRadius.circular(4)),
      child: Row(children: [
        SizedBox(width: 55, child: Text('${date.day.toString().padLeft(2, '0')} ${months[date.month-1]}',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900))),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Operator ${day?.operators ?? '—'}  •  Out ${day?.outbound ?? '—'}  •  In ${day?.inbound ?? '—'}',
            style: const TextStyle(fontSize: 10.2)),
          const SizedBox(height: 2),
          Text('Productivity ${day?.productivity?.toStringAsFixed(1) ?? '—'}   |   Gap ${day?.gap(store.dailyProductivityTarget)?.toStringAsFixed(1) ?? '—'}',
            style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ])),
        Container(width: 63, padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(color: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(5)),
          child: Text(p == null ? 'BELUM ISI' : '${p.toStringAsFixed(1)}%',
            textAlign: TextAlign.center, style: TextStyle(fontSize: p == null ? 9 : 11, fontWeight: FontWeight.w900, color: color))),
        const SizedBox(width: 2), const Icon(Icons.edit_outlined, size: 15, color: AppColors.blue),
      ])));
  }
}
