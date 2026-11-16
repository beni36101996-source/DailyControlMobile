import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import '../core/app_theme.dart';

/// Only riders explicitly marked X are considered "belum mengisi", matching
/// BotRiderKemuning.gs. Empty values mean "belum tersedia", not "X".
class PretripMissingScreen extends StatefulWidget {
  const PretripMissingScreen({super.key});

  @override
  State<PretripMissingScreen> createState() => _PretripMissingScreenState();
}

class _PretripMissingScreenState extends State<PretripMissingScreen> {
  List<String> names = const [];
  String sourceDate = '';
  int fit = 0;
  int unfit = 0;
  int unknown = 0;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!DailyControlApi.isReady) {
      setState(() => error = 'Hubungkan Gateway lewat menu Koneksi terlebih dahulu.');
      return;
    }
    setState(() { loading = true; error = null; });
    try {
      final found = <String>[];
      var fits = 0;
      var unfits = 0;
      var empties = 0;
      var date = '';
      var page = 0;
      bool hasNext;
      do {
        final result = await DailyControlApi.get(
            '/v1/pretrip', {'page': '$page', 'limit': '100'});
        final rows = result['rows'];
        if (rows is! List) throw const FormatException('Data Pre-Trip bukan tabel.');
        for (final raw in rows) {
          if (raw is! List) continue;
          final cells = raw.map((x) => '${x ?? ''}'.trim()).toList();
          if (cells.length < 4) continue;
          if (page == 0 && cells[0].toLowerCase() == 'id courier') {
            date = cells[3];
            continue;
          }
          final id = cells[0], name = cells[1];
          if (id.isEmpty || name.isEmpty || id.toLowerCase() == 'last update' ||
              name.toLowerCase() == 'last update') continue;
          final status = cells[3].toUpperCase();
          if (status == 'X') {
            found.add(name);
          } else if (status == 'FIT') {
            fits++;
          } else if (status == 'UN FIT' || status == 'UNFIT') {
            unfits++;
          } else {
            empties++;
          }
        }
        hasNext = result['hasNext'] == true;
        page++;
        if (page > 25) {
          throw StateError('Data terlalu panjang; hentikan agar tidak menampilkan hasil sebagian.');
        }
      } while (hasNext);
      if (mounted) setState(() {
        names = found;
        sourceDate = date;
        fit = fits;
        unfit = unfits;
        unknown = empties;
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _copy() async {
    if (names.isEmpty) return;
    final text = <String>[
      'PRE-TRIP — BELUM MENGISI${sourceDate.isEmpty ? '' : ' ($sourceDate)'}',
      for (var i = 0; i < names.length; i++) '${i + 1}. ${names[i]}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Daftar nama yang belum mengisi sudah disalin.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pre-Trip — Belum Isi')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Row(children: [
                const Expanded(child: Text('Siapa yang belum mengisi?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
                IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh),
                    onPressed: loading ? null : _refresh),
              ]),
              Text('Tanggal sumber: ${sourceDate.isEmpty ? 'Belum tersedia' : sourceDate}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 10),
              if (loading) const LinearProgressIndicator(),
              if (error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(error!, style: const TextStyle(color: Colors.red))),
              if (error == null) ...[
                Row(children: [
                  Expanded(child: _Count('Belum isi (X)', '${names.length}', AppColors.red)),
                  const SizedBox(width: 7),
                  Expanded(child: _Count('Fit', '$fit', AppColors.green)),
                  const SizedBox(width: 7),
                  Expanded(child: _Count('Unfit', '$unfit', AppColors.orange)),
                ]),
                if (unknown > 0) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('$unknown status belum tersedia; tidak dihitung sebagai X.',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
                const SizedBox(height: 10),
                if (names.isEmpty && !loading) const Card(child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Text('Tidak ada rider dengan status X pada tanggal sumber tersebut.'),
                )),
                for (var i = 0; i < names.length; i++) Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('${i + 1}. ${names[i]}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                ),
                const SizedBox(height: 10),
                if (names.isNotEmpty) FilledButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin daftar nama saja'),
                ),
                const SizedBox(height: 8),
                const Text('Status X = belum mengisi menurut aturan BotRiderKemuning. '
                    'Data berasal dari PRE TRIP RIDER; jika tanggal belum terbaru, tunggu pembaruan sumber.',
                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ],
          ),
        ),
      );
}

class _Count extends StatelessWidget {
  const _Count(this.title, this.value, this.color);
  final String title, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withValues(alpha: .09),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(11)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    ]),
  );
}
