import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/shell.dart';
import 'core/control_store.dart';
import 'core/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DailyControlApi.initialize();
  await DailyControlStore.instance.initialize();
  runApp(const DailyControlMobile());
}

class DailyControlMobile extends StatelessWidget {
  const DailyControlMobile({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daily Control Hub',
    debugShowCheckedModeBanner: false,
    theme: dailyControlTheme(),
    home: const MainShell(),
  );
}
