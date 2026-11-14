import 'package:flutter_test/flutter_test.dart';
import 'package:daily_control_mobile/core/control_store.dart';
import 'package:daily_control_mobile/screens/delivered_v2.dart';

void main() {
  test('Productivity computes from daily outbound and operator count', () {
    final e = ProductivityDay(date: '2026-11-14', operators: 3, outbound: 3000);
    expect(e.productivity, 1000);
    expect(e.percent(952)!, greaterThan(100));
  });

  test('Daily rider list contains more than twenty screenshot sample rows', () {
    expect(demoDelivered13Nov.length, greaterThanOrEqualTo(25));
    expect(demoDelivered13Nov.first.name, 'MUHAMMAD WANDA ARYA');
    expect(demoDelivered13Nov.first.achievement.toStringAsFixed(2), '97.33');
  });

  test('Local schedule has distinct categories and includes Sunday', () {
    final assignments = DailyControlStore.instance.holidays;
    expect(assignments.any((x) => x.day == 'Minggu'), isTrue);
    expect(assignments.map((e) => e.type).toSet().length, 3);
  });
}
