import 'package:flutter/material.dart';
import '../widgets/ui.dart';
import 'details.dart';

class RiderScreen extends StatelessWidget {
  const RiderScreen({super.key});
  void _open(BuildContext context, DetailKind kind) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(kind: kind)));
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(14), children: [
    const DemoNotice(), const SizedBox(height: 14),
    const PageSectionTitle('Rider Control', icon: Icons.groups_outlined), const SizedBox(height: 12),
    QuickItem(title: 'Pre-Trip Rider & Driver', subtitle: 'Siapa Fit dan siapa belum mengisi', icon: Icons.verified_user_outlined, onTap: () => _open(context, DetailKind.pretrip)),
    const SizedBox(height: 9),
    QuickItem(title: 'Daily Active', subtitle: 'M · L · LM · SM, total dan average per minggu', icon: Icons.event_available, onTap: () => _open(context, DetailKind.dailyActive)),
    const SizedBox(height: 9),
    QuickItem(title: 'Monitoring Target Rider', subtitle: 'Plus, Dedicated, Driver, gap & kebutuhan harian', icon: Icons.track_changes, onTap: () => _open(context, DetailKind.target)),
    const SizedBox(height: 9),
    QuickItem(title: 'Jadwal Libur Rider', subtitle: 'Senin–Minggu dan catatan cuti', icon: Icons.event_busy_outlined, onTap: () => _open(context, DetailKind.holiday)),
  ]);
}
