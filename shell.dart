import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'dashboard.dart';
import 'upload.dart';
import 'monitoring.dart';
import 'rider.dart';
import 'tools.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onNavigate: (i) => setState(() => index = i)),
      const UploadScreen(),
      const MonitoringScreen(),
      const RiderScreen(),
      const ToolsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Daily Control Hub', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          Text('Kemuning Riau Hub', style: TextStyle(color: Color(0xFFC1D7F2), fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notifikasi aktif setelah backend terhubung.')))), const SizedBox(width: 6)],
      ),
      body: IndexedStack(index: index, children: screens),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: AppColors.blue.withValues(alpha: .12),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.upload_file_outlined), selectedIcon: Icon(Icons.upload_file), label: 'Upload'),
          NavigationDestination(icon: Icon(Icons.insert_chart_outlined), selectedIcon: Icon(Icons.insert_chart), label: 'Laporan'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Rider'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
        ],
      ),
    );
  }
}
