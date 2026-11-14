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
  final Set<int> checkedTasks = {1, 2, 3, 4, 5, 6};
  List<HolidayAssignment> holidays = _seedHolidays();
  List<HolidayNote> notes = [HolidayNote(id: 1, name: 'ALFARIDZI FATURRAHMAN', start: '2026-10-25', end: '2026-11-01', reason: 'Cuti')];
  Map<String, ProductivityDay> productivity = _seedProductivity();
  Map<String, TripSlot> trips = _seedTrips();
  double dailyProductivityTarget = 952;
  String get syncLabel => DailyControlApi.isReady ? 'Server terhubung: perubahan menunggu konfirmasi API' : 'Mode lokal: tersimpan di HP, BELUM masuk Google Sheets';
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
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(key, jsonEncode(value));
    notifyListeners();
  }

  /// When API is connected, require server confirmation *before* changing UI state.
  Future<void> _serverWrite(String endpoint, Map<String, dynamic> payload) async {
    if (isLive) await DailyControlApi.action(endpoint, payload);
  }

  Future<void> setTask(int id, bool checked) async {
    await _serverWrite('daily-task', {'taskId': id, 'completed': checked});
    if (checked) { checkedTasks.add(id); } else { checkedTasks.remove(id); }
    await _write('dc_v2_tasks', checkedTasks.toList()..sort());
  }

  Future<void> putHoliday(HolidayAssignment item) async {
    await _serverWrite('holiday-assignment', item.toJson());
    holidays.removeWhere((x) => x.id == item.id);
    holidays.add(item);
    await _write('dc_v2_holidays', holidays.map((x) => x.toJson()).toList());
  }

  Future<void> removeHoliday(HolidayAssignment item) async {
    await _serverWrite('holiday-assignment-delete', item.toJson());
    holidays.removeWhere((x) => x.id == item.id);
    await _write('dc_v2_holidays', holidays.map((x) => x.toJson()).toList());
  }

  Future<void> putNote(HolidayNote item) async {
    await _serverWrite('holiday-note', item.toJson());
    notes.removeWhere((x) => x.id == item.id);
    notes.add(item);
    await _write('dc_v2_notes', notes.map((x) => x.toJson()).toList());
  }

  Future<void> removeNote(HolidayNote item) async {
    await _serverWrite('holiday-note-delete', item.toJson());
    notes.removeWhere((x) => x.id == item.id);
    await _write('dc_v2_notes', notes.map((x) => x.toJson()).toList());
  }

  Future<void> putProductivity(ProductivityDay day) async {
    await _serverWrite('productivity-day', day.toJson());
    productivity[day.date] = day;
    await _write('dc_v2_productivity', productivity.values.map((x) => x.toJson()).toList());
  }

  Future<void> setProductivityTarget(double target) async {
    await _serverWrite('productivity-target', {'target': target});
    dailyProductivityTarget = target;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setDouble('dc_v2_target', target);
    notifyListeners();
  }

  Future<void> putTrip(TripSlot trip) async {
    await _serverWrite('lh-trip', trip.toJson());
    trips['${trip.date}_${trip.slot}'] = trip;
    await _write('dc_v2_trips', trips.values.map((x) => x.toJson()).toList());
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
