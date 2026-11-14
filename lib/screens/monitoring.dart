import 'package:flutter/material.dart';
import '../widgets/ui.dart';
import 'details.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});
  void _open(BuildContext context, DetailKind kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 14),
    const PageSectionTitle('Monitoring Operasional', icon: Icons.analytics_outlined), const SizedBox(height: 12),
    QuickItem(title: 'Rekap Order', subtitle: 'Delivered, Delivering, OnHold, % Delivered & per jam', icon: Icons.local_shipping_outlined, onTap: () => _open(context, DetailKind.rekap)),
    const SizedBox(height: 9),
    QuickItem(title: 'Aging Paket', subtitle: '2–3 hari, >3 hari, resi, alasan & Size Type', icon: Icons.inventory_2_outlined, onTap: () => _open(context, DetailKind.aging)),
    const SizedBox(height: 9),
    QuickItem(title: 'Set Delivered', subtitle: 'Pilih periode → tanggal → data setiap rider', icon: Icons.calendar_month, onTap: () => _open(context, DetailKind.delivered)),
    const SizedBox(height: 9),
    QuickItem(title: 'Productivity OPR', subtitle: 'Target, outbound, gap, produktivitas & tren', icon: Icons.show_chart, onTap: () => _open(context, DetailKind.productivity)),
    const SizedBox(height: 9),
    QuickItem(title: 'New LH Trip', subtitle: 'Slot, trip ID, jadwal, actual arrival & kendaraan', icon: Icons.route_outlined, onTap: () => _open(context, DetailKind.trip)),
  ]);
}
