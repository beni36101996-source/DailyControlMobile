import 'package:shared_preferences/shared_preferences.dart';

/// Public HTTPS URLs only. Never store API keys or private credentials here.
class OperationalLinks {
  static const names = ['STD Daily', 'Paket Stuck', 'Expedited', 'Idle Time'];
  static String _key(String name) => 'dc_public_link_${name.toLowerCase().replaceAll(' ', '_')}';
  static Future<String> load(String name) async =>
      (await SharedPreferences.getInstance()).getString(_key(name)) ?? '';
  static Future<void> save(String name, String value) async {
    final url = Uri.tryParse(value.trim());
    if (url == null || url.scheme != 'https' || url.host.isEmpty ||
        url.userInfo.isNotEmpty) {
      throw FormatException('Masukkan link HTTPS yang benar tanpa username atau password.');
    }
    (await SharedPreferences.getInstance()).setString(_key(name), url.toString());
  }
}
