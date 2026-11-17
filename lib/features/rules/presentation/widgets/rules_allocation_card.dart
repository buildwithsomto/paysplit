import 'package:paysplit/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/rules/presentation/controllers/rules_controller.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

/// How the expected salary is shared out, drawn from the server's summary.
class RulesAllocationCard extends StatelessWidget {
  const RulesAllocationCard({required this.summary, super.key});
  final RulesSummary summary;
  static const _colors = [
    Color(0xFF33A7F5),
    Color(0xFF00D6D1),
    Color(0xFF171918),
    Color(0xFF0F4B70),
    Color(0xFF1D4CB4),
  ];
  @override
  Widget build(BuildContext context) {
    final salaryMinor = summary.baselineSalary ?? 0;
    final segments = summary.segments;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEAF6FF), Colors.white],
        ),
        border: Border.all(color: const Color(0x80D6EDFD)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 12,
            children: [
              const Expanded(
                child: Text(
                  'Allocation Progress',
                  style: TextStyle(fontSize: 14, color: Color(0xFF696969)),
                ),
              ),
              Text(
                salaryMinor > 0
                    ? '${summary.allocatedPercent.round()}% of Salary'
                    : 'No baseline',
                style: const TextStyle(fontSize: 14, color: Color(0xFF121212)),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 26,
              child: Row(
                children: [
                  if (salaryMinor > 0)
                    for (final (i, segment) in segments.indexed)
                      if (segment.amountMinor > 0)
                        Expanded(
                          flex: segment.amountMinor,
                          child: ColoredBox(
                            color: _colors[i % _colors.length],
                            child: _AllocationStripe(index: i),
                          ),
                        ),
                  if (salaryMinor == 0 || summary.remainder > 0)
                    Expanded(
                      flex: salaryMinor == 0 ? 1 : summary.remainder,
                      child: const ColoredBox(
                        color: Color(0xABECECEC),
                        child: SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final (i, segment) in segments.indexed)
                _Legend(color: _colors[i % _colors.length], name: segment.name),
              const _Legend(color: Color(0xFFD9D9D9), name: 'Spend Balance'),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              spacing: 4,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Expanded(
                      child: _Amount(
                        label: 'Monthly Salary Baseline',
                        amount: salaryMinor,
                      ),
                    ),
                    Expanded(
                      child: _Amount(
                        label: 'Spend Account Remainder',
                        amount: summary.remainder,
                        green: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Expanded(
                      child: _Amount(
                        label: 'Total Allocated',
                        amount: summary.totalAllocated,
                      ),
                    ),
                    Expanded(
                      child: _Amount(
                        label: 'Total Unallocated',
                        amount: summary.remainder,
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

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.name});
  final Color color;
  final String name;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Flexible(
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Color(0xFF171918)),
        ),
      ),
    ],
  );
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.amount,
    this.green = false,
  });
  final String label;
  final int amount;
  final bool green;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            height: 1.4,
            color: Color(0xFF444444),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          Money.format(amount),
          style: TextStyle(
            fontSize: 20,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: green ? AppColors.positive : const Color(0xFF171918),
          ),
        ),
      ],
    ),
  );
}

class _AllocationStripe extends StatelessWidget {
  const _AllocationStripe({required this.index});
  final int index;
  static const _assets = [
    'assets/icons/rules/a9243.svg',
    'assets/icons/rules/f31ea.svg',
    'assets/icons/rules/588da.svg',
    'assets/icons/rules/9bf3c.svg',
    'assets/icons/rules/5e26e.svg',
    'assets/icons/rules/826c7.svg',
  ];
  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      children: [
        Positioned(
          left: -94.59,
          top: -95.56,
          width: 289.427,
          height: 289.427,
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: AppSvgIcon(
                _assets[index % _assets.length],
                width: 228.2,
                height: 181.111,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
