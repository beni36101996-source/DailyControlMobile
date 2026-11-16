import 'package:flutter/material.dart';
import '../core/control_store.dart';
import '../core/api_service.dart';

class SyncNotice extends StatelessWidget {
  const SyncNotice({super.key, this.compact = true});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final store = DailyControlStore.instance;
    final connected = store.isLive;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 7 : 11),
      decoration: BoxDecoration(
        color: connected ? const Color(0xFFE2F6E9) : const Color(0xFFFFF2D6),
        border: Border.all(color: connected ? const Color(0xFFB2DEBE) : const Color(0xFFF0D596)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(children: [
        Icon(connected ? Icons.cloud_done_outlined : Icons.phonelink_lock_outlined,
          size: 17, color: connected ? const Color(0xFF137548) : const Color(0xFF805916)),
        const SizedBox(width: 7),
        Expanded(child: Text(connected
          ? (DailyControlApi.canWrite ? 'TERHUBUNG • data LIVE • penulisan wajib dikonfirmasi server.' : 'TERHUBUNG • BACA SAJA • penulisan ke spreadsheet masih dikunci.')
          : 'BELUM TERHUBUNG • data di layar tertentu mungkin contoh; buka Koneksi LIVE.',
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
