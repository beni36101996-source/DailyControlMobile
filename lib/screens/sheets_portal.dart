import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_theme.dart';
import '../core/api_service.dart';

/// The report *is* the original Google spreadsheet. No replacement cells,
/// formulas, colours or editable layouts are maintained inside the APK.
/// The list below is an allowlist of operational tabs, not an edit to Sheets.
class SheetsPortalScreen extends StatelessWidget {
  const SheetsPortalScreen({super.key});

  static const String _spreadsheetId =
      '1HGDPSfrpkTTWb0IvnEbXlfBAUpAki-Gd3-wn8Fzt8Es';
  static const String _base =
      'https://docs.google.com/spreadsheets/d/$_spreadsheetId/edit';

  static const List<_SheetLink> _reports = [
    _SheetLink('DASHBOARD', 1043010834, Icons.dashboard_outlined),
    _SheetLink('Rekap Order', 894957539, Icons.receipt_long_outlined),
    _SheetLink('Aging Paket', 1124219549, Icons.inventory_2_outlined),
    _SheetLink('PRODUCTIVITY OPR', 1354624253, Icons.analytics_outlined),
    _SheetLink('MONITORING TARGET RIDER', 1940410388, Icons.track_changes_outlined),
    _SheetLink('JADWAL LIBUR RIDER', 1132428778, Icons.event_outlined),
    _SheetLink('New LH TRIP', 510042420, Icons.route_outlined),
    _SheetLink('DAILY ACTIVE', 676802605, Icons.groups_outlined),
  ];

  // Sheet IDs read from the actual spreadsheet on 16 November 2026. A new
  // period is added to this app list only after its tab ID is known; the
  // original Google Sheet itself is never modified by this navigation.
  static const List<_SheetLink> _delivered = [
    _SheetLink('DELIVERED 9 - 15', 1508773574, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 2 - 8', 694785034, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 26 - 1', 996785776, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 19 - 25', 277850235, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 12 - 18', 608677011, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 5 - 11', 495149053, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 28 - 4', 1782442462, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 21 - 27', 1207087005, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 14 - 20', 1071721907, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 7 - 13', 1321086763, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 24 - 30', 81308904, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 17 - 23', 2093493370, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 3 - 9', 223846470, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 27 - 2', 727976786, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 20 - 26', 1411725383, Icons.calendar_view_week_outlined),
    _SheetLink('DELIVERED 06 - 12', 1273527308, Icons.calendar_view_week_outlined),
  ];

  static Future<void> openSheet(BuildContext context, {int gid = 1043010834}) async {
    // Opening in the Sheets app/browser preserves native editing, formulas,
    // conditional formats, validation, and the user's Google account access.
    final uri = Uri.parse('$_base#gid=$gid');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('No Google Sheets handler');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Google Sheets tidak bisa dibuka. Instal Sheets atau gunakan browser.'),
      ));
    }
  }

  Widget _link(BuildContext context, _SheetLink sheet) => Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
          leading: Icon(sheet.icon, size: 21, color: AppColors.blue),
          title: Text(sheet.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          trailing: const Icon(Icons.open_in_new, size: 17),
          onTap: () => openSheet(context, gid: sheet.gid),
        ),
      );

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(13),
        children: [
          const Text('Laporan Operasional',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Buka langsung tab Google Sheets asli. Tampilan, warna, rumus, dan sel edit tetap sama seperti spreadsheet.',
            style: TextStyle(fontSize: 11.5, color: AppColors.muted),
          ),
          const SizedBox(height: 11),
          for (final sheet in _reports) _link(context, sheet),
          const SizedBox(height: 10),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.local_shipping_outlined, color: AppColors.blue),
              title: const Text('DELIVERED — Pilih Periode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              subtitle: const Text('Seluruh periode yang sudah ada dalam spreadsheet',
                  style: TextStyle(fontSize: 11)),
              children: [
                _LiveDeliveredPeriods(
                  fallback: _delivered,
                  itemBuilder: (item) => _link(context, item),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Raw Data, Raw Backlog, Snapshot, Master, backup, dan sheet bantu sengaja tidak dibuatkan menu. '
            'Catatan: jika kamu membuka Google Sheets asli, tab lain yang belum disembunyikan di Google Sheets tetap mengikuti pengaturan file asli.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 25),
        ],
      );
}

class _SheetLink {
  const _SheetLink(this.title, this.gid, this.icon);
  final String title;
  final int gid;
  final IconData icon;
}


/// Newly created DELIVERED periods appear without rebuilding the APK once
/// Gateway's sheet-catalog action has been deployed. The saved 16 periods are
/// a fallback for older gateways and offline use.
class _LiveDeliveredPeriods extends StatefulWidget {
  const _LiveDeliveredPeriods({required this.fallback, required this.itemBuilder});
  final List<_SheetLink> fallback;
  final Widget Function(_SheetLink) itemBuilder;

  @override
  State<_LiveDeliveredPeriods> createState() => _LiveDeliveredPeriodsState();
}

class _LiveDeliveredPeriodsState extends State<_LiveDeliveredPeriods> {
  List<_SheetLink>? live;
  bool loading = false;

  @override
  void initState() { super.initState(); _refresh(); }

  Future<void> _refresh() async {
    if (!DailyControlApi.isReady) return;
    setState(() => loading = true);
    try {
      final data = await DailyControlApi.get('/v1/sheets/catalog', const {});
      final found = <_SheetLink>[];
      for (final raw in (data['delivered'] as List? ?? const [])) {
        if (raw is! Map) continue;
        final title = '${raw['title'] ?? ''}'.trim();
        final id = raw['gid'];
        final gid = id is num ? id.toInt() : int.tryParse('$id');
        if (title.startsWith('DELIVERED') && gid != null) {
          found.add(_SheetLink(title, gid, Icons.calendar_view_week_outlined));
        }
      }
      if (mounted && found.isNotEmpty) setState(() => live = found);
    } catch (_) {
      // Older gateway: preserve working navigation instead of blocking reports.
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = live ?? widget.fallback;
    return Column(children: [
      Row(children: [
        const SizedBox(width: 16),
        Expanded(child: Text(live == null
          ? 'Daftar periode tersimpan di APK'
          : 'Periode langsung dari spreadsheet',
          style: const TextStyle(fontSize: 10, color: AppColors.muted))),
        IconButton(tooltip: 'Perbarui daftar periode',
          onPressed: loading ? null : _refresh,
          icon: const Icon(Icons.refresh, size: 18)),
      ]),
      if (loading) const LinearProgressIndicator(),
      for (final item in items) widget.itemBuilder(item),
    ]);
  }
}
