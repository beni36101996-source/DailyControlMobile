import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
