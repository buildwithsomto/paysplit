import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class SalaryPartitionCard extends StatelessWidget {
  const SalaryPartitionCard({
    required this.state,
    required this.onRules,
    super.key,
  });
  final DashboardState state;
  final VoidCallback onRules;
  String _amount(int? value) =>
      dashboardAmount(value ?? 0, visible: state.balancesVisible);

  @override
  Widget build(BuildContext context) {
    final partition = state.summary?.partition;
    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Salary Partition',
                  style: TextStyle(fontSize: 16, color: Color(0xFF171918)),
                ),
              ),
              TextButton(
                onPressed: onRules,
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Text(
                      'See Rules',
                      style: TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.action,
                      ),
                    ),
                    AppSvgIcon('assets/icons/dashboard/9c184.svg', size: 18),
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE4E4E4)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 220,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The ring is drawn to the size and stroke of the
                          // Figma arcs, with each arc as long as its share.
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PartitionRing(
                                wallets: partition?.toWallets ?? 0,
                                beneficiaries: partition?.toBeneficiaries ?? 0,
                                remaining: partition?.remaining ?? 0,
                                // Hidden balances hide the proportions too.
                                visible: state.balancesVisible,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            top: 20,
                            width: 172,
                            height: 172,
                            child: Image.asset(
                              'assets/icons/dashboard/e4919.png',
                              excludeFromSemantics: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 27),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.textScalerOf(
                                            context,
                                          ).scale(10) >
                                          13
                                      ? 140
                                      : 90,
                                  child: const Text(
                                    'Spend Account\nRemainder',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      height: 1.2,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _amount(partition?.remaining),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF171918),
                                    ),
                                  ),
                                ),
                                if (partition?.baselineSalary != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    state.balancesVisible
                                        ? '${(partition?.remainingPercent ?? 0).round()}% Left for Living'
                                        : 'Balance hidden',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF555653),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 20,
                  children: [
                    Expanded(
                      child: _Breakdown(
                        label: 'Wallets',
                        amount: _amount(partition?.toWallets),
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _Breakdown(
                        label: 'Beneficiaries',
                        amount: _amount(partition?.toBeneficiaries),
                        color: const Color(0xFF171918),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final String amount;
  final Color color;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      spacing: 8,
      children: [
        Container(
          width: 4,
          constraints: const BoxConstraints(minHeight: 38),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF171918),
                  ),
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF555653)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The salary ring: wallets, then beneficiaries, then what is left to spend,
/// clockwise from the lower left. Each arc's length is its share of the
/// salary, so the ring agrees with the figures under it.
class _PartitionRing extends CustomPainter {
  const _PartitionRing({
    required this.wallets,
    required this.beneficiaries,
    required this.remaining,
    required this.visible,
  });
  final int wallets, beneficiaries, remaining;
  final bool visible;

  // Geometry of the Figma ring inside its 200 x 200 box.
  static const _center = Offset(100, 106);
  static const _radius = 90.2;
  static const _stroke = 10.9;
  static const _start = 130 * math.pi / 180;
  static const _sweep = 280 * math.pi / 180;

  /// The space between two arcs, measured along the middle of the stroke.
  static const _gap = 12 * math.pi / 180;

  /// A share too small to draw still shows as a dot.
  static const _least = 2 * math.pi / 180;

  static const _track = Color(0xFFE9EDF2);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);
    final rect = Rect.fromCircle(center: _center, radius: _radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final parts = [
      if (visible && wallets > 0) (wallets, AppColors.primary),
      if (visible && beneficiaries > 0)
        (beneficiaries, const Color(0xFF171918)),
      if (visible && remaining > 0) (remaining, _track),
    ];
    if (parts.isEmpty) {
      canvas.drawArc(rect, _start, _sweep, false, paint..color = _track);
      return;
    }
    final room = _sweep - _gap * (parts.length - 1);
    final total = parts.fold<int>(0, (sum, part) => sum + part.$1);
    // Small shares are raised to the least arc; the rest give up the room.
    final small = parts.where((part) => part.$1 / total * room < _least);
    final large = total - small.fold<int>(0, (sum, part) => sum + part.$1);
    final shared = room - _least * small.length;
    var angle = _start;
    for (final (value, color) in parts) {
      final share = value / total * room;
      final sweep = share < _least ? _least : value / large * shared;
      canvas.drawArc(rect, angle, sweep, false, paint..color = color);
      angle += sweep + _gap;
    }
  }

  @override
  bool shouldRepaint(_PartitionRing old) =>
      wallets != old.wallets ||
      beneficiaries != old.beneficiaries ||
      remaining != old.remaining ||
      visible != old.visible;
}
