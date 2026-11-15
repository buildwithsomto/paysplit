import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

class KycProgress extends StatefulWidget {
  const KycProgress({required this.step, super.key});
  final int step;
  @override
  State<KycProgress> createState() => _KycProgressState();
}

class _KycProgressState extends State<KycProgress> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.primaryLight),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Semantics(
            button: true,
            expanded: _expanded,
            label: 'Verification step ${widget.step} of 3. Show steps',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        spacing: 4,
                        children: [
                          const AppSvgIcon(
                            'assets/icons/kyc/f6005.svg',
                            size: 32,
                          ),
                          Container(
                            width: 30,
                            height: 2,
                            color: AppColors.primary,
                          ),
                          AppSvgIcon(
                            widget.step > 1
                                ? 'assets/icons/kyc/33af6.svg'
                                : 'assets/icons/kyc/923b9.svg',
                            size: 32,
                          ),
                          Container(
                            width: 30,
                            height: 2,
                            color: widget.step > 1
                                ? AppColors.primary
                                : const Color(0xFFC7C7CC),
                          ),
                          const AppSvgIcon(
                            'assets/icons/kyc/9d0e7.svg',
                            size: 32,
                          ),
                        ],
                      ),
                      RotatedBox(
                        quarterTurns: _expanded ? 1 : 3,
                        child: SvgPicture.asset(
                          'assets/icons/kyc/1ea1b.svg',
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '1. Profile basics\n2. Identity document\n3. Liveness check',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      SvgPicture.asset(
        widget.step == 1
            ? 'assets/icons/kyc/97f0b.svg'
            : 'assets/icons/kyc/7b76a.svg',
        excludeFromSemantics: true,
      ),
    ],
  );
}
