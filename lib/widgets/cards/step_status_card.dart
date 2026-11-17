import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';

enum StepProgress { pending, done, attention }

/// The numbered step card from the account-setup overlay, shared by every
/// screen that reports progress through a sequence.
class StepStatusCard extends StatelessWidget {
  const StepStatusCard({
    required this.step,
    required this.title,
    required this.description,
    this.state = StepProgress.pending,
    this.muted = false,
    this.onTap,
    super.key,
  });
  final int step;
  final String title;
  final String description;
  final StepProgress state;

  /// The last, not-yet-reachable step uses the neutral outline.
  final bool muted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: muted ? const Color(0xFFE4E4E4) : AppColors.primaryBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(muted ? 16 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: state == StepProgress.done
                          ? AppColors.primary
                          : const Color(0xFFC9C9C9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        SizedBox.square(
                          dimension: 14,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SvgPicture.asset(
                              'assets/icons/setup-progress/54e24.svg',
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        Text(
                          'Step $step',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1,
                            letterSpacing: .3,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state == StepProgress.done)
                    const _StepBadge.done()
                  else if (state == StepProgress.attention)
                    const _StepBadge.attention(),
                ],
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.25,
                  letterSpacing: .3,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF121212),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 24 / 14,
                  color: Color(0xFF4F4E55),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StepBadge extends StatelessWidget {
  const _StepBadge.done()
    : label = 'Done',
      color = const Color(0xFF34C759),
      icon = 'assets/icons/setup-progress/5c658.svg';
  const _StepBadge.attention()
    : label = 'Try again',
      color = const Color(0xFFB54708),
      icon = null;
  final String label;
  final Color color;
  final String? icon;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 65),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: .2),
          offset: const Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        if (icon case final icon?) AppSvgIcon(icon, size: 14),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lato',
            fontSize: 10,
            height: 1.4,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

/// The dotted line between two step cards.
class StepConnector extends StatelessWidget {
  const StepConnector({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 20,
    child: Center(
      child: RotatedBox(
        quarterTurns: 1,
        child: SvgPicture.asset(
          'assets/icons/setup-progress/aac2c.svg',
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
