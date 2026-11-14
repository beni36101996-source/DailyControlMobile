import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF2D9), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF6DAA4)),
    ),
    child: const Row(children: [
      Icon(Icons.info_outline, color: Color(0xFF91600D), size: 19),
      SizedBox(width: 8),
      Expanded(child: Text('MODE DEMO — angka contoh, belum terhubung ke data live.',
        style: TextStyle(fontSize: 12, color: Color(0xFF754A09), fontWeight: FontWeight.w600))),
    ]),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE0E7F0)),
      boxShadow: const [BoxShadow(color: Color(0x0A102B52), blurRadius: 12, offset: Offset(0, 3))],
    ),
    child: child,
  );
}

class PageSectionTitle extends StatelessWidget {
  const PageSectionTitle(this.title, {super.key, this.action, this.icon});
  final String title;
  final Widget? action;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(children: [
    if (icon != null) ...[Icon(icon, color: AppColors.blue, size: 21), const SizedBox(width: 8)],
    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink))),
    if (action != null) action!,
  ]);
}

class StatCard extends StatelessWidget {
  const StatCard(this.label, this.value, {super.key, this.icon = Icons.analytics_outlined, this.tint = AppColors.blue});
  final String label, value;
  final IconData icon;
  final Color tint;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 102),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: tint.withValues(alpha: .09), borderRadius: BorderRadius.circular(16), border: Border.all(color: tint.withValues(alpha: .20))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 21, color: tint), const SizedBox(width: 7),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), maxLines: 2))]),
      const SizedBox(height: 12),
      Text(value, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: tint)),
    ]),
  );
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.blue});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class QuickItem extends StatelessWidget {
  const QuickItem({super.key, required this.title, required this.icon, required this.onTap, this.subtitle});
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Panel(padding: EdgeInsets.zero, child: ListTile(
    leading: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .10), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.blue)),
    title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(fontSize: 11)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
    onTap: onTap,
  ));
}

void showFeedback(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}
