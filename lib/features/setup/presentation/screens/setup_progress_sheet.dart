import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/features/setup/presentation/controllers/setup_progress_provider.dart';
import 'package:paysplit/theme/app_colors.dart';
import 'package:paysplit/widgets/app_svg_icon.dart';
import 'package:paysplit/widgets/brand/success_illustration.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/cards/step_status_card.dart';

class SetupProgressSheet extends ConsumerWidget {
  const SetupProgressSheet({super.key});

  void _open(BuildContext context, String path) {
    // Replace this modal so Back returns to the dashboard, not a stale overlay.
    context.replace(path);
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
                    child: const SuccessRays(),
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
                                'Verify your account to upgrade to a Tier 2. Unlock splitting and get a dedicated account number.',
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
                        const StepStatusCard(
                          step: 1,
                          title: 'Sign up Account',
                          description: 'Create your PaySplit account',
                          state: StepProgress.done,
                        ),
                        const StepConnector(),
                        StepStatusCard(
                          step: 2,
                          title: 'Profile & Identity Verification',
                          description: switch (progress.identityStatus) {
                            KycStatus.unverified =>
                              'Verify using a government-issued ID',
                            KycStatus.inProgress =>
                              'In progress. Continue where you left off',
                            KycStatus.inReview => 'Pending review',
                            KycStatus.approved => 'Identity approved',
                            KycStatus.actionRequired =>
                              'One step needs another try',
                            KycStatus.rejected => 'Verification unsuccessful',
                            KycStatus.reverificationRequired =>
                              'Re-verification required',
                          },
                          state: switch (progress.identityStatus) {
                            KycStatus.approved => StepProgress.done,
                            KycStatus.actionRequired ||
                            KycStatus.rejected ||
                            KycStatus.reverificationRequired =>
                              StepProgress.attention,
                            _ => StepProgress.pending,
                          },
                          onTap: () => _open(context, identityPath),
                        ),
                        const StepConnector(),
                        StepStatusCard(
                          step: 3,
                          title: 'Setup Checklist',
                          description:
                              'Add salary source and set your first rule.',
                          state: progress.configurationComplete
                              ? StepProgress.done
                              : StepProgress.pending,
                          muted: true,
                          onTap: () =>
                              _open(context, progress.configurationPath),
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
                        ? progress.configurationPath
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
                // The arc is drawn from the reported percent, over the
                // ring artwork.
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
