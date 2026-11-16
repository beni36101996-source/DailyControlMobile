import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/control_store.dart';

/// Form konfigurasi Web App yang di-deploy pada Apps Script milik Daily Control.
/// Key tidak dicetak ke log maupun ditampilkan kembali setelah disimpan.
class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});
  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController url;
  final key = TextEditingController();
  bool busy = false;
  bool hidden = true;
  Map<String, dynamic>? status;
  String? problem;

  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: DailyControlApi.endpoint);
    if (DailyControlApi.isReady) _probe();
  }

  @override
  void dispose() { url.dispose(); key.dispose(); super.dispose(); }

  Future<void> _probe() async {
    setState(() { busy = true; problem = null; });
    try {
      final result = await DailyControlApi.checkConnection();
      if (mounted) setState(() => status = result);
    } catch (error) {
      if (mounted) setState(() => problem = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _save() async {
    setState(() { busy = true; problem = null; });
    try {
      final result = await DailyControlApi.connect(url.text, key.text);
      await DailyControlStore.instance.clearLegacyDemo();
      if (mounted) setState(() { status = result; key.clear(); });
      try {
        await DailyControlStore.instance.refreshAllLive();
      } catch (readError) {
        if (mounted) setState(() => problem = 'Koneksi berhasil, tetapi sebagian tabel gagal dimuat: $readError');
      }
    } catch (error) {
      if (mounted) setState(() => problem = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _disconnect() async {
    await DailyControlApi.disconnect();
    if (mounted) setState(() { status = null; problem = null; url.clear(); key.clear(); });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Koneksi Daily Control')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Hubungkan APK ke Apps Script', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      const Text('Gunakan URL deployment /exec dan API key yang dibuat di Script Properties. '
        'Kunci hanya untuk HP operator dan disimpan di penyimpanan aman Android.',
        style: TextStyle(fontSize: 12)),
      const SizedBox(height: 16),
      TextField(controller: url, autocorrect: false,
        decoration: const InputDecoration(labelText: 'URL Web App', hintText: 'https://script.google.com/macros/s/.../exec'),
        keyboardType: TextInputType.url),
      const SizedBox(height: 12),
      TextField(controller: key, obscureText: hidden, autocorrect: false,
        decoration: InputDecoration(labelText: 'API key (rahasia)',
          suffixIcon: IconButton(onPressed: () => setState(() => hidden = !hidden),
            icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(onPressed: busy ? null : _save,
        icon: const Icon(Icons.link), label: const Text('Hubungkan & Verifikasi')),
      OutlinedButton.icon(onPressed: busy || !DailyControlApi.isReady ? null : _probe,
        icon: const Icon(Icons.refresh), label: const Text('Uji Koneksi Ulang')),
      if (busy) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: LinearProgressIndicator()),
      if (problem != null) Padding(padding: const EdgeInsets.all(10),
        child: Text(problem!, style: const TextStyle(color: Colors.red, fontSize: 12))),
      const Divider(height: 30),
      if (DailyControlApi.isReady) ...[
        const Text('Status terverifikasi', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        _statusLine('Spreadsheet', '${status?['spreadsheetTitle'] ?? 'Daily Control'}'),
        _statusLine('Jumlah sheet', '${status?['sheetCount'] ?? '—'}'),
        _statusLine('Akses tulis', DailyControlApi.canWrite ? 'Diaktifkan server' : 'TERKUNCI (read-only)'),
        _statusLine('Upload', DailyControlApi.canUpload ? 'Diaktifkan server' : 'TERKUNCI'),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: busy ? null : _disconnect,
          icon: const Icon(Icons.logout), label: const Text('Putuskan koneksi')),
      ] else const Text('Belum tersambung. Data contoh tidak dianggap sebagai data spreadsheet.',
        style: TextStyle(fontSize: 12)),
      const SizedBox(height: 18),
      const Text('Keamanan: Untuk penggunaan bersama banyak staf, perlu login OAuth dan kontrol peran. '
        'Jangan mengirim API key melalui chat, memasukkannya ke GitHub, atau membagikan APK yang sudah berisi kunci.',
        style: TextStyle(fontSize: 11, color: Colors.black54)),
    ]),
  );

  Widget _statusLine(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [SizedBox(width: 104, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12)))]));
}
