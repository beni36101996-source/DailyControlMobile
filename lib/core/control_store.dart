import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

String dcDateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String dcDateShort(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

const dcWeekdays = <String>['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

enum RiderType { driverDedicated, riderPlus, riderDedicated }
extension RiderTypeLabel on RiderType {
  String get label => switch (this) {
    RiderType.driverDedicated => 'Driver Dedicated',
    RiderType.riderPlus => 'Rider Plus',
    RiderType.riderDedicated => 'Rider Dedicated',
  };
}

class HolidayAssignment {
  HolidayAssignment({required this.id, required this.day, required this.name, required this.type});
  final int id;
  final String day;
  final String name;
  final RiderType type;
  Map<String, dynamic> toJson() => {'id': id, 'day': day, 'name': name, 'type': type.name};
  factory HolidayAssignment.fromJson(Map<String, dynamic> map) => HolidayAssignment(
    id: (map['id'] as num?)?.toInt() ?? 0,
    day: (map['day'] ?? 'Senin').toString(),
    name: (map['name'] ?? '').toString(),
    type: RiderType.values.firstWhere((e) => e.name == map['type'], orElse: () => RiderType.riderDedicated),
  );
}

class HolidayNote {
  HolidayNote({required this.id, required this.name, required this.start, required this.end, required this.reason});
  final int id;
  final String name, start, end, reason;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'start': start, 'end': end, 'reason': reason};
  factory HolidayNote.fromJson(Map<String, dynamic> x) => HolidayNote(
    id: (x['id'] as num?)?.toInt() ?? 0,
    name: (x['name'] ?? '').toString(), start: (x['start'] ?? '').toString(),
    end: (x['end'] ?? '').toString(), reason: (x['reason'] ?? '').toString(),
  );
}

class ProductivityDay {
  ProductivityDay({required this.date, this.inbound, this.operators, this.outbound});
  final String date;
  final int? inbound, operators, outbound;
  double? get productivity => operators == null || operators! <= 0 || outbound == null ? null : outbound! / operators!;
  double? percent(double target) => productivity == null || target <= 0 ? null : productivity! / target * 100;
  double? gap(double target) => productivity == null ? null : productivity! - target;
  Map<String, dynamic> toJson() => {'date': date, 'inbound': inbound, 'operators': operators, 'outbound': outbound};
  factory ProductivityDay.fromJson(Map<String, dynamic> x) => ProductivityDay(
    date: (x['date'] ?? '').toString(), inbound: (x['inbound'] as num?)?.toInt(),
    operators: (x['operators'] as num?)?.toInt(), outbound: (x['outbound'] as num?)?.toInt(),
  );
}

class TripSlot {
  TripSlot({required this.date, required this.slot, this.tripId = '', this.estimateArrival = '',
    this.departureStation = 'Batang Gansal Hub', this.nextStation = 'Kemuning Riau Hub',
    this.scheduleDeparture = '', this.actualDeparture = '', this.actualArrival = '',
    this.status = '', this.orderCount = '', this.packCount = '',
    this.vehicle = '', this.vehicleGroup = '', this.driver = ''});
  final String date;
  final int slot;
  final String tripId, estimateArrival, departureStation, nextStation, scheduleDeparture,
      actualDeparture, actualArrival, status, orderCount, packCount, vehicle, vehicleGroup, driver;
  bool get hasData => tripId.isNotEmpty || actualArrival.isNotEmpty || orderCount.isNotEmpty;
  Map<String, dynamic> toJson() => {
    'date': date, 'slot': slot, 'tripId': tripId, 'estimateArrival': estimateArrival,
    'departureStation': departureStation, 'nextStation': nextStation,
    'scheduleDeparture': scheduleDeparture, 'actualDeparture': actualDeparture,
    'actualArrival': actualArrival, 'status': status, 'orderCount': orderCount,
    'packCount': packCount, 'vehicle': vehicle, 'vehicleGroup': vehicleGroup, 'driver': driver,
  };
  factory TripSlot.fromJson(Map<String, dynamic> x) => TripSlot(
    date: (x['date'] ?? '').toString(), slot: (x['slot'] as num?)?.toInt() ?? 1,
    tripId: (x['tripId'] ?? '').toString(), estimateArrival: (x['estimateArrival'] ?? '').toString(),
    departureStation: (x['departureStation'] ?? 'Batang Gansal Hub').toString(),
    nextStation: (x['nextStation'] ?? 'Kemuning Riau Hub').toString(),
    scheduleDeparture: (x['scheduleDeparture'] ?? '').toString(),
    actualDeparture: (x['actualDeparture'] ?? '').toString(),
    actualArrival: (x['actualArrival'] ?? '').toString(), status: (x['status'] ?? '').toString(),
    orderCount: (x['orderCount'] ?? '').toString(), packCount: (x['packCount'] ?? '').toString(),
    vehicle: (x['vehicle'] ?? '').toString(), vehicleGroup: (x['vehicleGroup'] ?? '').toString(),
    driver: (x['driver'] ?? '').toString(),
  );
}

/// Local edits are intentionally distinguished from server-confirmed writes.
/// Configure a HTTPS authenticated API before any value can be synchronized to Sheets.
class DailyControlStore extends ChangeNotifier {
  DailyControlStore._();
  static final DailyControlStore instance = DailyControlStore._();
  SharedPreferences? _prefs;
  bool initialized = false;
  final Set<int> checkedTasks = {};
  List<String> liveTaskLabels = const [];
  bool tasksFromServer = false;
  List<HolidayAssignment> holidays = _seedHolidays();
  List<HolidayNote> notes = [HolidayNote(id: 1, name: 'ALFARIDZI FATURRAHMAN', start: '2026-10-25', end: '2026-11-01', reason: 'Cuti')];
  Map<String, ProductivityDay> productivity = _seedProductivity();
  Map<String, TripSlot> trips = _seedTrips();
  double dailyProductivityTarget = 952;
  String get syncLabel => DailyControlApi.isReady ? (DailyControlApi.canWrite ? 'Koneksi LIVE: data dari Spreadsheet' : 'Koneksi LIVE baca saja') : 'Belum terhubung ke Spreadsheet';
  bool get isLive => DailyControlApi.isReady;

  Future<void> initialize() async {
    if (initialized) return;
    _prefs = await SharedPreferences.getInstance();
    try {
      final tasks = _prefs!.getString('dc_v2_tasks');
      if (tasks != null) {
        checkedTasks..clear()..addAll((jsonDecode(tasks) as List).map((x) => (x as num).toInt()));
      }
      final savedHolidays = _prefs!.getString('dc_v2_holidays');
      if (savedHolidays != null) {
        holidays = (jsonDecode(savedHolidays) as List).map((x) => HolidayAssignment.fromJson(Map<String, dynamic>.from(x as Map))).toList();
      }
      final savedNotes = _prefs!.getString('dc_v2_notes');
      if (savedNotes != null) {
        notes = (jsonDecode(savedNotes) as List).map((x) => HolidayNote.fromJson(Map<String, dynamic>.from(x as Map))).toList();
      }
      final savedProductivity = _prefs!.getString('dc_v2_productivity');
      if (savedProductivity != null) {
        productivity = {for (final x in jsonDecode(savedProductivity) as List)
          (x as Map)['date'].toString(): ProductivityDay.fromJson(Map<String, dynamic>.from(x))};
      }
      final savedTrips = _prefs!.getString('dc_v2_trips');
      if (savedTrips != null) {
        trips = {for (final x in jsonDecode(savedTrips) as List)
          '${(x as Map)['date']}_${x['slot']}': TripSlot.fromJson(Map<String, dynamic>.from(x))};
      }
      dailyProductivityTarget = _prefs!.getDouble('dc_v2_target') ?? 952;
    } catch (e) {
      debugPrint('Local data could not be read; falling back to demo: $e');
    }
    initialized = true;
    notifyListeners();
  }

  Future<void> _write(String key, Object value) async {
    // Data LIVE tidak disalin ke SharedPreferences (plaintext).
    notifyListeners();
  }

  Future<void> clearLegacyDemo() async {
    _prefs ??= await SharedPreferences.getInstance();
    for (final key in ['dc_v2_tasks','dc_v2_holidays','dc_v2_notes',
      'dc_v2_productivity','dc_v2_target','dc_v2_trips']) {
      await _prefs!.remove(key);
    }
    checkedTasks.clear(); tasksFromServer = false; liveTaskLabels = const [];
    holidays = []; notes = []; productivity = {}; trips = {};
    notifyListeners();
  }

  /// When API is connected, require server confirmation *before* changing UI state.
  Future<void> _serverWrite(String endpoint, Map<String, dynamic> payload) async {
    if (!isLive) throw StateError('Belum terhubung. Data tidak disimpan ke Spreadsheet.');
    await DailyControlApi.action(endpoint, payload);
  }

  /// Always refresh server-owned daily tasks before showing an editable live checklist.
  /// Do not overwrite locally selected demo tasks when no authenticated API exists.
  Future<void> refreshTasks() async {
    if (!isLive) return;
    final response = await DailyControlApi.get('/v1/dashboard/tasks', {});
    final values = response['checkedTaskIds'];
    if (values is! List) throw const FormatException('Server must return checkedTaskIds.');
    final ids = <int>{};
    for (final v in values) {
      if (v is! num || v.toInt() < 1 || v.toInt() > 14) {
        throw const FormatException('Invalid task ID from server.');
      }
      ids.add(v.toInt());
    }
    if (response['tasks'] is List) {
      liveTaskLabels = [for (final task in response['tasks'] as List) (task as Map)['name'].toString()];
    }
    tasksFromServer = true;
    checkedTasks..clear()..addAll(ids);
    notifyListeners();
  }

  Future<void> setTask(int id, bool checked) async {
    await _serverWrite('daily-task', {'taskId': id, 'completed': checked});
    if (checked) { checkedTasks.add(id); } else { checkedTasks.remove(id); }
    notifyListeners();
  }

  Future<void> putHoliday(HolidayAssignment item, {HolidayAssignment? previous}) async {
    await _serverWrite('holiday-upsert', {...item.toJson(), 'category': item.type.label, 'oldName': previous?.name ?? '', 'oldDay': previous?.day ?? ''});
    holidays.removeWhere((x) => x.id == item.id);
    holidays.add(item);
    await refreshHolidays();
  }

  Future<void> removeHoliday(HolidayAssignment item) async {
    await _serverWrite('holiday-delete', item.toJson());
    holidays.removeWhere((x) => x.id == item.id);
    await refreshHolidays();
  }

  Future<void> putNote(HolidayNote item) async {
    await _serverWrite('holiday-note-save', {...item.toJson(), if (item.id >= 10 && item.id <= 25) 'rowNumber': item.id});
    notes.removeWhere((x) => x.id == item.id);
    notes.add(item);
    await refreshHolidays();
  }

  Future<void> removeNote(HolidayNote item) async {
    await _serverWrite('holiday-note-delete', {...item.toJson(), if (item.id >= 10 && item.id <= 25) 'rowNumber': item.id});
    notes.removeWhere((x) => x.id == item.id);
    await refreshHolidays();
  }

  Future<void> putProductivity(ProductivityDay day) async {
    await _serverWrite('productivity-day', day.toJson());
    productivity[day.date] = day;
    await refreshProductivity();
  }

  Future<void> setProductivityTarget(double target) async {
    await _serverWrite('productivity-target-save', {'target': target.round()});
    dailyProductivityTarget = target;
    await refreshProductivity();
  }

  Future<void> putTrip(TripSlot trip) async {
    await _serverWrite('lh-trip', trip.toJson());
    trips['${trip.date}_${trip.slot}'] = trip;
    await refreshTrips();
  }

  static int? _parseInt(String v) {
    final clean = v.replaceAll(',', '').replaceAll('.', '').trim();
    return clean.isEmpty ? null : int.tryParse(clean);
  }

  static String? _parseSheetDate(String raw) {
    final text = raw.trim();
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return text;
    final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
    if (slash != null) {
      final month = int.parse(slash[1]!);
      final day = int.parse(slash[2]!);
      final year = int.parse(slash[3]!);
      return dcDateKey(DateTime(year, month, day));
    }
    final english = RegExp(r'^(\d{1,2})[\s-]+([A-Za-z]{3})[\s-]+(\d{4})$').firstMatch(text);
    if (english != null) {
      const months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
      final index = months.indexOf(english[2]!.toLowerCase());
      if (index >= 0) return dcDateKey(DateTime(int.parse(english[3]!), index + 1, int.parse(english[1]!)));
    }
    return null;
  }

  /// Baca ulang sumber spreadsheet; hanya data yang berhasil dibaca ditampilkan
  /// sebagai LIVE. Jangan campur data contoh ketika server telah aktif.
  Future<void> refreshProductivity() async {
    if (!isLive) return;
    final response = await DailyControlApi.get('/v1/productivity', {});
    final result = <String, ProductivityDay>{};
    for (final raw in (response['rows'] as List? ?? const [])) {
      final row = (raw as List).map((x) => x?.toString() ?? '').toList();
      if (row.length < 4) continue;
      final date = _parseSheetDate(row[0]);
      if (date == null) continue;
      result[date] = ProductivityDay(date: date, inbound: _parseInt(row[1]),
        operators: _parseInt(row[2]), outbound: _parseInt(row[3]));
    }
    final target = double.tryParse((response['target'] ?? '').toString().replaceAll(',', ''));
    if (target != null && target > 0) dailyProductivityTarget = target;
    productivity = result;
    notifyListeners();
  }

  Future<void> refreshTrips() async {
    if (!isLive) return;
    final response = await DailyControlApi.get('/v1/lh-trip', {});
    final result = <String, TripSlot>{};
    String? date;
    for (final raw in (response['rows'] as List? ?? const [])) {
      final row = (raw as List).map((x) => x?.toString() ?? '').toList();
      if (row.length < 15) continue;
      date = _parseSheetDate(row[0]) ?? date;
      final match = RegExp(r'Slot\s*([123])', caseSensitive: false).firstMatch(row[1]);
      if (date == null || match == null) continue;
      final slot = int.parse(match[1]!);
      result['${date}_$slot'] = TripSlot(date: date, slot: slot,
        tripId: row[2], estimateArrival: row[3], departureStation: row[4],
        nextStation: row[5], scheduleDeparture: row[6], actualDeparture: row[7],
        actualArrival: row[8], status: row[9], orderCount: row[10], packCount: row[11],
        vehicle: row[12], vehicleGroup: row[13], driver: row[14]);
    }
    trips = result;
    notifyListeners();
  }

  Future<void> refreshHolidays() async {
    if (!isLive) return;
    final response = await DailyControlApi.get('/v1/holiday', {});
    final grid = (response['grid'] as List? ?? const []);
    final backgrounds = (response['colors'] as List? ?? const []);
    final legends = (response['legend'] as List? ?? const []).map((e) => '$e').toList();
    final legendColors = (response['legendColors'] as List? ?? const []).map((e) => '$e').toList();
    final assignments = <HolidayAssignment>[];
    for (var r = 0; r < grid.length && r < 4; r++) {
      final row = (grid[r] as List);
      for (var c = 0; c < row.length && c < 7; c++) {
        final name = (row[c] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final color = r < backgrounds.length && c < (backgrounds[r] as List).length
          ? '${(backgrounds[r] as List)[c]}'.toLowerCase() : '';
        final i = legendColors.indexWhere((v) => v.toLowerCase() == color);
        final legend = i >= 0 && i < legends.length ? legends[i] : '';
        final type = RiderType.values.firstWhere((x) => x.label == legend,
          orElse: () => RiderType.riderDedicated);
        assignments.add(HolidayAssignment(id: 1 + c * 4 + r, day: dcWeekdays[c], name: name, type: type));
      }
    }
    final notesSource = response['notes'] as List? ?? const [];
    final freshNotes = <HolidayNote>[];
    for (var i = 0; i < notesSource.length; i++) {
      final line = (notesSource[i] as List).map((x) => (x ?? '').toString()).toList();
      if (line.isEmpty || line[0].trim().isEmpty) continue;
      freshNotes.add(HolidayNote(id: i + 10, name: line[0],
        start: line.length > 1 ? (_parseSheetDate(line[1]) ?? line[1]) : '',
        end: line.length > 2 ? (_parseSheetDate(line[2]) ?? line[2]) : '',
        reason: line.length > 3 ? line[3] : ''));
    }
    holidays = assignments;
    notes = freshNotes;
    notifyListeners();
  }

  Future<void> refreshAllLive() async {
    if (!isLive) return;
    await refreshTasks();
    await refreshProductivity();
    await refreshTrips();
    await refreshHolidays();
  }

}

List<HolidayAssignment> _seedHolidays() {
  final records = <(String, String, RiderType)>[
    ('Senin', 'HAMDANI PULUNGAN', RiderType.riderDedicated),
    ('Senin', 'ARIFFAN SURI PURBA', RiderType.riderDedicated),
    ('Senin', 'RIZKI', RiderType.riderPlus),
    ('Senin', 'MARDIANSYAH', RiderType.driverDedicated),
    ('Selasa', 'BINTANG S', RiderType.riderDedicated),
    ('Selasa', 'RIDHO AGUSTIAN', RiderType.riderDedicated),
    ('Selasa', 'FIQI ARIANTO', RiderType.riderPlus),
    ('Rabu', 'ISWAHYUDI', RiderType.riderDedicated),
    ('Rabu', 'MUHAMMAD THORIQ LUBIS', RiderType.riderPlus),
    ('Rabu', 'TRI IRWAN', RiderType.riderPlus),
    ('Rabu', 'HALIMAN', RiderType.driverDedicated),
    ('Kamis', 'RENDI SAPUTRA', RiderType.riderDedicated),
    ('Kamis', 'NEDI SAFITRI', RiderType.riderDedicated),
    ('Kamis', 'RISKI ABDUR ROHIM', RiderType.riderPlus),
    ('Jumat', 'ISMAIL', RiderType.riderDedicated),
    ('Jumat', 'MUHAMMAD REZA', RiderType.riderDedicated),
    ('Jumat', 'PRAMUJA', RiderType.riderPlus),
    ('Jumat', 'ADRIAN KUSWONDO', RiderType.driverDedicated),
    ('Sabtu', 'BAHRUL AYSRORI', RiderType.riderDedicated),
    ('Sabtu', 'ALFARIDZI FATURRAHMAN', RiderType.riderDedicated),
    ('Sabtu', 'M. SYAWALUDIN PRATAMA', RiderType.riderDedicated),
    ('Sabtu', 'MUHAMMAD WANDA ARYA', RiderType.driverDedicated),
    ('Minggu', 'DIKI HERMANSYAH', RiderType.riderDedicated),
    ('Minggu', 'PAJAR ANUGRAH', RiderType.riderDedicated),
    ('Minggu', 'ARIYA WARDANA P', RiderType.riderPlus),
    ('Minggu', 'RISFAL FADHILLAH', RiderType.driverDedicated),
  ];
  return [for (var i = 0; i < records.length; i++) HolidayAssignment(id: i + 1, day: records[i].$1, name: records[i].$2, type: records[i].$3)];
}

Map<String, ProductivityDay> _seedProductivity() {
  final values = [3499, 2174, 3589, 2617, 2402, 3280, 2176, 3380, 3586, 2117];
  return {for (var i = 0; i < values.length; i++)
    '2026-11-${(i + 1).toString().padLeft(2, '0')}': ProductivityDay(date: '2026-11-${(i + 1).toString().padLeft(2, '0')}', operators: i == 6 ? 2 : 3, outbound: values[i])};
}

Map<String, TripSlot> _seedTrips() => {
  '2026-11-11_1': TripSlot(date: '2026-11-11', slot: 1, tripId: 'LT0QB31PIRVV1', actualArrival: '04:16', vehicle: 'B9280NCJ', orderCount: '39 (1.439)', status: 'Arrived'),
  '2026-11-11_2': TripSlot(date: '2026-11-11', slot: 2, tripId: 'LT0QB31PW4001', actualArrival: '08:21', vehicle: 'BM8592AU', orderCount: '22 (888)', status: 'Arrived'),
  '2026-11-11_3': TripSlot(date: '2026-11-11', slot: 3),
};
