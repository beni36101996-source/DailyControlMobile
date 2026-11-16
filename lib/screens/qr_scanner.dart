import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// QR pairing data is handled only inside the app and is never logged.
class GatewayQrData {
  final String url;
  final String? apiKey;
  const GatewayQrData(this.url, this.apiKey);

  static GatewayQrData? tryParse(String raw) {
    try {
      final dynamic obj = jsonDecode(raw);
      if (obj is Map && obj['type'] == 'dcmobile.gateway.v1') {
        final url = obj['url'];
        final key = obj['key'];
        if (url is String && key is String &&
            url.startsWith('https://script.google.com/macros/s/') &&
            url.endsWith('/exec') && key.isNotEmpty) {
          return GatewayQrData(url, key);
        }
      }
    } catch (_) {
      // Plain URL QR is also supported, but requires manually entering a key.
    }
    final url = raw.trim();
    if (url.startsWith('https://script.google.com/macros/s/') &&
        url.endsWith('/exec')) {
      return GatewayQrData(url, null);
    }
    return null;
  }
}

class GatewayQrScanner extends StatefulWidget {
  const GatewayQrScanner({super.key});

  @override
  State<GatewayQrScanner> createState() => _GatewayQrScannerState();
}

class _GatewayQrScannerState extends State<GatewayQrScanner> {
  bool _accepted = false;
  bool _invalidShown = false;

  void _onDetect(BarcodeCapture capture) {
    if (_accepted || !mounted) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      final config = GatewayQrData.tryParse(value);
      if (config != null) {
        _accepted = true;
        Navigator.of(context).pop(config);
        return;
      }
      if (!_invalidShown) {
        _invalidShown = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('QR bukan konfigurasi Daily Control. Scan QR dari HP admin.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan QR Koneksi')),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Arahkan kamera ke QR Koneksi pada HP admin. '
                'URL dan kunci akan terisi otomatis.'),
          ),
          Expanded(child: MobileScanner(onDetect: _onDetect)),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Jangan scan QR dari sumber yang tidak dipercaya.'),
          ),
        ]),
      );
}
