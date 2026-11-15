import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

class SuccessSheetLayout extends StatelessWidget {
  const SuccessSheetLayout({
    required this.title,
    required this.message,
    required this.onClose,
    required this.onHome,
    super.key,
  });
  final String title;
  final String message;
  final VoidCallback onClose;
  final VoidCallback onHome;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Stack(
      children: [
        Positioned(
          top: -258,
          left: (MediaQuery.sizeOf(context).width - 702) / 2,
          child: const _SuccessBurst(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 47.4, 16, 39),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 91.2,
                  height: 91.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.857),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, AppColors.primary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/destinations/225c0.svg',
                    width: 51,
                    height: 39,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              const SizedBox(height: 61.4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF323232),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7C7C7C),
                ),
              ),
              const SizedBox(height: 58.4),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Close',
                      outlined: true,
                      onPressed: onClose,
                    ),
                  ),
                  Expanded(
                    child: AppButton(label: 'Go Home', onPressed: onHome),
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

class _SuccessBurst extends StatelessWidget {
  const _SuccessBurst();
  static const _angles = [0.0, 52.61, 105.22, 157.84, -149.55, -96.94, -44.33];
  static const _assets = [
    'afc27.svg',
    '38444.svg',
    'ba82c.svg',
    'e63a1.svg',
    'be98d.svg',
    '6b556.svg',
    '1ab40.svg',
  ];
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: 702,
        child: Stack(
          children: [
            for (var i = 0; i < _assets.length; i++)
              Center(
                child: Transform.rotate(
                  angle: _angles[i] * math.pi / 180,
                  child: SizedBox.square(
                    dimension: 496.427,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 496.427 * .5923,
                          top: 496.427 * .3552,
                          child: SvgPicture.asset(
                            'assets/icons/destinations/${_assets[i]}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
