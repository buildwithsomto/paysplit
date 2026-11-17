import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paysplit/core/presentation/content_phase.dart';
import 'package:paysplit/features/kyc/data/models/kyc_models.dart';
import 'package:paysplit/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:paysplit/features/kyc/presentation/widgets/kyc_section.dart';
import 'package:paysplit/widgets/buttons/app_button.dart';
import 'package:paysplit/widgets/buttons/app_text_link.dart';
import 'package:paysplit/widgets/cards/step_status_card.dart';
import 'package:paysplit/widgets/layout/app_page_layout.dart';
import 'package:paysplit/widgets/layout/onboarding_result_layout.dart';

/// Where verification stands: the approval screen from the design, or the
/// stepper with what is done and what still needs the user.
class KycResultScreen extends ConsumerWidget {
  const KycResultScreen({super.key});

  /// Provider reason codes, in words the user can act on.
  static String failureCopy(String? code) => switch (code) {
    'LIVENESS_FAILED' =>
      'We couldn’t confirm a live photo. Use good lighting and look straight at the camera.',
    'NO_FACE_DETECTED' || 'NO_FACE' =>
      'We couldn’t see a face in that photo. Keep your whole face in the frame.',
    'FACE_MISMATCH' =>
      'Your photo didn’t match your ID record. Try again in good lighting.',
    'NAME_MISMATCH' =>
      'The name on this ID doesn’t match your PaySplit account.',
    'DOB_MISMATCH' => 'The date of birth on this ID doesn’t match our records.',
    'IDENTITY_NOT_FOUND' =>
      'We couldn’t find that ID number. Check it and try again.',
    'INVALID_DOCUMENT' =>
      'We couldn’t read that document. Upload a clear, uncropped photo.',
    'ATTEMPTS_EXCEEDED' =>
      'You’ve used today’s attempts. Please try again tomorrow.',
    _ => 'This step needs another try.',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(kycControllerProvider);
    final status = state.status;
    final verification = state.verification;
    final document = switch (verification?.identityMethod) {
      IdentityDocument.bvn => 'BVN',
      IdentityDocument.nin => 'NIN',
      _ => 'identity document',
    };
    if (status == KycStatus.approved) {
      return OnboardingResultLayout(
        title: 'Identity Approved',
        secondStepActive: true,
        description:
            'Your $document and liveness check have been authenticated by the provider.',
        bottom: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextLink(label: 'Skip', onPressed: () => context.go('/home')),
            AppButton(
              label: 'Continue to Setup Checklist',
              onPressed: () {
                final router = GoRouter.of(context);
                router.go('/home');
                router.push('/setup/progress');
              },
            ),
          ],
        ),
      );
    }

    final identity = verification?.identity ?? const KycStep();
    final liveness = verification?.liveness ?? const KycStep();
    final profileDone = verification?.profileCompleted ?? false;
    final (title, message) = switch (status) {
      KycStatus.inReview => (
        'Verification in review',
        'We’re reviewing your details. You can keep exploring PaySplit while you wait.',
      ),
      KycStatus.inProgress => (
        'Verification in progress',
        'Pick up where you left off. Your salary account and split rules unlock once your identity is approved.',
      ),
      KycStatus.actionRequired => (
        'One more step needed',
        'Part of your verification needs another try before your identity can be approved.',
      ),
      KycStatus.rejected => (
        'Verification unsuccessful',
        'We couldn’t verify your identity with the details provided. Review the steps and try again.',
      ),
      KycStatus.reverificationRequired => (
        'Re-verification required',
        'Your identity needs to be checked again before financial actions can continue.',
      ),
      _ => (
        'Complete your verification',
        'Verify your identity to unlock your salary account, split rules and transfers.',
      ),
    };
    final resumable = status != KycStatus.inReview;
    final attempts = liveness.failed ? liveness.attemptsRemaining : null;
    final loadFailed = verification == null && state.phase.isFailure;
    return AppPageLayout(
      title: 'Profile Verification',
      onBack: () => context.canPop() ? context.pop() : context.go('/home'),
      bottom: AppButton(
        label: loadFailed
            ? 'Try again'
            : switch (status) {
                KycStatus.inReview => 'Go to Dashboard',
                KycStatus.unverified => 'Start Verification',
                _ => 'Continue Verification',
              },
        busy: verification == null && state.phase.isBusy,
        onPressed: () => loadFailed
            ? ref.read(kycControllerProvider.notifier).load()
            : context.go(
                resumable ? ref.read(kycResumeRouteProvider) : '/home',
              ),
      ),
      child: KycSection(
        step: !profileDone
            ? 1
            : identity.passed
            ? 3
            : 2,
        title: loadFailed ? 'Verification status unavailable' : title,
        description: loadFailed
            ? state.phase == ContentPhase.offline
                  ? 'You’re offline. Reconnect to see where your verification stands.'
                  : 'We couldn’t load your verification status. Try again.'
            : message,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepStatusCard(
              step: 1,
              title: 'Profile Basics',
              description: profileDone
                  ? [
                      state.country?.name,
                      verification?.phoneNumber,
                    ].nonNulls.join(' · ')
                  : 'Residence country and mobile number',
              state: profileDone ? StepProgress.done : StepProgress.pending,
            ),
            const StepConnector(),
            StepStatusCard(
              step: 2,
              title: 'Identity Verification',
              description: identity.passed
                  ? [
                      verification?.identityMethod?.label ?? 'ID',
                      ?verification?.maskedIdNumber,
                      'verified',
                    ].join(' ')
                  : identity.failed
                  ? failureCopy(identity.failureReason)
                  : 'BVN, NIN or a government-issued ID',
              state: identity.passed
                  ? StepProgress.done
                  : identity.failed
                  ? StepProgress.attention
                  : StepProgress.pending,
            ),
            const StepConnector(),
            StepStatusCard(
              step: 3,
              title: 'Face Verification',
              description: liveness.passed
                  ? 'Selfie matched to your ID'
                  : liveness.failed
                  ? [
                      failureCopy(liveness.failureReason),
                      if (attempts != null && attempts > 0)
                        '$attempts ${attempts == 1 ? 'attempt' : 'attempts'} left.',
                    ].join(' ')
                  : 'A quick selfie to confirm it’s you',
              state: liveness.passed
                  ? StepProgress.done
                  : liveness.failed
                  ? StepProgress.attention
                  : StepProgress.pending,
              muted: !identity.passed,
            ),
          ],
        ),
      ),
    );
  }
}
