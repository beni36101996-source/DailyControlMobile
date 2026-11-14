import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_control_mobile/main.dart';

void main() {
  testWidgets('Dashboard shows operational navigation', (tester) async {
    await tester.pumpWidget(const DailyControlMobile());
    expect(find.text('Daily Control Hub'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);
  });
  testWidgets('Switch to Upload page', (tester) async {
    await tester.pumpWidget(const DailyControlMobile());
    await tester.tap(find.text('Upload').last);
    await tester.pumpAndSettle();
    expect(find.text('Upload & Tools'), findsOneWidget);
    expect(find.text('Data Harian (CSV)'), findsOneWidget);
    expect(find.text('Data Order (CSV)'), findsOneWidget);
  });
}
