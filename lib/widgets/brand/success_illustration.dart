import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';

/// Original exported ray assets, placed and rotated as in node 6143:2302.
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
            for (var index = 0; index < _angles.length; index++)
              Center(
                child: Transform.rotate(
                  angle: _angles[index] * math.pi / 180,
                  child: SizedBox.square(
                    dimension: 643.511,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 643.511 * .5923,
                          top: 643.511 * .3552,
                          child: SvgPicture.asset(
                            'assets/brand/imgEllipse${3250 + index}.svg',
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
