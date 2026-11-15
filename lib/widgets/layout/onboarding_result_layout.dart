import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:paysplit/widgets/brand/success_illustration.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/theme/app_theme.dart';
import 'package:paysplit/theme/app_typography.dart';

class OnboardingResultLayout extends StatelessWidget {
  const OnboardingResultLayout({
    required this.title,
    required this.description,
    required this.bottom,
    this.secondStepActive = false,
    super.key,
  });
  final String title;
  final String description;
  final Widget bottom;
  final bool secondStepActive;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.systemOverlay,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: MediaQuery.paddingOf(context).top + 127 - 455,
              left: (MediaQuery.sizeOf(context).width - 910) / 2,
              child: const SuccessRays(),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 65, 16, 32),
                    child: Column(
                      children: [
                        const SuccessBadge(),
                        const SizedBox(height: 36),
                        Text(
                          title,
                          style: AppTypography.heading.copyWith(
                            color: AppColors.heading,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(description, textAlign: TextAlign.center),
                        ),
                        SizedBox(height: secondStepActive ? 49 : 29),
                        const _SetupStep(
                          step: 1,
                          title: 'Profile & Identity Verification',
                          description: 'Biometric liveness',
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: SvgPicture.asset(
                              secondStepActive
                                  ? 'assets/brand/step_connector_active.svg'
                                  : 'assets/brand/imgLine3.svg',
                              excludeFromSemantics: true,
                            ),
                          ),
                        ),
                        _SetupStep(
                          step: 2,
                          active: secondStepActive,
                          title: 'Setup Checklist',
                          description: 'Income, vaults & rules',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 18, 16, 36),
          child: bottom,
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.step,
    required this.title,
    required this.description,
    this.active = true,
  });
  final int step;
  final bool active;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(step == 1 ? 12 : 16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? const Color(0xFFC2E5FC) : const Color(0xFFE4E4E4),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.action : const Color(0xFFF0F1F5),
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
                    active
                        ? 'assets/brand/imgStar1.svg'
                        : 'assets/brand/imgStar2.svg',
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Text(
                'Step $step',
                style: TextStyle(
                  fontSize: 12,
                  height: 14 / 12,
                  letterSpacing: .3,
                  color: active ? AppColors.white : AppColors.placeholder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            height: 1.25,
            fontWeight: FontWeight.w600,
            letterSpacing: .3,
            color: Color(0xFF121212),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: AppTypography.body.copyWith(
            height: 24 / 14,
            color: const Color(0xFF4F4E55),
          ),
        ),
      ],
    ),
  );
}
