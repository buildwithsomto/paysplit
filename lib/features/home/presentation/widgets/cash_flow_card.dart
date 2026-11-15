import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/core/formatting/money.dart';
import 'package:paysplit/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:paysplit/features/home/presentation/widgets/dashboard_card.dart';
import 'package:paysplit/theme/app_colors.dart';

/// Native, selectable data bars; decorative grid assets remain the Figma originals.
class CashFlowCard extends StatefulWidget {
  const CashFlowCard({required this.state, super.key});
  final DashboardState state;
  @override
  State<CashFlowCard> createState() => _CashFlowCardState();
}

class _CashFlowCardState extends State<CashFlowCard> {
  int _selected = 4;
  static const _months = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
  // Integer kobo, matching the selected sample's allocation summary.
  static const _wallets = [43000000, 0, 53500000, 31500000, 47750000, 31500000];
  static const _beneficiaries = [0, 30500000, 24500000, 0, 13500000, 0];
  static const _gridTop = 20.0;
  static const _gridStep = 42.0;
  static const _baseline = _gridTop + 3 * _gridStep;
  static const _minorPerGridStep = 20000000;

  static double _barHeight(int minor) => minor / _minorPerGridStep * _gridStep;

  @override
  Widget build(BuildContext context) => DashboardCard(
    padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Salary Allocation & Split Cash Flow',
          style: TextStyle(fontSize: 14, color: Color(0xFF171918)),
        ),
        if (!widget.state.populated) ...[
          const SizedBox(height: 100),
          Center(
            child: SvgPicture.asset(
              'assets/icons/dashboard/b98c5.svg',
              width: 120,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Your allocations will appear here.')),
          const SizedBox(height: 52),
        ] else if (!widget.state.balancesVisible) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 90),
            child: Center(child: Text('Balances and cash flow are hidden.')),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              Text(
                Money.format(_wallets[_selected] + _beneficiaries[_selected]),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF171918),
                ),
              ),
              Text(
                '${_months[_selected]} allocations',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Legend('Wallets', AppColors.primary),
              _Legend('Recipient/Beneficiaries', Color(0xFF171918)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF9F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E4E4)),
            ),
            child: const Text(
              'Jun – Nov 2026 · Sample data',
              style: TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              SizedBox(
                width: 33,
                height: 298,
                child: Stack(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Positioned(
                        top: _gridTop - 7 + i * _gridStep,
                        left: 0,
                        right: 0,
                        child: Text(
                          [
                            '₦600k',
                            '₦400k',
                            '₦200k',
                            '₦0',
                            '−200k',
                            '−400k',
                            '−600k',
                          ][i],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF555653),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 298,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Stack(
                          children: [
                            for (var i = 0; i < 7; i++)
                              Positioned(
                                top: _gridTop + i * _gridStep,
                                left: 0,
                                right: 0,
                                height: 1,
                                child: i == 3
                                    ? Image.asset(
                                        'assets/icons/dashboard/3c337.png',
                                        fit: BoxFit.fill,
                                        excludeFromSemantics: true,
                                      )
                                    : SvgPicture.asset(
                                        'assets/icons/dashboard/e79b3.svg',
                                        fit: BoxFit.fill,
                                        excludeFromSemantics: true,
                                      ),
                              ),
                            for (var i = 0; i < 6; i++)
                              Positioned(
                                left: i * constraints.maxWidth / 6,
                                top: 0,
                                bottom: 0,
                                width: constraints.maxWidth / 6,
                                child: Semantics(
                                  button: true,
                                  selected: i == _selected,
                                  label:
                                      '${_months[i]} 2026. Wallets ${Money.format(_wallets[i])}. Beneficiaries ${Money.format(_beneficiaries[i])}.',
                                  child: Tooltip(
                                    message:
                                        '${_months[i]}: ${Money.format(_wallets[i] + _beneficiaries[i])} allocated',
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _selected = i),
                                      child: Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          if (i > 0)
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              bottom: 0,
                                              width: 1,
                                              child: RotatedBox(
                                                quarterTurns: 1,
                                                child: Image.asset(
                                                  'assets/icons/dashboard/4a96f.png',
                                                  fit: BoxFit.fill,
                                                  excludeFromSemantics: true,
                                                ),
                                              ),
                                            ),
                                          if (_wallets[i] > 0)
                                            Positioned(
                                              top:
                                                  _baseline -
                                                  _barHeight(_wallets[i]),
                                              width: 26,
                                              height: _barHeight(_wallets[i]),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: i == _selected
                                                      ? AppColors.primary
                                                      : null,
                                                  gradient: i == _selected
                                                      ? null
                                                      : const LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Color(0xFFEAF6FF),
                                                            Color(0x00FFFFFF),
                                                          ],
                                                        ),
                                                  border: const Border(
                                                    top: BorderSide(
                                                      color: AppColors.primary,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          18,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          if (_beneficiaries[i] > 0)
                                            Positioned(
                                              top: _baseline,
                                              width: 26,
                                              height: _barHeight(
                                                _beneficiaries[i],
                                              ),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: i == _selected
                                                      ? const Color(0xFF171918)
                                                      : null,
                                                  gradient: i == _selected
                                                      ? null
                                                      : const LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Color(0x00FFFFFF),
                                                            Color(0xFFF4F4F3),
                                                          ],
                                                        ),
                                                  border: const Border(
                                                    bottom: BorderSide(
                                                      color: Color(0xFF171918),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  borderRadius:
                                                      const BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                          18,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final month in _months)
                          Expanded(
                            child: Text(
                              '$month\n26',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: Color(0xFF555653),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF171918)),
        ),
      ),
    ],
  );
}
