import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Daily Control Mobile -> Gateway standalone Gmail pribadi, ke sheet yang sama.
/// Semua operasi, termasuk baca, lewat POST JSON. API key tidak masuk URL,
/// log, screenshot, maupun repository dan disimpan di Android KeyStore.
/// PERINGATAN: key operator tunggal; untuk banyak pengguna butuh OAuth+role.
class DailyControlApi {
  static const _storage = FlutterSecureStorage();
  static String _url = '';
  static String _apiKey = '';
  static bool _connected = false;
  static bool _readOnly = true;
  static bool _uploadEnabled = false;

  static bool get isReady => _connected;
  static bool get canWrite => _connected && !_readOnly;
  static bool get canUpload => canWrite && _uploadEnabled;
  static String get endpoint => _url;
  static bool get readOnly => _readOnly;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _url = prefs.getString('dcm_gateway_url') ?? '';
    _apiKey = await _storage.read(key: 'dcm_gateway_key') ?? '';
    _connected = false;
    if (_url.isNotEmpty && _apiKey.isNotEmpty) {
      try { await checkConnection(); } catch (_) { _connected = false; }
    }
  }

  static bool _validUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host == 'script.google.com' &&
        uri.path.startsWith('/macros/s/') && uri.path.endsWith('/exec');
  }

  static Future<Map<String, dynamic>> connect(String url, String key) async {
    final normalized = url.trim();
    if (!_validUrl(normalized)) {
      throw StateError('URL harus alamat deployment Apps Script .../exec di script.google.com.');
    }
    if (key.trim().length < 48) throw StateError('API key belum lengkap.');
    final response = await _raw('health', const {}, url: normalized, key: key.trim());
    final data = Map<String, dynamic>.from(response['result'] as Map);
    if (data['spreadsheetTitle'] == null) throw StateError('Endpoint tidak cocok dengan Gateway Daily Control.');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dcm_gateway_url', normalized);
    await _storage.write(key: 'dcm_gateway_key', value: key.trim());
    _url = normalized;
    _apiKey = key.trim();
    _connected = true;
    _readOnly = data['readOnly'] != false;
    _uploadEnabled = data['uploadEnabled'] == true;
    return data;
  }

  static Future<Map<String, dynamic>> checkConnection() async {
    if (_url.isEmpty || _apiKey.isEmpty) throw StateError('Isi URL gateway dan API key di menu Koneksi.');
    try {
      final response = await _raw('health', const {});
      final data = Map<String, dynamic>.from(response['result'] as Map);
      _connected = true;
      _readOnly = data['readOnly'] != false;
      _uploadEnabled = data['uploadEnabled'] == true;
      return data;
    } catch (_) {
      _connected = false;
      rethrow;
    }
  }

  static Future<void> disconnect() async {
    _url = ''; _apiKey = ''; _connected = false;
    _readOnly = true; _uploadEnabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dcm_gateway_url');
    await _storage.delete(key: 'dcm_gateway_key');
  }

  static Future<Map<String, dynamic>> _raw(String action, Map<String, dynamic> data,
      {String? url, String? key}) async {
    final target = url ?? _url;
    final apiKey = key ?? _apiKey;
    if (!_validUrl(target) || apiKey.isEmpty) throw StateError('Gateway belum dikonfigurasi.');
    final response = await http.post(Uri.parse(target),
      headers: const {'Content-Type': 'text/plain; charset=utf-8'},
      body: jsonEncode({'action': action, 'apiKey': apiKey, 'data': data}),
    ).timeout(const Duration(seconds: 150));
    Map<String, dynamic> result;
    try {
      result = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } catch (_) {
      throw StateError('Respons Apps Script tidak valid (HTTP ${response.statusCode}). Periksa deployment /exec dan izin akses.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || result['ok'] != true) {
      throw StateError('${result['error'] ?? 'Request gagal'} (HTTP ${response.statusCode})');
    }
    return result;
  }

  static Future<Map<String, dynamic>> _call(String action, Map<String, dynamic> data) async {
    if (!_connected) throw StateError('Belum ada koneksi LIVE yang berhasil diverifikasi. Buka Pengaturan Koneksi.');
    final response = await _raw(action, data);
    if (response['result'] is! Map) throw const FormatException('Result API harus berupa object.');
    return Map<String, dynamic>.from(response['result'] as Map);
  }

  static Future<Map<String, dynamic>> get(String path, Map<String, String> query) async {
    final action = switch (path) {
      '/v1/dashboard/tasks' => 'daily-tasks',
      '/v1/dashboard' => 'dashboard',
      '/v1/target-rider' => 'target-rider',
      '/v1/daily-active' => 'daily-active',
      '/v1/productivity' => 'productivity',
      '/v1/lh-trip' => 'lh-trip',
      '/v1/holiday' => 'holiday',
      '/v1/delivered/periods' => 'delivered-periods',
      '/v1/delivered' => 'delivered-data',
      '/v1/aging' => 'aging',
      '/v1/pretrip' => 'pretrip',
      '/v1/recap-order' => 'recap-order',
      _ => throw StateError('Endpoint baca tidak dikenali: $path'),
    };
    return _call(action, Map<String, dynamic>.from(query));
  }

  static Future<Map<String, dynamic>> action(String path, Map<String, dynamic> data) async {
    if (!canWrite) throw StateError('Gateway masih READ ONLY. Pengubahan Spreadsheet belum diizinkan.');
    final action = switch (path) {
      'daily-task' => 'daily-task-set',
      'productivity-day' => 'productivity-save',
      'lh-trip' => 'lh-trip-save',
      'target-rider-target' => 'target-set',
      'holiday-upsert' => 'holiday-upsert',
      'holiday-delete' => 'holiday-delete',
      'holiday-note-save' => 'holiday-note-save',
      'holiday-note-delete' => 'holiday-note-delete',
      'productivity-target-save' => 'productivity-target-save',
      'update-delivered' => 'update-delivered',
      'baseline-backlog' => 'baseline-backlog',
      'refresh-aging' => 'refresh-aging',
      'holiday-slot' => 'holiday-slot-save',
      _ => throw StateError('Tindakan "$path" belum terhubung/teruji. Data TIDAK disimpan.'),
    };
    return _call(action, data);
  }

  static Future<List<Map<String, dynamic>>> latestJobs() async {
    final r = await _call('jobs-latest', const {});
    return [for (final raw in (r['jobs'] as List? ?? const []))
      Map<String, dynamic>.from(raw as Map)];
  }

  static Future<Map<String, dynamic>> jobStatus(String jobId) async {
    return _call('job-status', {'jobId': jobId});
  }

  /// Upload masuk antrean Apps Script asli. Respons PENDING bukan hasil selesai.
  /// Mesin Order tetap 4 tahap di worker; Harian tidak memanggil Update Delivered.
  static Future<Map<String, dynamic>> upload({
    required String kind,
    required String fileName,
    required Uint8List bytes,
    String? sheetName,
    String? mode,
  }) async {
    if (!canUpload) throw StateError('Upload masih dikunci di Apps Script. Tidak ada data yang berubah.');
    final ext = fileName.toLowerCase().split('.').last;
    if (bytes.length > 8 * 1024 * 1024) throw StateError('File melebihi batas 8 MB.');
    if (kind == 'harian') {
      if (ext != 'csv') throw StateError('Data Harian harus CSV.');
      return _call('upload-daily', {'fileName': fileName, 'sheetName': sheetName,
        'mode': mode, 'csvText': utf8.decode(bytes, allowMalformed: true)});
    }
    if (kind == 'order') {
      if (ext != 'csv') throw StateError('Data Order harus CSV.');
      return _call('upload-order', {
        'fileName': fileName, 'csvText': utf8.decode(bytes, allowMalformed: true)});
    }
    if (kind == 'backlog') {
      if (ext == 'csv') {
        return _call('upload-backlog-csv', {
          'fileName': fileName, 'csvText': utf8.decode(bytes, allowMalformed: true)});
      }
      if (ext == 'xlsx') {
        final workbook = Excel.decodeBytes(bytes);
        const required = <String>['shipment id', 'lm hub aging', 'no. attempts', 'latest user name', 'order account'];
        for (final sheet in workbook.tables.values) {
          if (sheet == null) continue;
          final rows = sheet.rows.map((r) => r.map((c) => c?.value?.toString() ?? '').toList()).toList();
          if (rows.isEmpty) continue;
          final heads = rows.first.map((v) => v.toLowerCase().trim()).toList();
          if (required.every(heads.contains)) {
            return _call('upload-backlog-table', {'fileName': fileName, 'rows': rows});
          }
        }
        throw StateError('File Excel tidak memiliki sheet dengan header backlog yang sesuai.');
      }
      throw StateError('Backlog hanya mendukung CSV atau XLSX. Format XLS lama belum didukung.');
    }
    throw StateError('Jenis upload tidak dikenal.');
  }
}
