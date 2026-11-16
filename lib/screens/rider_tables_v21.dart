import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/control_store.dart';
import '../widgets/sync_notice.dart';

class RiderTableV21 extends StatefulWidget {
  const RiderTableV21({super.key, required this.isTarget});
  final bool isTarget;
  @override
  State<RiderTableV21> createState() => _RiderTableV21State();
}

class _RiderTableV21State extends State<RiderTableV21> {
  bool loading = false;
  String? failure;
  List<Map<String, dynamic>>? remote;
  List<Map<String, dynamic>> targetDetails = const [];
  String group = 'Rider Plus';
  String targetForGroup = ''; 
  DateTime date = DateTime.now();
  String search = '';
  static const groups = ['Rider Plus', 'Rider Dedicated', 'Driver Dedicated'];

  @override
  void initState() { super.initState(); if (DailyControlApi.isReady) _load(); }

  Future<void> _load() async {
    setState(() {loading = true; failure = null;});
    try {
      final path = widget.isTarget ? '/v1/target-rider' : '/v1/daily-active';
      final reply = await DailyControlApi.get(path, {'date': dcDateKey(date), if(widget.isTarget) 'group': group});
      final rows = reply['rows'];
      if (rows is! List) throw const FormatException('Respons API tidak berisi rows.');
      final details = <Map<String, dynamic>>[];
      if (widget.isTarget && reply['detail'] is List) {
        for (final raw in reply['detail'] as List) {
          final line = (raw as List).map((x) => x?.toString() ?? '').toList();
          if (line.length < 14 || line[1].trim().isEmpty || line[1].toUpperCase() == 'NAMA RIDER') continue;
          details.add({'name': line[1], 'type': line[2], 'sen': line[3], 'sel': line[4],
            'rab': line[5], 'kam': line[6], 'jum': line[7], 'sab': line[8], 'min': line[9],
            'active': line[10], 'target': line[11], 'gap': line[12], 'status': line[13]});
        }
      }
      final selectedTarget = widget.isTarget && reply['targets'] is List
        ? (reply['targets'] as List).where((e) => (e as Map)['group'] == group).toList()
        : const [];
      if (mounted) setState(() {
        targetForGroup = selectedTarget.isEmpty ? '' : '${(selectedTarget.first as Map)['target']}';
        remote = [for (final x in rows) Map<String, dynamic>.from(x as Map)];
        targetDetails = details;
      });
    } catch (e) {if(mounted) setState(() {failure = '$e'; remote = null;});}
    finally {if(mounted) setState(() => loading = false);}
  }

  Future<void> _editTarget() async {
    if (!DailyControlApi.canWrite) return;
    final controller = TextEditingController(text: targetForGroup);
    final submitted = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Target $group'),
      content: TextField(controller: controller, keyboardType: TextInputType.number,
        decoration: const InputDecoration(labelText: 'Parcel / orang / hari')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Simpan'))],
    ));
    controller.dispose();
    if (submitted == null || !mounted) return;
    final target = int.tryParse(submitted);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Target harus angka positif.')));
      return;
    }
    setState(() => loading = true);
    try {
      await DailyControlApi.action('target-rider-target', {'group':group, 'target':target});
      await _load();
    } catch(e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {if (mounted) setState(() => loading = false);}
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(context: context, initialDate: date,
      firstDate: DateTime(2025), lastDate: DateTime(2031));
    if (selected != null) {
      setState(() {date = selected; remote = null;});
      if (DailyControlApi.isReady) await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = remote ?? (DailyControlApi.isReady ? <Map<String, dynamic>>[] :
      widget.isTarget ? _targetExamples(group) : _activeExamples());
    final filtered = rows.where((r) => '${r['name'] ?? ''}'.toLowerCase().contains(search.toLowerCase())).toList();
    return ListView(padding: const EdgeInsets.fromLTRB(8,8,8,24), children: [
      const SyncNotice(),
      const SizedBox(height: 7),
      Row(children: [
        Expanded(child: Text(widget.isTarget ? 'Target Produktivitas Mingguan' : 'Daily Active — Monitoring Rider',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
        OutlinedButton.icon(onPressed: _chooseDate, icon: const Icon(Icons.calendar_today, size: 14),
          label: Text(dcDateShort(date), style: const TextStyle(fontSize: 10))),
        if (DailyControlApi.isReady) IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh)),
      ]),
      if (widget.isTarget) ...[
        const SizedBox(height: 5),
        SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: Row(children: [for(final g in groups)
            Padding(padding: const EdgeInsets.only(right: 5), child: ChoiceChip(
              visualDensity: VisualDensity.compact, label: Text(g, style: const TextStyle(fontSize: 10)),
              selected: g == group, onSelected: (_) {setState(() {group = g; remote = null;}); if (DailyControlApi.isReady) _load();},
            ))])),
      ],
      if (widget.isTarget && DailyControlApi.isReady) Padding(
        padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
          Expanded(child: Text('Target $group: $targetForGroup parcel/orang/hari',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
          if (DailyControlApi.canWrite) TextButton.icon(
            onPressed: loading ? null : _editTarget, icon: const Icon(Icons.edit, size: 15),
            label: const Text('Edit target')),
        ])),
      const SizedBox(height: 5),
      TextField(onChanged: (v) => setState(() => search = v),
        decoration: const InputDecoration(isDense: true, prefixIcon: Icon(Icons.search, size: 18),
          hintText: 'Cari rider / driver', contentPadding: EdgeInsets.symmetric(vertical: 8))),
      if (loading) const LinearProgressIndicator(),
      if (failure != null) Padding(padding: const EdgeInsets.all(6), child: Text('Gagal membaca server: $failure', style: const TextStyle(fontSize: 11, color: Colors.red))),
      if (!DailyControlApi.isReady) const Padding(padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('DATA CONTOH — tabel ini belum membaca Spreadsheet.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF945E00)))),
      const SizedBox(height: 5),
      widget.isTarget ? _targetTable(filtered) : _activeTable(filtered),
      if (widget.isTarget && targetDetails.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('DAFTAR RIDER SESUAI SPREADSHEET', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
        const SizedBox(height: 6),
        _targetRiderTable(targetDetails.where((r) => '${r['name']}'.toLowerCase().contains(search.toLowerCase())).toList()),
      ],
      if(filtered.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada data untuk pilihan ini.'))),
    ]);
  }

  Widget _targetTable(List<Map<String, dynamic>> rows) => Column(children: [
    _headerRow(['Hari', 'Active', 'Target', 'Actual', 'Gap', 'Status'], [3,2,2,2,2,3]),
    for (int i=0; i<rows.length; i++) _dataRow([
      '${rows[i]['day'] ?? ''}', '${rows[i]['active'] ?? '-'}', '${rows[i]['target'] ?? '-'}',
      '${rows[i]['actual'] ?? '-'}', '${rows[i]['gap'] ?? '-'}', '${rows[i]['status'] ?? '-'}',
    ], [3,2,2,2,2,3], i, lastIsStatus: true),
  ]);

  Widget _activeTable(List<Map<String, dynamic>> rows) => Column(children: [
    _headerRow(['Nama Rider', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min', 'Avg'], [7,2,2,2,2,2,2,2,3]),
    for (int i=0; i<rows.length; i++) _dataRow([
      '${rows[i]['name'] ?? ''}', ...['sen','sel','rab','kam','jum','sab','min'].map((k) => '${rows[i][k] ?? '-'}'),
      '${rows[i]['average'] ?? '-'}',
    ], [7,2,2,2,2,2,2,2,3], i, isActive: true),
  ]);

  Widget _targetRiderTable(List<Map<String, dynamic>> rows) => Column(children: [
    _headerRow(['Nama Rider', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min', 'Target', 'Status'], [7,2,2,2,2,2,2,2,3,4]),
    for (int i = 0; i < rows.length; i++) _dataRow([
      '${rows[i]['name'] ?? ''}',
      ...['sen','sel','rab','kam','jum','sab','min'].map((k) => '${rows[i][k] ?? '-'}'),
      '${rows[i]['target'] ?? '-'}', '${rows[i]['status'] ?? '-'}',
    ], [7,2,2,2,2,2,2,2,3,4], i, isActive: true),
  ]);

  Widget _headerRow(List<String> texts, List<int> sizes) => Row(children: [
    for (int j=0;j<texts.length;j++) Expanded(flex:sizes[j], child: Container(
      alignment: j == 0 ? Alignment.centerLeft : Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 9),
      color: const Color(0xFF16365C), child: Text(texts[j], maxLines:1, overflow:TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white))))
  ]);

  Widget _dataRow(List<String> cells, List<int> sizes, int rowIndex, {bool isActive=false, bool lastIsStatus=false}) =>
    Row(children: [for(int j=0;j<cells.length;j++) Expanded(flex:sizes[j], child: Container(
      constraints: const BoxConstraints(minHeight: 35), alignment: j == 0 ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(color: _cellColor(cells[j], j, rowIndex, isActive, lastIsStatus),
        border: const Border(bottom: BorderSide(color: Color(0xFFD5DEE8), width: .65))),
      child: Text(cells[j], maxLines: j==0 ? 2 : 1, overflow:TextOverflow.ellipsis,
        textAlign:j==0?TextAlign.left:TextAlign.center, style:TextStyle(fontSize:j==0?9.5:9,
          fontWeight:j==0?FontWeight.w700:FontWeight.w600, color:const Color(0xFF173253))),
    ))]);

  Color _cellColor(String value, int index, int row, bool active, bool status) {
    if (active && index>0 && index<8) {
      switch(value.toUpperCase()) {
        case 'M': return const Color(0xFFDCF1DD);
        case 'L': return const Color(0xFFE7DEF5);
        case 'LM': return const Color(0xFFFFEDC8);
        case 'SM': return const Color(0xFFFADBDC);
      }
    }
    if (status && index==5) {
      if (value.toUpperCase() == 'CAPAI') return const Color(0xFFBFEBD2);
      if(value == 'BELUM CAPAI') return const Color(0xFFFFD8D8);
    }
    return row.isEven ? const Color(0xFFF4F7FB) : Colors.white;
  }
}

List<Map<String, dynamic>> _targetExamples(String group) {
  if(group=='Rider Plus') return [
    {'name':'Rider Plus','day':'Senin','active':5,'target':550,'actual':767,'gap':217,'status':'CAPAI'},
    {'name':'Rider Plus','day':'Selasa','active':5,'target':550,'actual':498,'gap':-52,'status':'BELUM CAPAI'},
    {'name':'Rider Plus','day':'Rabu','active':4,'target':440,'actual':470,'gap':30,'status':'CAPAI'},
    {'name':'Rider Plus','day':'Kamis','active':5,'target':550,'actual':452,'gap':-98,'status':'BELUM CAPAI'},
  ];
  return <Map<String, dynamic>>[];
}

List<Map<String, dynamic>> _activeExamples() => [
  {'name':'MUHAMMAD WANDA ARYA','sen':'M','sel':'M','rab':'L','kam':'M','jum':'M','sab':'M','min':'L','average':'83%'},
  {'name':'ADRIAN KUSWONDO','sen':'M','sel':'M','rab':'M','kam':'M','jum':'L','sab':'M','min':'M','average':'100%'},
  {'name':'TRI IRWAN','sen':'M','sel':'M','rab':'L','kam':'M','jum':'M','sab':'M','min':'L','average':'83%'},
  {'name':'FIQI ARIANTO','sen':'M','sel':'M','rab':'M','kam':'M','jum':'M','sab':'LM','min':'M','average':'117%'},
  {'name':'ISMAIL','sen':'M','sel':'M','rab':'M','kam':'L','jum':'M','sab':'M','min':'M','average':'100%'},
];
