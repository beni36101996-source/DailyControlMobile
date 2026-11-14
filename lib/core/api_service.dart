import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Only an API bridge, not a live connection. A server and verified login are
/// required before enabling writes to the real operational spreadsheet.
class DailyControlApi {
  static const baseUrl = String.fromEnvironment('DC_API_BASE_URL', defaultValue: '');
  static String? accessToken;
  static bool get isReady => baseUrl.isNotEmpty && (accessToken?.isNotEmpty ?? false);

  static Future<Map<String, dynamic>> upload({
    required String kind,
    required String fileName,
    required Uint8List bytes,
    String? sheetName,
    String? mode,
  }) async {
    return _post('/v1/upload/$kind', {
      'fileName': fileName,
      'base64Data': base64Encode(bytes),
      'sheetName': sheetName,
      'mode': mode,
    });
  }

  static Future<Map<String, dynamic>> action(String path, Map<String, dynamic> body) =>
      _post('/v1/actions/$path', body);

  static Future<Map<String, dynamic>> get(String path, Map<String, String> query) async {
    if (!isReady) throw StateError('API dan login belum dikonfigurasi.');
    final url = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    if (url.scheme != 'https') throw StateError('API wajib menggunakan HTTPS.');
    final response = await http.get(url, headers: {'authorization': 'Bearer $accessToken'})
      .timeout(const Duration(seconds: 30));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || response.statusCode < 200 || response.statusCode >= 300 || decoded['ok'] != true) {
      throw StateError('API baca gagal (HTTP ${response.statusCode}).');
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    if (!isReady) {
      throw StateError('Belum terhubung. Backend API aman dan login belum disiapkan. Tidak ada data Spreadsheet yang berubah.');
    }
    final url = Uri.parse('$baseUrl$path');
    if (url.scheme != 'https') throw StateError('API wajib memakai HTTPS.');
    final response = await http.post(
      url,
      headers: {'content-type': 'application/json', 'authorization': 'Bearer $accessToken'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 60));
    Map<String, dynamic> result;
    try {
      result = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw StateError('Respons server tidak valid (HTTP ${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300 || result['ok'] != true) {
      throw StateError((result['message'] ?? 'Permintaan gagal (HTTP ${response.statusCode}).').toString());
    }
    return result;
  }
}
