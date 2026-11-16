import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/app_theme.dart';
import '../widgets/sync_notice.dart';

/// View ringan untuk tabel besar Google Sheets; tidak memakai angka contoh.
class LiveSheetView extends StatefulWidget {
  const LiveSheetView({super.key, required this.path, required this.title});
  final String path;
  final String title;
  @override
  State<LiveSheetView> createState() => _LiveSheetViewState();
}

class _LiveSheetViewState extends State<LiveSheetView> {
  bool loading = false;
  String? problem;
  int page = 0;
  bool next = false;
  List<List<String>> rows = [];
  String search = '';

  @override
  void initState() {super.initState(); if (DailyControlApi.isReady) _load();}
  Future<void> _load({bool reset = false}) async {
    if (!DailyControlApi.isReady) return;
    if (reset) page = 0;
    setState(() {loading = true; problem = null;});
    try {
      final data = await DailyControlApi.get(widget.path, {'page':'$page','limit':'60'});
      final loaded = <List<String>>[];
      for (final line in (data['rows'] as List? ?? const [])) {
        loaded.add([for (final cell in (line as List)) '${cell ?? ''}']);
      }
      if (mounted) setState(() {rows = loaded; next = data['hasNext'] == true;});
    } catch (e) {
      if (mounted) setState(() => problem = '$e');
    } finally {if (mounted) setState(() => loading = false);}
  }

  Color shade(String s, int rowIndex) {
    final value = s.toLowerCase();
    if (value.contains('delivered') && !value.contains('un')) return const Color(0xFFD3F4DA);
    if (value.contains('on hold') || value.contains('onhold')) return const Color(0xFFFFE9C5);
    if (value.contains('delivering')) return const Color(0xFFD8E9FF);
    if (value.contains('belum') || value.contains('stuck')) return const Color(0xFFFFDEDE);
    return rowIndex.isEven ? const Color(0xFFF2F6FC) : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = rows.where((row) => row.join(' ').toLowerCase().contains(search.toLowerCase())).toList();
    final width = (rows.isEmpty ? 8 : rows.map((e) => e.length).reduce((a,b) => a>b?a:b));
    return ListView(padding: const EdgeInsets.all(10), children: [
      const SyncNotice(),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))),
        IconButton(onPressed: loading ? null : () => _load(reset: true), icon: const Icon(Icons.refresh), tooltip: 'Refresh Sheets'),
      ]),
      TextField(decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search, size: 19),
        hintText: 'Cari data dalam halaman'), onChanged: (v) => setState(() => search = v)),
      if (loading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
      if (problem != null) Text(problem!, style: const TextStyle(color: Colors.red, fontSize: 11)),
      if (!DailyControlApi.isReady) const Padding(padding: EdgeInsets.all(20),
        child: Text('Hubungkan Gateway pada menu Koneksi. Data contoh tidak ditampilkan.')),
      if (DailyControlApi.isReady && rows.isEmpty && !loading) const Padding(padding: EdgeInsets.all(20),
        child: Text('Tidak ada baris yang dikirim oleh spreadsheet.')),
      if (rows.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text('Halaman ${page+1} • ${rows.length} baris • geser tabel ke samping',
          style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 5),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (int r=0;r<filtered.length;r++)
              Row(children: [for(int c=0;c<width;c++) Container(
                width: c==0 ? 160 : 106,
                constraints: const BoxConstraints(minHeight: 30),
                padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 5),
                decoration: BoxDecoration(color:shade(c<filtered[r].length?filtered[r][c]:'',r),
                  border: Border.all(color: const Color(0xFFE0E6ED),width: .5)),
                child: Text(c<filtered[r].length ? filtered[r][c] : '',
                  maxLines:2,overflow:TextOverflow.ellipsis,style: const TextStyle(fontSize:10)),
              ))],
          ])),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
          OutlinedButton(onPressed: loading || page==0 ? null : () {page--; _load();},child: const Text('Sebelumnya')),
          OutlinedButton(onPressed: loading || !next ? null : () {page++; _load();},child: const Text('Berikutnya')),
        ]),
      ],
    ]);
  }
}
