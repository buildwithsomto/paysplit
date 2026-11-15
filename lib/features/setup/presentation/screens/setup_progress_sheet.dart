import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_progress_provider.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';

class SetupProgressSheet extends ConsumerWidget {
  const SetupProgressSheet({super.key});

  void _open(BuildContext context, String path) {
    // Replace this modal so Back returns to the dashboard, not a stale overlay.
    context.replace(path);
  }

  String _configurationPath(SetupProgress progress) {
    if (!progress.salaryComplete) return '/setup';
    if (!progress.walletComplete) return '/setup/wallet';
    if (!progress.beneficiaryComplete) return '/setup/beneficiary';
    if (!progress.ruleComplete) return '/setup/rule';
    return '/setup';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(setupProgressProvider);
    final hasStatus = progress.identityStatus != KycStatus.unverified;
    final identityPath = hasStatus ? '/kyc/result' : '/kyc';
    final label = progress.complete
        ? 'Go To Dashboard'
        : progress.identityComplete
        ? 'Continue to Setup Checklist'
        : hasStatus
        ? 'View Verification Status'
        : 'Continue to KYC';
    return SizedBox(
      height: 798,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    top: -346,
                    left: (MediaQuery.sizeOf(context).width - 910) / 2,
                    child: const _SetupBurst(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 47, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _ProgressRing(progress: progress)),
                        const SizedBox(height: 16),
                        Column(
                          children: [
                            const Text(
                              'Complete Account Setup',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF101828),
                                fontSize: 20,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 329),
                              child: const Text(
                                'Complete your identity and salary setup.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF475467),
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _SetupStep(
                          step: 1,
                          title: 'Sign up Account',
                          description: 'Create your PaySplit account',
                          done: true,
                        ),
                        const _StepConnector(),
                        _SetupStep(
                          step: 2,
                          title: 'Profile & Identity Verification',
                          description: hasStatus
                              ? 'Pending review'
                              : progress.identityComplete
                              ? 'Sample identity approved'
                              : 'Verify using a government-issued ID',
                          done: progress.identityComplete,
                          onTap: () => _open(
                            context,
                            progress.identityComplete
                                ? '/kyc/result'
                                : identityPath,
                          ),
                        ),
                        const _StepConnector(),
                        _SetupStep(
                          step: 3,
                          title: 'Setup Checklist',
                          description:
                              'Add salary source and set your first rule.',
                          done: progress.configurationComplete,
                          // Draft configuration is permitted before approval.
                          onTap: () =>
                              _open(context, _configurationPath(progress)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 19,
                    right: 14,
                    child: IconButton(
                      tooltip: 'Close setup progress',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x80FFFFFF),
                      ),
                      icon: const AppSvgIcon(
                        'assets/icons/setup-progress/8ac92.svg',
                      ),
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            child: AppButton(
              label: label,
              onPressed: () {
                if (progress.complete) {
                  context.go('/home');
                } else {
                  _open(
                    context,
                    progress.identityComplete
                        ? _configurationPath(progress)
                        : identityPath,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});
  final SetupProgress progress;
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(17.481) / 17.481;
    return Semantics(
      label: 'Account setup progress',
      value:
          '${progress.completedSteps} of 3 steps, ${progress.percent} percent',
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 118 * scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/icons/setup-progress/7b57e.svg',
                ),
              ),
              Positioned.fill(
                // The source's static quarter circle does not match its labels.
                // This data-driven arc shows the actual completed fraction.
                child: CircularProgressIndicator(
                  value: progress.fraction,
                  strokeWidth: 22 * scale,
                  strokeAlign: -1,
                  strokeCap: StrokeCap.butt,
                  trackGap: 0,
                  backgroundColor: Colors.transparent,
                  color: AppColors.primary,
                ),
              ),
              Text(
                '${progress.percent}%',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17.481,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
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
    required this.done,
    this.onTap,
  });
  final int step;
  final String title;
  final String description;
  final bool done;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    child: Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: step == 3 ? const Color(0xFFE4E4E4) : AppColors.primaryBorder,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(step == 3 ? 16 : 12),
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
                      color: done ? AppColors.primary : const Color(0xFFC9C9C9),
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
                  if (done) const _DoneBadge(),
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

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 65),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFF34C759),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3334C759),
          offset: Offset(0, 2),
          blurRadius: 5,
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        AppSvgIcon('assets/icons/setup-progress/5c658.svg', size: 14),
        Text(
          'Done',
          style: TextStyle(
            fontFamily: 'Lato',
            fontSize: 10,
            height: 1,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();
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

class _SetupBurst extends StatelessWidget {
  const _SetupBurst();
  static const _angles = [0.0, 52.61, 105.22, 157.84, -149.55, -96.94, -44.33];
  static const _assets = [
    'f59ad.svg',
    '977de.svg',
    '10066.svg',
    'f761c.svg',
    'f497a.svg',
    '3145d.svg',
    '52490.svg',
  ];
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: 910,
        child: Stack(
          children: [
            for (var i = 0; i < _assets.length; i++)
              Center(
                child: Transform.rotate(
                  angle: _angles[i] * math.pi / 180,
                  child: SizedBox.square(
                    dimension: 643.511,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 643.511 * .5923,
                          top: 643.511 * .3552,
                          child: SvgPicture.asset(
                            'assets/icons/setup-progress/${_assets[i]}',
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
