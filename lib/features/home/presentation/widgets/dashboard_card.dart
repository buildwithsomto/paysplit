import 'package:flutter/material.dart';
import 'package:paysplit/core/formatting/money.dart';

/// An amount as the dashboard shows it: masked while balances are hidden.
String dashboardAmount(int minor, {required bool visible}) =>
    visible ? Money.format(minor) : '••••••';

/// A figure with at most one decimal and no trailing `.0`: `20`, `95.8`.
String compactNumber(double value) => value == value.roundToDouble()
    ? '${value.round()}'
    : value.toStringAsFixed(1);

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x80E4E4E4)),
    ),
    child: child,
  );
}
