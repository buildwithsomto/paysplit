import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/core/formatting/money.dart';
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
  String amount(int value) =>
      state.balancesVisible ? Money.format(value) : '••••••';

  @override
  Widget build(BuildContext context) => DashboardCard(
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
                        // Exact native bounds of the two exported Figma arcs.
                        Positioned(
                          left: 6,
                          top: 10.376,
                          width: 90.9168,
                          height: 167.508,
                          child: SvgPicture.asset(
                            'assets/icons/dashboard/b9629.svg',
                            excludeFromSemantics: true,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 10.5264,
                          width: 89.3752,
                          height: 167.3576,
                          child: SvgPicture.asset(
                            'assets/icons/dashboard/4dc5d.svg',
                            excludeFromSemantics: true,
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
                                    MediaQuery.textScalerOf(context).scale(10) >
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
                                  amount(state.remainder),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF171918),
                                  ),
                                ),
                              ),
                              if (state.populated) ...[
                                const SizedBox(height: 8),
                                Text(
                                  state.balancesVisible
                                      ? '${state.remainderPercent}% Left for Living'
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
                      amount: amount(state.walletAllocation),
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _Breakdown(
                      label: 'Beneficiaries',
                      amount: amount(state.beneficiaryAllocation),
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
