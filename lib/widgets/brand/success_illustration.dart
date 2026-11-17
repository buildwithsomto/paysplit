import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';

/// The burst of seven rays behind a success badge: one ray image, rotated
/// around the centre.
class SuccessRays extends StatelessWidget {
  const SuccessRays({super.key});

  static const _angles = [0.0, 52.61, 105.22, 157.84, -149.55, -96.94, -44.33];

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: 910,
        child: Stack(
          children: [
            for (final angle in _angles)
              Center(
                child: Transform.rotate(
                  angle: angle * math.pi / 180,
                  child: SizedBox.square(
                    dimension: 643.511,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 643.511 * .5923,
                          top: 643.511 * .3552,
                          child: SvgPicture.asset(
                            'assets/brand/success_ray.svg',
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

class SuccessBadge extends StatelessWidget {
  const SuccessBadge({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Success',
    child: Container(
      width: 118.226,
      height: 118.226,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, AppColors.primary],
        ),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/brand/imgStroke3.svg',
        excludeFromSemantics: true,
      ),
    ),
  );
}
